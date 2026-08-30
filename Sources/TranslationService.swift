import Foundation

enum TranslationError: LocalizedError {
    case invalidURL
    case invalidResponse(Int)
    case emptyResponse
    case decodingError(String)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API Endpoint URL. Please verify in Settings."
        case .invalidResponse(let code):
            return "Server responded with HTTP Status \(code)."
        case .emptyResponse:
            return "Empty response received from AI Gateway."
        case .decodingError(let msg):
            return "Failed to parse AI response: \(msg)"
        case .networkError(let err):
            return "Network connection error: \(err.localizedDescription)"
        }
    }
}

actor TranslationService {
    static let shared = TranslationService()

    func translate(
        text: String,
        endpoint: String,
        apiKey: String,
        model: String,
        systemPrompt: String,
        targetLanguage: String
    ) async throws -> String {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return ""
        }

        // Clean endpoint formatting
        var cleanedEndpoint = endpoint.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleanedEndpoint.hasSuffix("/") {
            cleanedEndpoint.removeLast()
        }
        if !cleanedEndpoint.hasSuffix("/chat/completions") {
            if cleanedEndpoint.hasSuffix("/v1") {
                cleanedEndpoint += "/chat/completions"
            } else {
                cleanedEndpoint += "/v1/chat/completions"
            }
        }

        guard let url = URL(string: cleanedEndpoint) else {
            throw TranslationError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey.trimmingCharacters(in: .whitespacesAndNewlines))", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 15

        let requestPayload: [String: Any] = [
            "model": model,
            "temperature": 0.2,
            "max_tokens": 1024,
            "messages": [
                [
                    "role": "system",
                    "content": "\(systemPrompt)\nTarget translation language: \(targetLanguage)."
                ],
                [
                    "role": "user",
                    "content": "Translate the following Chinese text into \(targetLanguage):\n\n\(text)"
                ]
            ]
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestPayload, options: [])
        } catch {
            throw TranslationError.decodingError("Failed to serialize request JSON: \(error.localizedDescription)")
        }

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw TranslationError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw TranslationError.invalidResponse(0)
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorBody = String(data: data, encoding: .utf8) {
                print("Translation API Error [\(httpResponse.statusCode)]: \(errorBody)")
            }
            throw TranslationError.invalidResponse(httpResponse.statusCode)
        }

        do {
            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let choices = json["choices"] as? [[String: Any]],
               let firstChoice = choices.first,
               let message = firstChoice["message"] as? [String: Any],
               let content = message["content"] as? String {
                return content.trimmingCharacters(in: .whitespacesAndNewlines)
            } else {
                throw TranslationError.emptyResponse
            }
        } catch {
            throw TranslationError.decodingError(error.localizedDescription)
        }
    }
}
