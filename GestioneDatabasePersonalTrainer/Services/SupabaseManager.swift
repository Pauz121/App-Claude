import Foundation

enum SupabaseError: LocalizedError {
    case notConfigured
    case invalidURL
    case invalidResponse
    case apiError(String)
    case missingSession

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Configura Supabase URL e anon key in AppConfiguration.swift."
        case .invalidURL:
            return "URL Supabase non valido."
        case .invalidResponse:
            return "Risposta Supabase non valida."
        case .apiError(let message):
            return message
        case .missingSession:
            return "Sessione non disponibile."
        }
    }
}

struct SupabaseAuthUser: Codable {
    let id: UUID
    let email: String?
}

struct SupabaseAuthSession: Codable {
    let accessToken: String
    let refreshToken: String?
    let user: SupabaseAuthUser

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case user
    }
}

final class SupabaseManager {
    static let shared = SupabaseManager()

    private let urlSession: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private let sessionKey = "supabase.auth.session"

    private(set) var session: SupabaseAuthSession?

    private init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
        decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        restoreSession()
    }

    func restoreSession() {
        guard let data = UserDefaults.standard.data(forKey: sessionKey) else { return }
        session = try? decoder.decode(SupabaseAuthSession.self, from: data)
    }

    func clearSession() {
        session = nil
        UserDefaults.standard.removeObject(forKey: sessionKey)
    }

    func signUp(email: String, password: String) async throws -> SupabaseAuthSession {
        let response: SupabaseAuthSession = try await authRequest(path: "/auth/v1/signup", body: [
            "email": email,
            "password": password
        ])
        save(response)
        return response
    }

    func signIn(email: String, password: String) async throws -> SupabaseAuthSession {
        let response: SupabaseAuthSession = try await authRequest(path: "/auth/v1/token?grant_type=password", body: [
            "email": email,
            "password": password
        ])
        save(response)
        return response
    }

    func signOut() async {
        _ = try? await request(path: "/auth/v1/logout", method: "POST", body: EmptyBody(), authenticated: true)
        clearSession()
    }

    func select<T: Decodable>(_ table: String, queryItems: [URLQueryItem] = []) async throws -> [T] {
        let data = try await request(path: "/rest/v1/\(table)", method: "GET", queryItems: queryItems, body: OptionalBody.none, authenticated: true)
        return try decoder.decode([T].self, from: data)
    }

    func insert<T: Encodable, R: Decodable>(_ table: String, value: T) async throws -> [R] {
        let data = try await request(path: "/rest/v1/\(table)", method: "POST", body: value, authenticated: true, preferRepresentation: true)
        return try decoder.decode([R].self, from: data)
    }

    func update<T: Encodable, R: Decodable>(_ table: String, filters: [URLQueryItem], value: T) async throws -> [R] {
        let data = try await request(path: "/rest/v1/\(table)", method: "PATCH", queryItems: filters, body: value, authenticated: true, preferRepresentation: true)
        return try decoder.decode([R].self, from: data)
    }

    func delete(_ table: String, filters: [URLQueryItem]) async throws {
        _ = try await request(path: "/rest/v1/\(table)", method: "DELETE", queryItems: filters, body: OptionalBody.none, authenticated: true)
    }

    func rpc<T: Encodable, R: Decodable>(_ name: String, params: T) async throws -> R {
        let data = try await request(path: "/rest/v1/rpc/\(name)", method: "POST", body: params, authenticated: true)
        return try decoder.decode(R.self, from: data)
    }

    func uploadProgressPhoto(data: Data, storagePath: String, contentType: String = "image/jpeg") async throws {
        guard AppConfiguration.isSupabaseConfigured else { throw SupabaseError.notConfigured }
        guard let baseURL = URL(string: AppConfiguration.supabaseURL) else { throw SupabaseError.invalidURL }
        guard let token = session?.accessToken else { throw SupabaseError.missingSession }

        let base = baseURL.absoluteString.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard let url = URL(string: "\(base)/storage/v1/object/progress-photos/\(storagePath)") else {
            throw SupabaseError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = data
        request.setValue(AppConfiguration.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        request.setValue("false", forHTTPHeaderField: "x-upsert")

        let (_, response) = try await urlSession.data(for: request)
        try validate(response: response, data: Data())
    }

    private func save(_ authSession: SupabaseAuthSession) {
        session = authSession
        if let data = try? encoder.encode(authSession) {
            UserDefaults.standard.set(data, forKey: sessionKey)
        }
    }

    private func authRequest<T: Decodable>(path: String, body: [String: String]) async throws -> T {
        let data = try await request(path: path, method: "POST", body: body, authenticated: false)
        return try decoder.decode(T.self, from: data)
    }

    private func request<T: Encodable>(
        path: String,
        method: String,
        queryItems: [URLQueryItem] = [],
        body: T,
        authenticated: Bool,
        preferRepresentation: Bool = false
    ) async throws -> Data {
        guard AppConfiguration.isSupabaseConfigured else { throw SupabaseError.notConfigured }
        guard let baseURL = URL(string: AppConfiguration.supabaseURL) else { throw SupabaseError.invalidURL }

        let normalizedPath = path.hasPrefix("/") ? String(path.dropFirst()) : path
        let base = baseURL.absoluteString.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        var components = URLComponents(string: "\(base)/\(normalizedPath)")
        if !queryItems.isEmpty {
            let existingQueryItems = components?.queryItems ?? []
            components?.queryItems = existingQueryItems + queryItems
        }
        guard let url = components?.url else { throw SupabaseError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue(AppConfiguration.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if preferRepresentation {
            request.setValue("return=representation", forHTTPHeaderField: "Prefer")
        }

        if authenticated {
            guard let token = session?.accessToken else { throw SupabaseError.missingSession }
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            request.setValue("Bearer \(AppConfiguration.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        }

        if !(body is EmptyBody) && !(body is OptionalBody) {
            request.httpBody = try encoder.encode(body)
        }

        let (data, response) = try await urlSession.data(for: request)
        try validate(response: response, data: data)
        return data
    }

    private func validate(response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else { throw SupabaseError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else {
            if let apiError = try? JSONDecoder().decode(SupabaseAPIError.self, from: data) {
                throw SupabaseError.apiError(apiError.message ?? apiError.msg ?? "Errore Supabase \(http.statusCode)")
            }
            throw SupabaseError.apiError("Errore Supabase \(http.statusCode)")
        }
    }
}

private struct SupabaseAPIError: Decodable {
    let message: String?
    let msg: String?
}

private struct EmptyBody: Encodable {}
private enum OptionalBody: Encodable {
    case none
}
