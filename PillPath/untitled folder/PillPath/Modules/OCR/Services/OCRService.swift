

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

       
        let orientedImage = image.fixedOrientation()
        guard let fixedCG = orientedImage.cgImage else { throw OCRError.invalidImage }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                let observations = request.results as? [VNRecognizedTextObservation] ?? []

               let text = observations
                    .compactMap { obs -> String? in
                        let top = obs.topCandidates(2)
                        return top.max(by: { $0.confidence < $1.confidence })?.string
                    }
                    .joined(separator: "\n")

                let result = OCRResult(rawText: text)
                continuation.resume(returning: result)
            }

           request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
           
            request.customWords = OCRService.medicalHintWords

            let handler = VNImageRequestHandler(cgImage: fixedCG, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

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



private extension UIImage {
   func fixedOrientation() -> UIImage {
        guard imageOrientation != .up else { return self }
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(in: CGRect(origin: .zero, size: size))
        let fixed = UIGraphicsGetImageFromCurrentImageContext() ?? self
        UIGraphicsEndImageContext()
        return fixed
    }
}



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
