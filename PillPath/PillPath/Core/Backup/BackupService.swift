
import Foundation
import CoreData
import Combine
import FirebaseFirestore

enum BackupError: LocalizedError {
    case notAuthenticated
    case noBackupFound
    case encodingFailed
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .notAuthenticated: return "You must be signed in to use cloud backup."
        case .noBackupFound:    return "No backup found in the cloud for this account."
        case .encodingFailed:   return "Failed to prepare backup data."
        case .decodingFailed:   return "Backup file is corrupted or unreadable."
        }
    }
}

protocol BackupServiceProtocol {
    func backup() async throws -> Date
    func checkForBackup() async throws -> Date?
    func restore() async throws
    func lastBackupDate() -> Date?
    func localMedicationCount() -> Int
}

final class BackupService: BackupServiceProtocol {

    private let coreData: CoreDataStack
    private static let lastBackupKey = "pp_last_backup_date"
    private static let autoBackupThreshold: TimeInterval = 3600

    init(coreData: CoreDataStack = .shared) {
        self.coreData = coreData
    }


    func backup() async throws -> Date {
        let uid = AppSession.shared.currentUserId
        guard !uid.isEmpty else { throw BackupError.notAuthenticated }

        let snapshot = try await MainActor.run { try buildSnapshot(userId: uid) }
        let data = try encode(snapshot)
        guard let json = String(data: data, encoding: .utf8) else { throw BackupError.encodingFailed }
        try await upload(json: json, userId: uid)

        let now = Date.now
        UserDefaults.standard.set(now, forKey: Self.lastBackupKey)
        return now
    }

    func autoBackupIfNeeded() async {
        guard !AppSession.shared.currentUserId.isEmpty else { return }
        if let last = lastBackupDate(),
           Date.now.timeIntervalSince(last) < Self.autoBackupThreshold { return }
        _ = try? await backup()
    }

    func checkForBackup() async throws -> Date? {
        let uid = AppSession.shared.currentUserId
        guard !uid.isEmpty else { return nil }
        do {
            let doc = try await docRef(userId: uid).getDocument()
            guard doc.exists else { return nil }
            return (doc.get("updatedAt") as? Timestamp)?.dateValue()
        } catch {
            return nil
        }
    }

    func restore() async throws {
        let uid = AppSession.shared.currentUserId
        guard !uid.isEmpty else { throw BackupError.notAuthenticated }

        let json = try await download(userId: uid)
        guard let data = json.data(using: .utf8) else { throw BackupError.decodingFailed }
        let snapshot = try decode(data)
        try await MainActor.run { try apply(snapshot, userId: uid) }
    }

    func lastBackupDate() -> Date? {
        UserDefaults.standard.object(forKey: Self.lastBackupKey) as? Date
    }

    func localMedicationCount() -> Int {
        let uid = AppSession.shared.currentUserId
        guard !uid.isEmpty else { return 0 }
        let request = MedicationEntity.fetchRequest()
        request.predicate = NSPredicate(format: "userId == %@", uid)
        return (try? coreData.viewContext.count(for: request)) ?? 0
    }


    private func buildSnapshot(userId: String) throws -> AppBackup {
        let ctx = coreData.viewContext

        let medReq = MedicationEntity.fetchRequest()
        medReq.predicate = NSPredicate(format: "userId == %@", userId)
        let meds = try ctx.fetch(medReq)

        let schedReq = ScheduleEntity.fetchRequest()
        schedReq.predicate = NSPredicate(format: "medication.userId == %@", userId)
        let scheds = try ctx.fetch(schedReq)

        let timeReq = ScheduleTimeEntity.fetchRequest()
        timeReq.predicate = NSPredicate(format: "schedule.medication.userId == %@", userId)
        let times = try ctx.fetch(timeReq)

        let logReq = DoseLogEntity.fetchRequest()
        logReq.predicate = NSPredicate(format: "medication.userId == %@", userId)
        let logs = try ctx.fetch(logReq)

        let evtReq = MedicalEventEntity.fetchRequest()
        evtReq.predicate = NSPredicate(format: "userId == %@", userId)
        let evts = try ctx.fetch(evtReq)

        return AppBackup(
            version: 1,
            exportedAt: .now,
            userId: userId,
            medications:   meds.compactMap  { MedicationBackup(from: $0) },
            schedules:     scheds.compactMap { ScheduleBackup(from: $0) },
            scheduleTimes: times.compactMap  { ScheduleTimeBackup(from: $0) },
            doseLogs:      logs.compactMap   { DoseLogBackup(from: $0) },
            medicalEvents: evts.compactMap   { MedicalEventBackup(from: $0) }
        )
    }


    private func encode(_ backup: AppBackup) throws -> Data {
        let enc = JSONEncoder()
        enc.dateEncodingStrategy = .iso8601
        guard let data = try? enc.encode(backup) else { throw BackupError.encodingFailed }
        return data
    }

    private func decode(_ data: Data) throws -> AppBackup {
        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        guard let backup = try? dec.decode(AppBackup.self, from: data) else {
            throw BackupError.decodingFailed
        }
        return backup
    }


