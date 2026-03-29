//
//  MedicationService.swift
//  PillPath — Medications Module
//

import Foundation
import CoreData

protocol MedicationServiceProtocol {
    func fetchAll() throws -> [Medication]
    func fetchActive() throws -> [Medication]
    func fetch(id: UUID) throws -> Medication?
    func save(_ medication: Medication) throws
    func delete(_ medication: Medication) throws
    func searchOpenFDA(query: String) async throws -> [Medication]
}

final class MedicationService: MedicationServiceProtocol {

    private let coreData: CoreDataStack
    private let network: NetworkClientProtocol

    init(coreData: CoreDataStack = .shared, network: NetworkClientProtocol = NetworkClient.shared) {
        self.coreData = coreData
        self.network = network
    }

    // MARK: - Fetch

    func fetchAll() throws -> [Medication] {
        let request = MedicationEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "addedAt", ascending: false)]
        let entities = try coreData.viewContext.fetch(request)
        return entities.compactMap { MedicationMapper.toDomain($0) }
    }

    func fetchActive() throws -> [Medication] {
        let request = MedicationEntity.fetchRequest()
        request.predicate = NSPredicate(format: "isActive == YES")
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        let entities = try coreData.viewContext.fetch(request)
        return entities.compactMap { MedicationMapper.toDomain($0) }
    }

    func fetch(id: UUID) throws -> Medication? {
        let request = MedicationEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try coreData.viewContext.fetch(request).first.flatMap { MedicationMapper.toDomain($0) }
    }

    // MARK: - Save / Delete

    func save(_ medication: Medication) throws {
        let entity = MedicationMapper.toEntity(medication, context: coreData.viewContext)
        _ = entity  // entity is already inserted into context
        coreData.save()
    }

    func delete(_ medication: Medication) throws {
        let request = MedicationEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", medication.id as CVarArg)
        request.fetchLimit = 1
        guard let entity = try coreData.viewContext.fetch(request).first else { return }
        coreData.viewContext.delete(entity)
        coreData.save()
    }

    // MARK: - openFDA Search

    func searchOpenFDA(query: String) async throws -> [Medication] {
        let response: OpenFDADrugResponse = try await network.request(
            OpenFDAEndpoint.searchDrug(query: query, limit: 10)
        )
        return FDAMapper.toMedications(response)
    }
}
