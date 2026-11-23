//
//  TokenStore.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 23/11/26.
//

import Foundation
import Security

struct TokenStore {
    let account: String

    private let service = "com.dimasdaffa.Hospitaly.session"

    private var lookup: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }

    func read() throws -> String? {
        var query = lookup
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecItemNotFound {
            return nil
        }

        guard status == errSecSuccess else { throw TokenStoreError.unavailable }
        guard let data = result as? Data,
              let token = String(data: data, encoding: .utf8), !token.isEmpty else {
            throw TokenStoreError.invalidToken
        }

        return token
    }

    func save(_ token: String) throws {
        let attributes: [String: Any] = [
            kSecValueData as String: Data(token.utf8),
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        let status = SecItemUpdate(lookup as CFDictionary, attributes as CFDictionary)

        if status == errSecItemNotFound {
            let item = lookup.merging(attributes) { _, newValue in newValue }
            guard SecItemAdd(item as CFDictionary, nil) == errSecSuccess else {
                throw TokenStoreError.unavailable
            }
        } else if status != errSecSuccess {
            throw TokenStoreError.unavailable
        }
    }

    func remove() throws {
        let status = SecItemDelete(lookup as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw TokenStoreError.unavailable
        }
    }
}
