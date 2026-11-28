//
//  APIClient.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//

import Foundation

struct APIClient: Sendable {
    private let baseURL: URL
    private let session: URLSession

    init(baseURL: URL) {
        self.baseURL = baseURL

        let configuration = URLSessionConfiguration.ephemeral
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.urlCache = nil
        configuration.timeoutIntervalForRequest = 15
        configuration.timeoutIntervalForResource = 25
        session = URLSession(configuration: configuration)
    }

    func checkConnection() async throws {
        _ = try await send("health", method: "GET")
    }

    func publicImageURL(_ path: String) -> URL? {
        guard let url = URL(string: path, relativeTo: baseURL)?.absoluteURL,
              url.host != nil, url.user == nil, url.password == nil else { return nil }

        if url.scheme == "https" { return url }
        let isLocalAPI = url.scheme == "http" && baseURL.scheme == "http"
            && url.host == baseURL.host && url.port == baseURL.port
        return isLocalAPI ? url : nil
    }

    func get<Response: Decodable>(
        _ path: String, token: String, query: [URLQueryItem] = []
    ) async throws -> Response {
        let data = try await send(path, method: "GET", token: token, query: query)
        return try decode(data)
    }

    func getFile(_ file: PrivateDocumentDownload, token: String) async throws -> Data {
        try await send(file.source.path, method: "GET", token: token, mediaType: file.mediaType)
    }

    func sendMultipart<Response: Decodable>(
        _ path: String, method: String, body: Data, boundary: String, token: String
    ) async throws -> Response {
        let data = try await send(
            path, method: method, token: token, body: body,
            contentType: "multipart/form-data; boundary=\(boundary)"
        )
        return try decode(data)
    }

    func post<Body: Encodable, Response: Decodable>(
        _ path: String, body: Body, token: String? = nil, idempotencyKey: UUID? = nil
    ) async throws -> Response {
        let data = try await send(
            path, method: "POST", token: token, body: JSONEncoder().encode(body), idempotencyKey: idempotencyKey
        )
        return try decode(data)
    }

    func patch<Body: Encodable, Response: Decodable>(
        _ path: String, body: Body, token: String
    ) async throws -> Response {
        let data = try await send(path, method: "PATCH", token: token, body: JSONEncoder().encode(body))
        return try decode(data)
    }

    func put(_ path: String, token: String) async throws {
        _ = try await send(path, method: "PUT", token: token)
    }

    func delete(_ path: String, token: String) async throws {
        _ = try await send(path, method: "DELETE", token: token)
    }

    func put<Body: Encodable, Response: Decodable>(
        _ path: String, body: Body, token: String
    ) async throws -> Response {
        let data = try await send(path, method: "PUT", token: token, body: JSONEncoder().encode(body))
        return try decode(data)
    }

    private func send(
        _ path: String, method: String, token: String? = nil, body: Data? = nil,
        query: [URLQueryItem] = [], idempotencyKey: UUID? = nil,
        mediaType: String? = nil, contentType: String = "application/json"
    ) async throws -> Data {
        let url = baseURL.appending(path: path)
        var request = URLRequest(url: query.isEmpty ? url : url.appending(queryItems: query))
        request.httpMethod = method
        request.setValue(mediaType ?? "application/json", forHTTPHeaderField: "Accept")

        if let token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let idempotencyKey {
            request.setValue(idempotencyKey.uuidString, forHTTPHeaderField: "Idempotency-Key")
        }

        if let body {
            request.setValue(contentType, forHTTPHeaderField: "Content-Type")
            request.httpBody = body
        }

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: request)
        } catch is CancellationError {
            throw CancellationError()
        } catch let error as URLError where error.code == .cancelled {
            throw CancellationError()
        } catch let error as URLError where error.code == .notConnectedToInternet {
            throw APIError.offline
        } catch let error as URLError where error.code == .timedOut {
            throw APIError.timedOut
        } catch {
            throw APIError.connectionFailed
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw APIError.httpStatus(httpResponse.statusCode)
        }

        if let mediaType {
            guard httpResponse.mimeType?.caseInsensitiveCompare(mediaType) == .orderedSame,
                  !data.isEmpty else { throw APIError.invalidPayload }
        }

        return data
    }

    private func decode<Response: Decodable>(_ data: Data) throws -> Response {
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(Response.self, from: data)
        } catch {
            throw APIError.invalidPayload
        }
    }
}
