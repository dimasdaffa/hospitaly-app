//
//  APIClient.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//

import Foundation

struct APIClient {
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

    func get<Response: Decodable>(_ path: String, token: String) async throws -> Response {
        let data = try await send(path, method: "GET", token: token)
        return try decode(data)
    }

    func post<Body: Encodable, Response: Decodable>(_ path: String, body: Body) async throws -> Response {
        let data = try await send(path, method: "POST", body: JSONEncoder().encode(body))
        return try decode(data)
    }

    private func send(
        _ path: String, method: String, token: String? = nil, body: Data? = nil
    ) async throws -> Data {
        var request = URLRequest(url: baseURL.appending(path: path))
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
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
        } catch {
            throw APIError.connectionFailed
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw APIError.httpStatus(httpResponse.statusCode)
        }

        return data
    }

    private func decode<Response: Decodable>(_ data: Data) throws -> Response {
        do {
            return try JSONDecoder().decode(Response.self, from: data)
        } catch {
            throw APIError.invalidPayload
        }
    }
}
