//
//  LookupViewModel.swift
//  PillPath — Lookup Module
//
//  Drives the Search Medication screen.
//  Debounces input → openFDA search → suggestions while idle.
//

import Foundation
import Combine

@MainActor
final class LookupViewModel: ObservableObject {

    // MARK: - Published

    @Published var searchText = ""
    @Published var searchResults: [MedicationSearchResult] = []
    @Published var isSearching = false
    @Published var errorMessage: String?
    @Published var selectedResult: MedicationSearchResult?

    // MARK: - Suggestions (shown when search field is empty)

    let suggestions = [
        "Aspirin", "Ibuprofen", "Metformin", "Lisinopril",
        "Amoxicillin", "Atorvastatin", "Omeprazole", "Sertraline"
    ]

    // MARK: - Private

    private let fdaService: FDAServiceProtocol
    private var searchTask: Task<Void, Never>?

    // MARK: - Init

    init(fdaService: FDAServiceProtocol? = nil) {
        self.fdaService = fdaService ?? DIContainer.shared.resolve(FDAServiceProtocol.self)
    }

    // MARK: - Search

    /// Call on every keystroke; debounced internally.
    func onSearchTextChanged(_ text: String) {
        searchTask?.cancel()
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty else {
            searchResults = []
            isSearching = false
            return
        }
        isSearching = true
        searchTask = Task {
            // 400ms debounce
            try? await Task.sleep(nanoseconds: 400_000_000)
            guard !Task.isCancelled else { return }
            await performSearch(query: text)
        }
    }

    func search(query: String) async {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        searchText = query
        await performSearch(query: query)
    }

    private func performSearch(query: String) async {
        isSearching = true
        errorMessage = nil
        do {
            let results = try await fdaService.search(query: query, limit: 15)
            searchResults = results
        } catch {
            if (error as? CancellationError) == nil {
                errorMessage = "Search failed. Please check your connection."
            }
        }
        isSearching = false
    }

    func clearSearch() {
        searchText = ""
        searchResults = []
        isSearching = false
        errorMessage = nil
        searchTask?.cancel()
    }
}
