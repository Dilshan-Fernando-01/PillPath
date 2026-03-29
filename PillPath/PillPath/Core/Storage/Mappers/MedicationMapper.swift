//
//  MedicationMapper.swift
//  PillPath
//
//  Converts between MedicationEntity (CoreData) and Medication (domain).
//  All CoreData ↔ domain conversions happen here only.
//

import Foundation
import CoreData

enum MedicationMapper {

    // MARK: - Entity → Domain

    static func toDomain(_ entity: MedicationEntity) -> Medication? {
        guard let id = entity.id,
              let name = entity.name,
              let addedAt = entity.addedAt else { return nil }

        let statusChange: MedicationStatusChange? = {
            guard let json = entity.statusInfoJSON,
                  let data = json.data(using: .utf8) else { return nil }
            return try? JSONDecoder().decode(MedicationStatusChange.self, from: data)
        }()

        return Medication(
            id: id,
            name: name,
            genericName: entity.genericName,
            displayName: entity.displayName,
            form: MedicationForm(rawValue: entity.form ?? "tablet") ?? .tablet,
            dosageAmount: entity.dosageAmount,
            dosageUnit: DosageUnit(rawValue: entity.dosageUnit ?? "pills") ?? .pills,
            instructions: entity.instructions,
            notes: entity.notes,
            photoURL: entity.photoURL,
            currentQuantity: Int(entity.currentQuantity),
            lowQuantityAlert: entity.lowQuantityAlert,
            lowQuantityThreshold: Int(entity.lowQuantityThreshold),
            isActive: entity.isActive,
            addedAt: addedAt,
            sideEffects: JSONHelper.decodeStringArray(entity.sideEffectsJSON),
            interactions: JSONHelper.decodeStringArray(entity.interactionsJSON),
            statusChange: statusChange
        )
    }

    // MARK: - Domain → Entity (upsert)

    static func toEntity(_ medication: Medication, context: NSManagedObjectContext) -> MedicationEntity {
        let entity = fetchOrCreate(id: medication.id, context: context)
        entity.id             = medication.id
        entity.name           = medication.name
        entity.genericName    = medication.genericName
        entity.displayName    = medication.displayName
        entity.form           = medication.form.rawValue
        entity.dosageAmount   = medication.dosageAmount
        entity.dosageUnit     = medication.dosageUnit.rawValue
        entity.instructions   = medication.instructions
        entity.notes          = medication.notes
        entity.photoURL       = medication.photoURL
        entity.currentQuantity       = Int32(medication.currentQuantity)
        entity.lowQuantityAlert      = medication.lowQuantityAlert
        entity.lowQuantityThreshold  = Int32(medication.lowQuantityThreshold)
        entity.isActive       = medication.isActive
        entity.addedAt        = medication.addedAt
        entity.sideEffectsJSON  = JSONHelper.encodeStringArray(medication.sideEffects)
        entity.interactionsJSON = JSONHelper.encodeStringArray(medication.interactions)
        if let sc = medication.statusChange,
           let data = try? JSONEncoder().encode(sc) {
            entity.statusInfoJSON = String(data: data, encoding: .utf8)
        } else {
            entity.statusInfoJSON = nil
        }
        return entity
    }

    private static func fetchOrCreate(id: UUID, context: NSManagedObjectContext) -> MedicationEntity {
        let request = MedicationEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return (try? context.fetch(request).first) ?? MedicationEntity(context: context)
    }
}
