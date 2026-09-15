import Foundation

enum ChatError: LocalizedError {
    case invalidURL(String)
    case http(status: Int, body: String)
    case noChoices
    case emptyKey

    var errorDescription: String? {
        switch self {
        case .invalidURL(let value):
            return "Invalid API URL: \(value)"
        case .http(let status, let body):
            return "HTTP \(status): \(body)"
        case .noChoices:
            return "The API returned no choices."
        case .emptyKey:
            return "Add an API key in Settings"
        }
    }
}

enum ChatClient {
    static func complete(
        baseURL: String,
        model: String,
        apiKey: String,
        system: String,
        user: String
    ) async throws -> String {
        guard !apiKey.isEmpty else { throw ChatError.emptyKey }

        var root = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        if root.hasSuffix("/") {
            root.removeLast()
        }
        let urlString = root + "/chat/completions"
        guard let url = URL(string: urlString) else {
            throw ChatError.invalidURL(urlString)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 60
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let payload = ChatRequest(
            model: model,
            messages: [
                .init(role: "system", content: system),
                .init(role: "user", content: user),
            ]
        )
        request.httpBody = try JSONEncoder().encode(payload)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw ChatError.http(status: -1, body: "No HTTP response")
        }
        if http.statusCode >= 400 {
            let raw = String(data: data, encoding: .utf8) ?? ""
            let prefix = String(raw.prefix(300))
            throw ChatError.http(status: http.statusCode, body: prefix)
        }

        let decoded = try JSONDecoder().decode(ChatResponse.self, from: data)
        guard let content = decoded.choices.first?.message.content, !content.isEmpty else {
            throw ChatError.noChoices
        }
        return content
    }
}

private struct ChatRequest: Encodable {
    struct Message: Encodable {
        var role: String
        var content: String
    }

    var model: String
    var messages: [Message]
}

private struct ChatResponse: Decodable {
    struct Choice: Decodable {
        struct Message: Decodable {
            var content: String?
        }

        var message: Message
    }

    var choices: [Choice]
}
