import Foundation

struct APIClient {
    enum APIError: LocalizedError {
        case emptyBaseURL
        case invalidURL
        case invalidResponse
        case server(statusCode: Int, message: String)

        var errorDescription: String? {
            switch self {
            case .emptyBaseURL:
                return "Enter a valid API Base URL first."
            case .invalidURL:
                return "The API URL is invalid."
            case .invalidResponse:
                return "The server returned an invalid response."
            case let .server(statusCode, message):
                return "Server error \(statusCode): \(message)"
            }
        }
    }

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchPendingOrders(settings: AppSettings) async throws -> [OrderQueueItem] {
        guard let baseURL = settings.normalizedBaseURL else {
            throw APIError.emptyBaseURL
        }

        guard let url = buildURL(baseURL: baseURL, path: "v1/orders/pending", queryItems: [
            URLQueryItem(name: "limit", value: String(settings.notificationCount))
        ]) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        applyToken(settings.appToken, to: &request)

        let (data, response) = try await session.data(for: request)
        try validate(response: response, data: data)

        let decoded = try JSONDecoder().decode(PendingOrdersResponse.self, from: data)
        return decoded.items
    }

    func acknowledgeOrders(settings: AppSettings, ids: [String]) async throws -> [String] {
        guard let baseURL = settings.normalizedBaseURL else {
            throw APIError.emptyBaseURL
        }

        guard let url = buildURL(baseURL: baseURL, path: "v1/orders/ack") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        applyToken(settings.appToken, to: &request)
        request.httpBody = try JSONEncoder().encode(AckRequest(ids: ids))

        let (data, response) = try await session.data(for: request)
        try validate(response: response, data: data)

        let decoded = try JSONDecoder().decode(AckResponse.self, from: data)
        return decoded.acknowledgedIDs
    }

    private func buildURL(baseURL: URL, path: String, queryItems: [URLQueryItem] = []) -> URL? {
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            return nil
        }

        let existingPath = components.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let requestedPath = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        components.path = "/" + [existingPath, requestedPath].filter { !$0.isEmpty }.joined(separator: "/")
        components.queryItems = queryItems.isEmpty ? nil : queryItems
        return components.url
    }

    private func applyToken(_ token: String, to request: inout URLRequest) {
        let trimmed = token.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            request.setValue(trimmed, forHTTPHeaderField: "X-App-Token")
        }
    }

    private func validate(response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200 ..< 300).contains(httpResponse.statusCode) else {
            let message = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])?["detail"] as? String
                ?? String(data: data, encoding: .utf8)
                ?? "Unknown error"
            throw APIError.server(statusCode: httpResponse.statusCode, message: message)
        }
    }
}
