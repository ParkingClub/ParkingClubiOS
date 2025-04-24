import Foundation

class ControlViewModel: ObservableObject {
    @Published var tickets: [Ticket] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let controlService = ControlService.shared
    private let userManager = UserManager.shared
    
    private let printerManager = BluetoothPrinterManager.shared
    
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
    
//    nuevas funciones para intentar imprimir
    func printTicket(_ ticket: Ticket) {
            guard let mac = userManager.mac,
                  let sucName = userManager.nombreEmpleado else {
                print("❌ Faltan datos de impresora o sucursal")
                return
            }
            
            // Formatear fecha y hora
            let fechaTxt = formatDate(ticket.hentrada)     // ej. "22/04/2025"
            let horaTxt  = formatTime(ticket.hentrada)     // ej. "14:30"
            let ubicacion = "San carlos"                // si tu modelo lo trae
            
            let data = buildPrintData(macAddress: mac,
                                      placa: ticket.placa,
                                      fecha: fechaTxt,
                                      hora: horaTxt,
                                      ubicacion: ubicacion,
                                      sucName: sucName)
            
            printerManager.send(data: data)
        }
        
        private func buildPrintData(macAddress: String,
                                    placa: String,
                                    fecha: String,
                                    hora: String,
                                    ubicacion: String,
                                    sucName: String) -> Data {
            var d = Data()
            // Ejemplo de comandos ESC/POS
            d.append(contentsOf: [0x1B, 0x45, 0x01])            // negrilla ON
            d.append(contentsOf: [0x1D, 0x21, 0x10])            // tamaño grande
            d.append(contentsOf: [0x1B, 0x61, 0x01])            // centrar
            d.append(sucName.data(using: .utf8)!)
            d.append(contentsOf: [0x1B, 0x64, 0x01])            // salto
            // … continúa armando tu ticket igual que en Android …
            d.append("Placa: \(placa)\n".data(using: .utf8)!)
            d.append("Fecha: \(fecha)\n".data(using: .utf8)!)
            d.append("Hora: \(hora)\n".data(using: .utf8)!)
            // etc.
            d.append(contentsOf: [0x1B, 0x64, 0x03])            // saltos finales
            return d
        }
        
         func formatDate(_ date: Date) -> String {
            let df = DateFormatter()
            df.dateFormat = "dd/MM/yyyy"
            return df.string(from: date)
        }
         func formatTime(_ date: Date) -> String {
            let df = DateFormatter()
            df.dateFormat = "HH:mm"
            return df.string(from: date)
        }
    }

