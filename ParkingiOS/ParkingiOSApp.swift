import SwiftUI

@main
struct ParkingiOSApp: App {
    @StateObject private var userManager = UserManager.shared      // único modelo
    
    init() {
            // Solo para desarrollo: forzar logout al lanzar la app
            userManager.clearUserData()
        }

    var body: some Scene {
        WindowGroup {
            Group {
                // Si hay nombreEmpleado ≠ nil  ⇒  usuario autenticado
                if userManager.nombreEmpleado != nil {
                    MenuView()
                } else {
                    LoginView()
                }
            }
            .environmentObject(userManager)     // inyecta el mismo modelo a toda la jerarquía
        }
    }
}
