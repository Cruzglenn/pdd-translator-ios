import Foundation
import Vision
import UIKit

class OCRService {
    static let shared = OCRService()

    private var lastRecognizedHash: Int = 0

    func recognizeText(from image: UIImage, force: Bool = false) async throws -> (text: String, isNew: Bool) {
        guard let cgImage = image.cgImage else {
            return ("", false)
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { [weak self] (request, error) in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: ("", false))
                    return
                }

                var recognizedStrings: [String] = []
                for observation in observations {
                    if let topCandidate = observation.topCandidates(1).first {
                        let text = topCandidate.string.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !text.isEmpty {
                            recognizedStrings.append(text)
                        }
                    }
                }

                let fullText = recognizedStrings.joined(separator: "\n")
                let textHash = fullText.hashValue

                let isNew = (self?.lastRecognizedHash != textHash) || force
                if isNew {
                    self?.lastRecognizedHash = textHash
                }

                continuation.resume(returning: (fullText, isNew))
            }

            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = ["zh-Hans", "zh-Hant", "en-US"]

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    func resetCache() {
        lastRecognizedHash = 0
    }
}
