//
//  PrescriptionValidationService.swift
//  PillPath — OCR Module
//
//  Validates a list of raw medication name candidates against openFDA.
//  Returns [ScannedMedicationItem] with confidence scores and FDA-matched names.
//
//  Confidence scoring uses Jaro-Winkler string similarity — pure Swift, no library.
//

import Foundation

protocol PrescriptionValidationServiceProtocol {
    func validate(candidates: [String]) async -> [ScannedMedicationItem]
}

final class PrescriptionValidationService: PrescriptionValidationServiceProtocol {

    private let fdaService: FDAServiceProtocol

    // Confidence thresholds
    static let exactThreshold:   Int = 95
    static let partialThreshold: Int = 60
    static let autoAcceptThreshold: Int = 75

    init(fdaService: FDAServiceProtocol? = nil) {
        self.fdaService = fdaService ?? DIContainer.shared.resolve(FDAServiceProtocol.self)
    }

    func validate(candidates: [String]) async -> [ScannedMedicationItem] {
        // Deduplicate before API calls
        let unique = Array(OrderedSet(candidates))

        // Run all FDA searches concurrently (one task per candidate)
        return await withTaskGroup(of: ScannedMedicationItem.self) { group in
            for name in unique {
                group.addTask { await self.validateSingle(name) }
            }
            var results: [ScannedMedicationItem] = []
            for await item in group { results.append(item) }
            // Preserve original ordering
            return unique.compactMap { name in
                results.first { $0.originalName == name }
            }
        }
    }

    // MARK: - Single validation

    private func validateSingle(_ name: String) async -> ScannedMedicationItem {
        do {
            let fdaResults = try await fdaService.search(query: name, limit: 5)

            guard !fdaResults.isEmpty else {
                return ScannedMedicationItem(originalName: name, matchStatus: .none)
            }

            // Score each FDA result against the original name
            let scored: [(result: MedicationSearchResult, score: Int)] = fdaResults.map { result in
                let brandScore   = jaroWinklerSimilarity(name.lowercased(), result.brandName.lowercased())
                let genericScore = result.genericName.map {
                    jaroWinklerSimilarity(name.lowercased(), $0.lowercased())
                } ?? 0
                return (result, max(brandScore, genericScore))
            }

            guard let best = scored.max(by: { $0.score < $1.score }) else {
                return ScannedMedicationItem(originalName: name, matchStatus: .none)
            }

            let matchStatus: ScannedMedicationItem.MatchStatus
            switch best.score {
            case Self.exactThreshold...:   matchStatus = .exact
            case Self.partialThreshold...: matchStatus = .partial
            default:                        matchStatus = .none
            }

            // Guess form from FDA dosage forms
            let guessedForm = best.result.dosageForms.first
                .flatMap { MedicationForm(rawValue: $0.lowercased()) } ?? .tablet

            return ScannedMedicationItem(
                originalName: name,
                fdaMatchName: best.result.brandName,
                fdaResult: best.result,
                confidence: best.score,
                matchStatus: matchStatus,
                suggestedForm: guessedForm
            )

        } catch {
            return ScannedMedicationItem(originalName: name, matchStatus: .none)
        }
    }

    // MARK: - Jaro-Winkler similarity (returns 0–100)

    private func jaroWinklerSimilarity(_ s1: String, _ s2: String) -> Int {
        let jaro = jaroSimilarity(s1, s2)
        let prefix = commonPrefixLength(s1, s2, maxLen: 4)
        let p = 0.1  // standard winkler constant
        let jw = jaro + Double(prefix) * p * (1.0 - jaro)
        return Int((jw * 100).rounded())
    }

    private func jaroSimilarity(_ s1: String, _ s2: String) -> Double {
        if s1 == s2 { return 1.0 }
        let a = Array(s1), b = Array(s2)
        let la = a.count, lb = b.count
        guard la > 0, lb > 0 else { return 0 }
        let matchDist = max(la, lb) / 2 - 1
        var matchedA = [Bool](repeating: false, count: la)
        var matchedB = [Bool](repeating: false, count: lb)
        var matches = 0
        for i in 0..<la {
            let lo = max(0, i - matchDist)
            let hi = min(i + matchDist, lb - 1)
            for j in lo...hi where !matchedB[j] && a[i] == b[j] {
                matchedA[i] = true
                matchedB[j] = true
                matches += 1
                break
            }
        }
        guard matches > 0 else { return 0 }
        var transpositions = 0
        var k = 0
        for i in 0..<la where matchedA[i] {
            while !matchedB[k] { k += 1 }
            if a[i] != b[k] { transpositions += 1 }
            k += 1
        }
        let m = Double(matches)
        return (m / Double(la) + m / Double(lb) + (m - Double(transpositions) / 2) / m) / 3.0
    }

    private func commonPrefixLength(_ s1: String, _ s2: String, maxLen: Int) -> Int {
        var count = 0
        for (c1, c2) in zip(s1, s2) {
            if count >= maxLen || c1 != c2 { break }
            count += 1
        }
        return count
    }
}

// MARK: - Ordered Set helper (preserves insertion order, deduplicates)

private struct OrderedSet<T: Hashable>: Sequence {
    private var set  = Set<T>()
    private var list = [T]()

    init(_ elements: [T]) {
        elements.forEach { insert($0) }
    }

    mutating func insert(_ element: T) {
        if set.insert(element).inserted { list.append(element) }
    }

    func makeIterator() -> IndexingIterator<[T]> { list.makeIterator() }
}
