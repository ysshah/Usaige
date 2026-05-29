import Foundation
import Security

enum KeychainError: LocalizedError {
    case notFound
    case unexpectedData
    case status(OSStatus)

    var errorDescription: String? {
        switch self {
        case .notFound: return "Keychain item not found"
        case .unexpectedData: return "Keychain item had unexpected data"
        case .status(let s):
            let msg = SecCopyErrorMessageString(s, nil) as String? ?? "OSStatus \(s)"
            return "Keychain error: \(msg)"
        }
    }
}

enum Keychain {
    /// Reads a generic-password item's value as a UTF-8 string.
    /// This is how the Claude Code OAuth credentials blob is stored.
    static func readGenericPassword(service: String) throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status != errSecItemNotFound else { throw KeychainError.notFound }
        guard status == errSecSuccess else { throw KeychainError.status(status) }
        guard let data = item as? Data, let string = String(data: data, encoding: .utf8) else {
            throw KeychainError.unexpectedData
        }
        return string
    }
}
