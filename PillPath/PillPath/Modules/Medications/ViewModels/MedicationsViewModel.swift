//
//  MedicationsViewModel.swift
//  PillPath — Medications Module
//

import Foundation
import Combine

@MainActor
final class MedicationsViewModel: ObservableObject {

    @Published var medications: [Medication] = []
    @Published var searchResults: [Medication] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let service: MedicationServiceProtocol

    init(service: MedicationServiceProtocol? = nil) {
        self.service = service ?? DIContainer.shared.resolve(MedicationServiceProtocol.self)
    }

    func loadMedications() {
        do {
            medications = try service.fetchAll()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func addMedication(_ medication: Medication) {
        do {
            try service.save(medication)
            loadMedications()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggleActive(_ medication: Medication, change: MedicationStatusChange) {
        var updated = medication
        updated.isActive = change.isActive
        updated.statusChange = change
        do {
            try service.save(updated)
            loadMedications()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteMedication(_ medication: Medication) {
        do {
            try service.delete(medication)
            medications.removeAll { $0.id == medication.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func searchOpenFDA(query: String) async {
        guard !query.isEmpty else { return }
        isLoading = true
        errorMessage = nil
        do {
            searchResults = try await service.searchOpenFDA(query: query)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
