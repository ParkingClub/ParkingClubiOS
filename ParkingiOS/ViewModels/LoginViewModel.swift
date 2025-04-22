import Foundation
import SwiftUI
import Security

class LoginViewModel: ObservableObject {
    @Published var username: String = ""
    @Published var password: String = ""
    @Published var isLoading: Bool = false
    @Published var showError: Bool = false
    @Published var authResponse: AuthResponse?
    @Published var loginSuccessful: Bool = false
    
    private let userManager = UserManager.shared
    
    func login() {
        isLoading = true
        showError = false
        loginSuccessful = false
        
        AuthService.shared.login(username: username, password: password) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let response):
                    self.authResponse = response
                    // Guardar datos en UserManager
                    self.userManager.setUserData(
                        idEmpleado: response.idEmpleado,
                        nombreEmpleado: response.nombreEmpleado,
                        mac: response.mac,
                        idsucursal: response.idsucursal,
                        idempresa: response.idempresa,
                        role: response.role
                    )
                    self.saveToKeychain(key: "jwt", value: response.jwt)
                    self.loginSuccessful = true
                    print("Login exitoso: \(response)")
                case .failure(let error):
                    self.showError = true
                    self.loginSuccessful = false
                    print("Error en el login: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func saveToKeychain(key: String, value: String) {
        if let data = value.data(using: .utf8) {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: key,
                kSecValueData as String: data
            ]
            
            SecItemDelete(query as CFDictionary)
            let status = SecItemAdd(query as CFDictionary, nil)
            if status != errSecSuccess {
                print("Error al guardar en Keychain: \(status)")
            }
        }
    }
    
    func getJWT() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "jwt",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecSuccess, let data = item as? Data, let value = String(data: data, encoding: .utf8) {
            return value
        }
        return nil
    }
}
