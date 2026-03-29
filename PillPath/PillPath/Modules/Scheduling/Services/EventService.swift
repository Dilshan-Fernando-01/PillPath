//
//  EventService.swift
//  PillPath — Scheduling Module
//

import Foundation
import CoreData

protocol EventServiceProtocol {
    func fetchAll() throws -> [MedicalEvent]
    func save(_ event: MedicalEvent) throws
    func delete(_ event: MedicalEvent) throws
}

final class EventService: EventServiceProtocol {

    private let coreData: CoreDataStack

    init(coreData: CoreDataStack = .shared) {
        self.coreData = coreData
    }

    func fetchAll() throws -> [MedicalEvent] {
        let request = MedicalEventEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        let entities = try coreData.viewContext.fetch(request)
        return entities.compactMap { MedicalEventMapper.toDomain($0) }
    }

    func save(_ event: MedicalEvent) throws {
        _ = MedicalEventMapper.toEntity(event, context: coreData.viewContext)
        coreData.save()
    }

    func delete(_ event: MedicalEvent) throws {
        let request = MedicalEventEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", event.id as CVarArg)
        request.fetchLimit = 1
        guard let entity = try coreData.viewContext.fetch(request).first else { return }
        coreData.viewContext.delete(entity)
        coreData.save()
    }
}
