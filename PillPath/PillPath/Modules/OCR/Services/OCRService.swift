//
//  OCRService.swift
//  PillPath — OCR Module
//
//  Uses Apple Vision framework for on-device OCR (VNRecognizeTextRequest).
//  No internet required for scanning — openFDA is used to enrich results.
//

import Foundation
import Vision
import UIKit

protocol OCRServiceProtocol {
    func recognizeText(from image: UIImage) async throws -> OCRResult
}

final class OCRService: OCRServiceProtocol {

    func recognizeText(from image: UIImage) async throws -> OCRResult {
        guard let cgImage = image.cgImage else {
            throw OCRError.invalidImage
        }

        // Pre-process: auto-orient the image
        let orientedImage = image.fixedOrientation()
        guard let fixedCG = orientedImage.cgImage else { throw OCRError.invalidImage }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                let observations = request.results as? [VNRecognizedTextObservation] ?? []

                // Use top 2 candidates per observation to improve handwriting coverage,
                // pick the one with higher confidence.
                let text = observations
                    .compactMap { obs -> String? in
                        let top = obs.topCandidates(2)
                        return top.max(by: { $0.confidence < $1.confidence })?.string
                    }
                    .joined(separator: "\n")

                let result = OCRResult(rawText: text)
                continuation.resume(returning: result)
            }

            // .accurate uses a neural-network model — handles printed + handwritten text.
            // iOS 16+ automatically includes handwriting recognition in this level.
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            // Hint the recogniser with medical vocabulary to boost drug-name accuracy.
            request.customWords = OCRService.medicalHintWords

            let handler = VNImageRequestHandler(cgImage: fixedCG, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    // MARK: - Medical vocabulary hints (improves drug-name accuracy for handwriting)

    /// Common drug name fragments fed as hints to the VNRecognizeTextRequest.
    /// These are NOT an exhaustive list — they nudge the language model toward
    /// pharmaceutical vocabulary when interpreting ambiguous handwritten characters.
    static let medicalHintWords: [String] = [
        "Paracetamol", "Acetaminophen", "Ibuprofen", "Amoxicillin", "Metformin",
        "Lisinopril", "Atorvastatin", "Omeprazole", "Amlodipine", "Metoprolol",
        "Simvastatin", "Losartan", "Azithromycin", "Ciprofloxacin", "Cetirizine",
        "Loratadine", "Salbutamol", "Prednisolone", "Dexamethasone", "Warfarin",
        "Aspirin", "Clopidogrel", "Furosemide", "Spironolactone", "Digoxin",
        "Levothyroxine", "Insulin", "Glibenclamide", "Metronidazole", "Fluconazole",
        "mg", "ml", "mcg", "tablet", "capsule", "daily", "twice", "thrice"
    ]
}

// MARK: - UIImage orientation fix

private extension UIImage {
    /// Returns a copy of the image with correct orientation baked in,
    /// which Vision requires for accurate results on photos taken in portrait mode.
    func fixedOrientation() -> UIImage {
        guard imageOrientation != .up else { return self }
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(in: CGRect(origin: .zero, size: size))
        let fixed = UIGraphicsGetImageFromCurrentImageContext() ?? self
        UIGraphicsEndImageContext()
        return fixed
    }
}

// MARK: - Errors

enum OCRError: LocalizedError {
    case invalidImage
    case recognitionFailed

    var errorDescription: String? {
        switch self {
        case .invalidImage:       return "Could not process the image."
        case .recognitionFailed:  return "Text recognition failed."
        }
    }
}
