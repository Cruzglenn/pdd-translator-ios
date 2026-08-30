import Foundation
import SwiftUI

class AppSettings: ObservableObject {
    static let shared = AppSettings()

    private let kApiEndpoint = "app_api_endpoint"
    private let kApiKey = "app_api_key"
    private let kSelectedModel = "app_selected_model"
    private let kRefreshInterval = "app_refresh_interval"
    private let kCustomSystemPrompt = "app_custom_system_prompt"
    private let kTargetLanguage = "app_target_language"

    @Published var apiEndpoint: String {
        didSet { UserDefaults.standard.set(apiEndpoint, forKey: kApiEndpoint) }
    }

    @Published var apiKey: String {
        didSet { UserDefaults.standard.set(apiKey, forKey: kApiKey) }
    }

    @Published var selectedModel: String {
        didSet { UserDefaults.standard.set(selectedModel, forKey: kSelectedModel) }
    }

    @Published var refreshInterval: Double {
        didSet { UserDefaults.standard.set(refreshInterval, forKey: kRefreshInterval) }
    }

    @Published var customSystemPrompt: String {
        didSet { UserDefaults.standard.set(customSystemPrompt, forKey: kCustomSystemPrompt) }
    }

    @Published var targetLanguage: String {
        didSet { UserDefaults.standard.set(targetLanguage, forKey: kTargetLanguage) }
    }

    let defaultModels = [
        "gemini-3.7-flash-high",
        "claude-3-7-sonnet-20250219",
        "claude-3-5-sonnet-latest",
        "gpt-4o",
        "gpt-4o-mini"
    ]

    private init() {
        self.apiEndpoint = UserDefaults.standard.string(forKey: kApiEndpoint) ?? "https://ai.gmcdev.app/v1"
        self.apiKey = UserDefaults.standard.string(forKey: kApiKey) ?? ""
        self.selectedModel = UserDefaults.standard.string(forKey: kSelectedModel) ?? "gemini-3.7-flash-high"
        self.refreshInterval = UserDefaults.standard.double(forKey: kRefreshInterval) == 0 ? 2.5 : UserDefaults.standard.double(forKey: kRefreshInterval)
        self.targetLanguage = UserDefaults.standard.string(forKey: kTargetLanguage) ?? "English"
        self.customSystemPrompt = UserDefaults.standard.string(forKey: kCustomSystemPrompt) ?? """
You are a real-time shopping screen translator specialized in Chinese e-commerce apps like Pinduoduo (拼多多), Taobao, and JD.
Translate all Chinese text cleanly, accurately, and concisely into natural English.
Format key sections clearly:
- 🏷️ Item Name / Product Title
- 💰 Price & Group Buy (拼单) Deals
- 📦 Specs / Variants (Color, Size, Options)
- ⭐ Reviews / Ratings & Seller Info
- 🚚 Shipping & Vouchers / Coupons
Keep translations concise for small on-screen subtitles.
"""
    }

    func resetToDefaults() {
        apiEndpoint = "https://ai.gmcdev.app/v1"
        apiKey = ""
        selectedModel = "gemini-3.7-flash-high"
        refreshInterval = 2.5
        targetLanguage = "English"
    }
}
