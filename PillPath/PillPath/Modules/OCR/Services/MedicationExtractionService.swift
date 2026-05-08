
import Foundation

protocol MedicationExtractionServiceProtocol {
    func extractCandidates(from rawText: String) -> [String]
}

final class MedicationExtractionService: MedicationExtractionServiceProtocol {

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

    private static let dosageSuffixPattern = try? NSRegularExpression(
        pattern: #"^\d+(\.\d+)?\s*(mg|ml|mcg|g|iu|tabs?|caps?)$"#,
        options: .caseInsensitive
    )

    func extractCandidates(from rawText: String) -> [String] {
        guard !rawText.isEmpty else { return [] }

        let lines = rawText.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        var candidates: [String] = []

        for line in lines {
            let extracted = extractFromLine(line)
            candidates.append(contentsOf: extracted)
        }

        var seen = Set<String>()
        return candidates.filter { candidate in
            let key = candidate.lowercased()
            if seen.contains(key) { return false }
            seen.insert(key)
            return true
        }
    }


    private func extractFromLine(_ line: String) -> [String] {

        var cleaned = line
        cleaned = cleaned.replacingOccurrences(
            of: #"^(\d+[\.\)]\s*|[-•*]\s*|Rx\s*:\s*|Take\s+)"#,
            with: "",
            options: .regularExpression
        )

        let tokens = cleaned.components(separatedBy: CharacterSet.whitespaces.union(.punctuationCharacters))
            .map { $0.trimmingCharacters(in: .punctuationCharacters) }
            .filter { !$0.isEmpty }

        var results: [String] = []

        for token in tokens {
            guard isDrugCandidate(token) else { continue }
            results.append(normalise(token))
        }

        if results.count >= 2 {
            let joined = results.prefix(2).joined(separator: " ")
            results.append(joined)
        }

        return results
    }


    private func isDrugCandidate(_ token: String) -> Bool {
        let lower = token.lowercased()

        guard token.count >= 4 else { return false }

        if isDosage(token) { return false }

        if Self.stopWords.contains(lower) { return false }

        if token == token.uppercased() && token.count < 6 { return false }

        let firstChar = token.unicodeScalars.first.map { CharacterSet.uppercaseLetters.contains($0) } ?? false
        return firstChar || token.count >= 6
    }

    private func isDosage(_ token: String) -> Bool {
        let range = NSRange(token.startIndex..., in: token)
        return Self.dosageSuffixPattern?.firstMatch(in: token, range: range) != nil
    }

    private func normalise(_ token: String) -> String {
        guard let first = token.first else { return token }
        return first.uppercased() + token.dropFirst().lowercased()
    }
}
