import Foundation
import UIKit
import ReplayKit
import Combine

class TranslationCoordinator: ObservableObject {
    static let shared = TranslationCoordinator()

    @Published var isRunning = false
    @Published var statusMessage = "Ready"
    @Published var latestSourceText = ""
    @Published var latestTranslation = ""
    @Published var isTranslating = false
    @Published var errorText: String?

    private var captureTimer: Timer?
    private var cancellables = Set<AnyCancellable>()

    private let ocrService = OCRService.shared
    private let translationService = TranslationService.shared
    private let pipManager = PiPOverlayManager.shared
    private let settings = AppSettings.shared

    private init() {}

    func startLiveTranslation() {
        guard !isRunning else { return }
        isRunning = true
        statusMessage = "Live Monitoring Active"
        errorText = nil
        ocrService.resetCache()

        // Start Floating PiP window
        pipManager.startPiP()

        // Periodic screen / clipboard check
        captureTimer = Timer.scheduledTimer(withTimeInterval: settings.refreshInterval, repeats: true) { [weak self] _ in
            self?.processCurrentContext()
        }
        processCurrentContext()
    }

    func stopLiveTranslation() {
        guard isRunning else { return }
        isRunning = false
        statusMessage = "Stopped"
        captureTimer?.invalidate()
        captureTimer = nil
        pipManager.stopPiP()
    }

    func processImageForTranslation(_ image: UIImage, force: Bool = true) {
        Task {
            await MainActor.run {
                self.isTranslating = true
                self.statusMessage = "Analyzing Chinese Text (OCR)..."
                self.pipManager.updateTranslation(text: "🔍 Scanning screen text...", isWorking: true)
            }

            do {
                let (extractedText, isNew) = try await ocrService.recognizeText(from: image, force: force)

                if extractedText.isEmpty {
                    await MainActor.run {
                        self.isTranslating = false
                        self.statusMessage = "No Chinese text detected on screen."
                    }
                    return
                }

                if !isNew && !force {
                    await MainActor.run {
                        self.isTranslating = false
                        self.statusMessage = "Screen content unchanged."
                    }
                    return
                }

                await MainActor.run {
                    self.latestSourceText = extractedText
                    self.statusMessage = "Translating via \(self.settings.selectedModel)..."
                    self.pipManager.updateTranslation(text: "⏳ Translating with AI...", isWorking: true)
                }

                let translated = try await translationService.translate(
                    text: extractedText,
                    endpoint: settings.apiEndpoint,
                    apiKey: settings.apiKey,
                    model: settings.selectedModel,
                    systemPrompt: settings.customSystemPrompt,
                    targetLanguage: settings.targetLanguage
                )

                await MainActor.run {
                    self.latestTranslation = translated
                    self.isTranslating = false
                    self.statusMessage = "Translation Updated"
                    self.pipManager.updateTranslation(text: translated, isWorking: false)
                }

            } catch {
                await MainActor.run {
                    self.isTranslating = false
                    self.errorText = error.localizedDescription
                    self.statusMessage = "Error: \(error.localizedDescription)"
                    self.pipManager.updateTranslation(text: "⚠️ Translation Failed: \(error.localizedDescription)", isWorking: false)
                }
            }
        }
    }

    private func processCurrentContext() {
        // If image is in pasteboard (user took a quick screenshot or shared)
        if let pasteboardImage = UIPasteboard.general.image {
            processImageForTranslation(pasteboardImage, force: false)
        }
    }
}
