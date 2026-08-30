import SwiftUI
import PhotosUI

struct ContentView: View {
    @ObservedObject var coordinator = TranslationCoordinator.shared
    @ObservedObject var settings = AppSettings.shared
    @ObservedObject var pipManager = PiPOverlayManager.shared

    @State private var showingSettings = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 18) {
                    // Header Status Card
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Gateway: ai.gmcdev.app")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                            Text(settings.selectedModel)
                                .font(.headline)
                                .foregroundColor(.primary)
                        }
                        Spacer()
                        Circle()
                            .fill(coordinator.isRunning ? Color.green : Color.gray)
                            .frame(width: 12, height: 12)
                        Text(coordinator.isRunning ? "ACTIVE" : "STANDBY")
                            .font(.caption)
                            .fontWeight(.heavy)
                            .foregroundColor(coordinator.isRunning ? .green : .secondary)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(14)

                    // Big Action Button
                    Button(action: {
                        if coordinator.isRunning {
                            coordinator.stopLiveTranslation()
                        } else {
                            coordinator.startLiveTranslation()
                        }
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: coordinator.isRunning ? "stop.circle.fill" : "play.circle.fill")
                                .font(.title2)
                            Text(coordinator.isRunning ? "Stop Floating Translator" : "Start Floating PiP Translator")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(coordinator.isRunning ? Color.red : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                        .shadow(color: (coordinator.isRunning ? Color.red : Color.blue).opacity(0.3), radius: 8, y: 4)
                    }

                    // Floating PiP Preview Card
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "pip.enter")
                                .foregroundColor(.yellow)
                            Text("Floating PiP Subtitle Preview")
                                .font(.subheadline)
                                .fontWeight(.bold)
                            Spacer()
                            if coordinator.isTranslating {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }

                        Text(pipManager.currentTranslation)
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(white: 0.12))
                            .cornerRadius(12)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(16)

                    // Quick Screenshot / Photo Translation Tester
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Test with Pinduoduo Screenshot")
                            .font(.subheadline)
                            .fontWeight(.bold)

                        HStack(spacing: 12) {
                            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                                HStack {
                                    Image(systemName: "photo.badge.plus")
                                    Text("Pick Screenshot")
                                }
                                .font(.subheadline)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(Color(.tertiarySystemBackground))
                                .cornerRadius(10)
                            }

                            Button(action: {
                                if let img = UIPasteboard.general.image {
                                    coordinator.processImageForTranslation(img, force: true)
                                }
                            }) {
                                HStack {
                                    Image(systemName: "doc.on.clipboard")
                                    Text("Paste Image")
                                }
                                .font(.subheadline)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(Color(.tertiarySystemBackground))
                                .cornerRadius(10)
                            }
                        }

                        if let error = coordinator.errorText {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(16)

                    // How to use in Pinduoduo instructions
                    VStack(alignment: .leading, spacing: 8) {
                        Text("💡 How to use with Pinduoduo:")
                            .font(.subheadline)
                            .fontWeight(.bold)
                        Text("1. Tap **Start Floating PiP Translator** above.\n2. Swipe up to go Home (the floating subtitle window will stay on screen).\n3. Open **Pinduoduo** (拼多多).\n4. Take a screenshot or tap the PiP window to instantly see English product title, specs, prices, and reviews translated via Gemini 3.7 Flash.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(16)
                }
                .padding()
            }
            .navigationTitle("Pinduoduo AI Translator")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gearshape.fill")
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .onChange(of: selectedPhotoItem) { newItem in
                guard let newItem = newItem else { return }
                Task {
                    if let data = try? await newItem.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        coordinator.processImageForTranslation(image, force: true)
                    }
                }
            }
        }
    }
}
