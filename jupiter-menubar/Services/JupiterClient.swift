import Foundation

enum JupiterError: Error, LocalizedError {
    case missingApiKey
    case rateLimited(retryAfter: TimeInterval)
    case http(status: Int, body: String)
    case decoding(Error)
    case transport(Error)
    case invalidURL

    var errorDescription: String? {
        switch self {
        case .missingApiKey: return "Add a Jupiter API key in Settings."
        case .rateLimited(let ra): return "Rate limited (retry in \(Int(ra))s)."
        case .http(let status, _): return "HTTP \(status)"
        case .decoding: return "Decoding failed"
        case .transport(let err): return "Network error: \(err.localizedDescription)"
        case .invalidURL: return "Invalid URL"
        }
    }
}

actor JupiterClient {
    static let shared = JupiterClient()

    private let baseURL = URL(string: "https://api.jup.ag")!
    private let session: URLSession
    private var apiKeyProvider: () -> String? = { nil }

    init(session: URLSession = .shared) {
        self.session = session
    }

    func setApiKeyProvider(_ provider: @escaping () -> String?) {
        self.apiKeyProvider = provider
    }

    func get<T: Decodable>(_ path: String, query: [String: String] = [:]) async throws -> T {
        guard let key = apiKeyProvider(), !key.isEmpty else {
            throw JupiterError.missingApiKey
        }

        var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)
        if !query.isEmpty {
            components?.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        guard let url = components?.url else { throw JupiterError.invalidURL }

        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 15)
        request.setValue(key, forHTTPHeaderField: "x-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw JupiterError.transport(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw JupiterError.http(status: -1, body: "Not HTTP")
        }

        if http.statusCode == 429 {
            let retry = http.value(forHTTPHeaderField: "Retry-After").flatMap(TimeInterval.init) ?? 10
            throw JupiterError.rateLimited(retryAfter: retry)
        }
        if http.statusCode == 401 || http.statusCode == 403 {
            throw JupiterError.missingApiKey
        }
        guard (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw JupiterError.http(status: http.statusCode, body: body)
        }

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw JupiterError.decoding(error)
        }
    }
}
