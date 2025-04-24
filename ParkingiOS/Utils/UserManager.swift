import Foundation

class UserManager: ObservableObject {
    static let shared = UserManager()
    
    @Published private var userData: [String: Any] = UserDefaults.standard.dictionary(forKey: "userData") as? [String: Any] ?? [:]
    
    var nombreEmpleado: String? {
        return userData["nombreEmpleado"] as? String
    }
    
    var role: String? {
        return userData["role"] as? String
    }
    
    var mac: String? {
        return userData["mac"] as? String
    }
    
    var idsucursal: Int? {
        return userData["idsucursal"] as? Int
    }
    
    func setUserData(idEmpleado: Int, nombreEmpleado: String, mac: String, idsucursal: Int, idempresa: Int, role: String) {
        userData = [
            "idEmpleado": idEmpleado,
            "nombreEmpleado": nombreEmpleado,
            "mac": mac,
            "idsucursal": idsucursal,
            "idempresa": idempresa,
            "role": role
        ]
        UserDefaults.standard.set(userData, forKey: "userData")
        objectWillChange.send() // Notificar cambios
    }
    
    func clearUserData() {
        userData = [:]
        UserDefaults.standard.removeObject(forKey: "userData")
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "jwt"
        ]
        SecItemDelete(query as CFDictionary)
        
        objectWillChange.send() // Notificar cambios
    }
}
