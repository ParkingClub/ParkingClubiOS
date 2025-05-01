import Foundation

class UserManager: ObservableObject {
    static let shared = UserManager()
    
    @Published private var userData: [String: Any] =
        UserDefaults.standard.dictionary(forKey: "userData") as? [String: Any] ?? [:]
    
    // ————————————— Propiedades existentes —————————————
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
    
    // ←– AÑADE ESTAS DOS:
        /// El ID del empleado (se guardó en setUserData)
        var idEmpleado: Int? { userData["idEmpleado"] as? Int }
        /// El ID de la empresa (opcional)
        var idempresa:  Int? { userData["idempresa"]  as? Int }

    // ————————————— NUEVO: UUID de la impresora BLE —————————————
    /// UUID persistente del periférico BLE que usas para imprimir
    var printerUUID: String? {
        get { return userData["printerUUID"] as? String }
        set {
            userData["printerUUID"] = newValue
            UserDefaults.standard.set(userData, forKey: "userData")
            objectWillChange.send()
        }
    }
    
    // ————————————— Configuración de usuario —————————————
    func setUserData(idEmpleado: Int,
                     nombreEmpleado: String,
                     mac: String,
                     idsucursal: Int,
                     idempresa: Int,
                     role: String) {
        userData = [
            "idEmpleado": idEmpleado,
            "nombreEmpleado": nombreEmpleado,
            "mac": mac,
            "idsucursal": idsucursal,
            "idempresa": idempresa,
            "role": role
            // no tocamos printerUUID aquí, así no se borra
        ]
        UserDefaults.standard.set(userData, forKey: "userData")
        objectWillChange.send()
    }
    
    // ————————————— Limpiar todo (incluye printerUUID) —————————————
    func clearUserData() {
        userData = [:]
        UserDefaults.standard.removeObject(forKey: "userData")
        // limpia también la clave en Keychain
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "jwt"
        ]
        SecItemDelete(query as CFDictionary)
        objectWillChange.send()
    }
}
