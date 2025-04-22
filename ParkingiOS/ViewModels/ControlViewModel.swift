import Foundation

class ControlViewModel: ObservableObject {
    @Published var tickets: [Ticket] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let controlService = ControlService.shared
    private let userManager = UserManager.shared
    
    func fetchTickets() {
        guard let jwt = LoginViewModel().getJWT() else {
            errorMessage = "No se encontró el token de autenticación"
            return
        }
        
        guard let sucursalId = userManager.idsucursal else {
            errorMessage = "No se encontró el ID de sucursal"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        controlService.fetchTickets(estado: 0, sucursalId: sucursalId, jwt: jwt) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let tickets):
                    self.tickets = tickets
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = formatter.date(from: dateString) {
            let outputFormatter = DateFormatter()
            outputFormatter.dateFormat = "dd/MM/yyyy HH:mm"
            return outputFormatter.string(from: date)
        }
        return dateString
    }
}
