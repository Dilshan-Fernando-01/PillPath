//
//  MedicationExtractionService.swift
//  PillPath — OCR Module
//
//  Parses raw OCR text → candidate medication name strings.
//  Pure Swift logic — no CoreData or network dependencies.
//
//  Strategy:
//  1. Split text into lines and tokens
//  2. Apply heuristic filters to identify drug-like tokens
//  3. Normalise and deduplicate
//

import Foundation

protocol MedicationExtractionServiceProtocol {
    func extractCandidates(from rawText: String) -> [String]
}

final class MedicationExtractionService: MedicationExtractionServiceProtocol {

    // Common non-drug words that appear on prescriptions (noise filter)
    private static let stopWords: Set<String> = [
        "take", "tablet", "tablets", "capsule", "capsules", "pill", "pills",
        "daily", "twice", "thrice", "once", "every", "hours", "days", "weeks",
        "morning", "evening", "night", "bedtime", "meal", "food", "water",
        "before", "after", "with", "without", "dose", "dosage", "mg", "ml",
        "patient", "name", "date", "doctor", "dr", "rx", "refill", "sig",
        "quantity", "qty", "dispense", "pharmacy", "phone", "address",
        "signature", "signed", "prescribed", "prescription",
        "for", "use", "as", "directed", "per", "oral", "by", "mouth",
        "the", "and", "or", "in", "of", "to", "a", "an"
    ]

    // Regex: tokens that look like dosage annotations (strip these)
    private static let dosageSuffixPattern = try? NSRegularExpression(
        pattern: #"^\d+(\.\d+)?\s*(mg|ml|mcg|g|iu|tabs?|caps?)$"#,
        options: .caseInsensitive
    )

    func extractCandidates(from rawText: String) -> [String] {
        guard !rawText.isEmpty else { return [] }

        // 1. Split into lines to process context-aware
        let lines = rawText.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        var candidates: [String] = []

        for line in lines {
            let extracted = extractFromLine(line)
            candidates.append(contentsOf: extracted)
        }

        // 2. Deduplicate preserving order (case-insensitive)
        var seen = Set<String>()
        return candidates.filter { candidate in
            let key = candidate.lowercased()
            if seen.contains(key) { return false }
            seen.insert(key)
            return true
        }
    }

    // MARK: - Line-level extraction

    private func extractFromLine(_ line: String) -> [String] {
        // Common prescription line patterns:
        // "1. Paracetamol 500mg" → "Paracetamol"
        // "Rx: Amoxicillin 250mg" → "Amoxicillin"
        // "Take Ibuprofen 200mg twice daily" → "Ibuprofen"
        // "- Metformin (500 mg)" → "Metformin"

        // Strip leading numbering / bullets / Rx prefix
        var cleaned = line
        cleaned = cleaned.replacingOccurrences(
            of: #"^(\d+[\.\)]\s*|[-•*]\s*|Rx\s*:\s*|Take\s+)"#,
            with: "",
            options: .regularExpression
        )

        // Tokenise
        let tokens = cleaned.components(separatedBy: CharacterSet.whitespaces.union(.punctuationCharacters))
            .map { $0.trimmingCharacters(in: .punctuationCharacters) }
            .filter { !$0.isEmpty }

        var results: [String] = []

        for token in tokens {
            guard isDrugCandidate(token) else { continue }
            results.append(normalise(token))
        }

        // Also try multi-word: "Atorvastatin Calcium" → return full word too
        if results.count >= 2 {
            let joined = results.prefix(2).joined(separator: " ")
            results.append(joined)
        }

        return results
    }

    // MARK: - Heuristics

    private func isDrugCandidate(_ token: String) -> Bool {
        let lower = token.lowercased()

        // Must be at least 4 characters
        guard token.count >= 4 else { return false }

        // Reject pure numbers or dosage strings
        if isDosage(token) { return false }

        // Reject stop words
        if Self.stopWords.contains(lower) { return false }

        // Reject tokens that are all-uppercase and short (like "RX", "OTC")
        if token == token.uppercased() && token.count < 6 { return false }

        // Accept: starts with uppercase (drug brand) or lowercase 6+ chars (generic)
        let firstChar = token.unicodeScalars.first.map { CharacterSet.uppercaseLetters.contains($0) } ?? false
        return firstChar || token.count >= 6
    }

    private func isDosage(_ token: String) -> Bool {
        let range = NSRange(token.startIndex..., in: token)
        return Self.dosageSuffixPattern?.firstMatch(in: token, range: range) != nil
    }

    private func normalise(_ token: String) -> String {
        // Capitalise first letter, lowercase rest (for brand names that might be ALL CAPS)
        guard let first = token.first else { return token }
        return first.uppercased() + token.dropFirst().lowercased()
    }
}
