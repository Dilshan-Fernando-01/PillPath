//
//  FDAService.swift
//  PillPath — Medications Module
//
//  Clean DTO wrapper around openFDA.
//  The rest of the app only sees [MedicationSearchResult] — never raw API JSON.
//

import Foundation

// MARK: - Protocol

protocol FDAServiceProtocol {
    func search(query: String, limit: Int) async throws -> [MedicationSearchResult]
    func details(for name: String) async throws -> MedicationSearchResult?
}

// MARK: - Clean DTO (not the raw API response)

struct MedicationSearchResult: Identifiable, Codable, Hashable {
    let id: UUID
    let brandName: String
    let genericName: String?
    let manufacturer: String?
    let dosageForms: [String]
    let pharmClass: [String]                   // e.g. ["Analgesic", "Antipyretic"]
    let indications: String?
    let dosageAndAdministration: [String]      // numbered how-to-use steps
    let warnings: String?
    let interactions: String?
    let sideEffects: [String]

    /// Converts the search result into a pre-filled Medication domain model.
    func toMedication() -> Medication {
        Medication(
            name: brandName,
            genericName: genericName,
            form: dosageForms.first.flatMap { MedicationForm(rawValue: $0.lowercased()) } ?? .tablet,
            instructions: indications,
            sideEffects: sideEffects,
            interactions: interactions.map { [$0] } ?? []
        )
    }
}

// MARK: - Service

final class FDAService: FDAServiceProtocol {

    private let network: NetworkClientProtocol

    init(network: NetworkClientProtocol = NetworkClient.shared) {
        self.network = network
    }

    func search(query: String, limit: Int = 10) async throws -> [MedicationSearchResult] {
        guard !query.isEmpty else { return [] }
        let response: OpenFDADrugResponse = try await network.request(
            OpenFDAEndpoint.searchDrug(query: query, limit: limit)
        )
        return FDAMapper.toSearchResults(response)
    }

    func details(for name: String) async throws -> MedicationSearchResult? {
        let response: OpenFDADrugResponse = try await network.request(
            OpenFDAEndpoint.drugLabel(name: name)
        )
        return FDAMapper.toSearchResults(response).first
    }
}

// MARK: - FDA Response Models (raw API — stay in this file)

struct OpenFDADrugResponse: Decodable {
    let results: [OpenFDADrugResult]?
}

struct OpenFDADrugResult: Decodable {
    let openfda: OpenFDAInfo?
    let indications_and_usage: [String]?
    let warnings: [String]?
    let drug_interactions: [String]?
    let dosage_and_administration: [String]?
    let adverse_reactions: [String]?
}

struct OpenFDAInfo: Decodable {
    let brand_name: [String]?
    let generic_name: [String]?
    let manufacturer_name: [String]?
    let dosage_form: [String]?
    let pharm_class_epc: [String]?   // Established Pharmacologic Class
}

// MARK: - FDA Mapper

enum FDAMapper {

    static func toSearchResults(_ response: OpenFDADrugResponse) -> [MedicationSearchResult] {
        (response.results ?? []).compactMap { result in
            guard let brandName = result.openfda?.brand_name?.first else { return nil }
            return MedicationSearchResult(
                id: UUID(),
                brandName: brandName,
                genericName: result.openfda?.generic_name?.first,
                manufacturer: result.openfda?.manufacturer_name?.first,
                dosageForms: result.openfda?.dosage_form ?? [],
                pharmClass: result.openfda?.pharm_class_epc ?? [],
                indications: result.indications_and_usage?.first,
                dosageAndAdministration: result.dosage_and_administration ?? [],
                warnings: result.warnings?.first,
                interactions: result.drug_interactions?.first,
                sideEffects: result.adverse_reactions ?? []
            )
        }
    }

    static func toMedications(_ response: OpenFDADrugResponse) -> [Medication] {
        toSearchResults(response).map { $0.toMedication() }
    }
}