    private func docRef(userId: String) -> DocumentReference {
        Firestore.firestore().collection("backups").document(userId)
    }

    private func upload(json: String, userId: String) async throws {
        try await docRef(userId: userId).setData([
            "data": json,
            "updatedAt": Timestamp(date: .now)
        ])
    }

    private func download(userId: String) async throws -> String {
        do {
            let doc = try await docRef(userId: userId).getDocument()
            guard doc.exists, let json = doc.get("data") as? String else {
                throw BackupError.noBackupFound
            }
            return json
        } catch let e as BackupError {
            throw e
        } catch {
            throw BackupError.noBackupFound
        }
    }


    private func apply(_ backup: AppBackup, userId: String) throws {
        let ctx = coreData.viewContext

        func upsertMed(id: UUID)    -> MedicationEntity   { fetch(MedicationEntity.self, id: id, ctx: ctx)   ?? MedicationEntity(context: ctx) }
        func upsertSched(id: UUID)  -> ScheduleEntity     { fetch(ScheduleEntity.self,   id: id, ctx: ctx)   ?? ScheduleEntity(context: ctx) }
        func upsertLog(id: UUID)    -> DoseLogEntity       { fetch(DoseLogEntity.self,    id: id, ctx: ctx)   ?? DoseLogEntity(context: ctx) }
        func upsertEvent(id: UUID)  -> MedicalEventEntity  { fetch(MedicalEventEntity.self, id: id, ctx: ctx) ?? MedicalEventEntity(context: ctx) }

        var medMap: [UUID: MedicationEntity] = [:]
        for m in backup.medications {
            let e = upsertMed(id: m.id)
            e.id = m.id;  e.userId = userId;  e.name = m.name
            e.genericName = m.genericName;  e.displayName = m.displayName
            e.form = m.form;  e.dosageAmount = m.dosageAmount;  e.dosageUnit = m.dosageUnit
            e.instructions = m.instructions;  e.notes = m.notes;  e.photoURL = m.photoURL
            e.currentQuantity = m.currentQuantity;  e.lowQuantityAlert = m.lowQuantityAlert
            e.lowQuantityThreshold = m.lowQuantityThreshold;  e.isActive = m.isActive
            e.addedAt = m.addedAt;  e.sideEffectsJSON = m.sideEffectsJSON
            e.interactionsJSON = m.interactionsJSON;  e.statusInfoJSON = m.statusInfoJSON
            medMap[m.id] = e
        }

        var schedMap: [UUID: ScheduleEntity] = [:]
        for s in backup.schedules {
            let e = upsertSched(id: s.id)
            e.id = s.id;  e.frequency = s.frequency;  e.intervalHours = s.intervalHours
            e.specificDaysJSON = s.specificDaysJSON;  e.customDatesJSON = s.customDatesJSON
            e.mealTiming = s.mealTiming;  e.startDate = s.startDate;  e.endDate = s.endDate
            e.isOngoing = s.isOngoing;  e.doseReminders = s.doseReminders
            e.notificationOffsetMinutes = s.notificationOffsetMinutes;  e.isActive = s.isActive
            e.medication = medMap[s.medicationId]
            if let old = e.scheduleTimes as? Set<ScheduleTimeEntity> { old.forEach { ctx.delete($0) } }
            schedMap[s.id] = e
        }

        var timesBySchedule: [UUID: [ScheduleTimeEntity]] = [:]
        for t in backup.scheduleTimes {
            let e = ScheduleTimeEntity(context: ctx)
            e.id = t.id;  e.hour = t.hour;  e.minute = t.minute;  e.label = t.label
            timesBySchedule[t.scheduleId, default: []].append(e)
        }
        for (schedId, times) in timesBySchedule {
            guard let sched = schedMap[schedId] else { continue }
            sched.scheduleTimes = NSSet(array: times)
            times.forEach { $0.schedule = sched }
        }

        for l in backup.doseLogs {
            let e = upsertLog(id: l.id)
            e.id = l.id;  e.scheduledAt = l.scheduledAt;  e.takenAt = l.takenAt
            e.status = l.status;  e.notes = l.notes
            e.medication = medMap[l.medicationId]
            if let sid = l.scheduleId { e.schedule = schedMap[sid] }
        }

        for ev in backup.medicalEvents {
            let e = upsertEvent(id: ev.id)
            e.id = ev.id;  e.userId = userId;  e.title = ev.title
            e.eventDescription = ev.eventDescription;  e.date = ev.date
            e.type = ev.type;  e.createdAt = ev.createdAt
        }

        if ctx.hasChanges { try ctx.save() }
        ctx.refreshAllObjects()
    }

    private func fetch<T: NSManagedObject>(_ type: T.Type, id: UUID, ctx: NSManagedObjectContext) -> T? {
        let req = NSFetchRequest<T>(entityName: String(describing: type))
        req.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        req.fetchLimit = 1
        return try? ctx.fetch(req).first
    }
}
