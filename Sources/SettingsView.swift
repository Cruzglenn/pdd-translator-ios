import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings = AppSettings.shared
    @Environment(\.dismiss) var dismiss
    @State private var showingResetAlert = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("AI Gateway & Server Endpoint")) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Base URL")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("https://ai.gmcdev.app/v1", text: $settings.apiEndpoint)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .font(.system(.body, design: .monospaced))
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("API Key (BYO or Default Gateway Key)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        SecureField("API Key", text: $settings.apiKey)
                            .font(.system(.body, design: .monospaced))
                    }
                }

                Section(header: Text("Model Selection")) {
                    Picker("Active LLM Model", selection: $settings.selectedModel) {
                        ForEach(settings.defaultModels, id: \.self) { model in
                            Text(model).tag(model)
                        }
                    }

                    HStack {
                        Text("Target Language")
                        Spacer()
                        TextField("English", text: $settings.targetLanguage)
                            .multilineTextAlignment(.trailing)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Screen Check Interval")
                            Spacer()
                            Text(String(format: "%.1f sec", settings.refreshInterval))
                                .foregroundColor(.secondary)
                        }
                        Slider(value: $settings.refreshInterval, in: 1.0...5.0, step: 0.5)
                    }
                }

                Section(header: Text("Pinduoduo Specialized System Prompt")) {
                    TextEditor(text: $settings.customSystemPrompt)
                        .frame(height: 140)
                        .font(.footnote)
                }

                Section {
                    Button(role: .destructive, action: { showingResetAlert = true }) {
                        HStack {
                            Spacer()
                            Text("Reset Settings to Default")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Configuration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Reset Configuration?", isPresented: $showingResetAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    settings.resetToDefaults()
                }
            } message: {
                Text("This will restore default endpoint (ai.gmcdev.app) and gemini-3.7-flash-high model.")
            }
        }
    }
}
