import Foundation

class ControlViewModel: ObservableObject {
    @Published var tickets: [Ticket] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let controlService = ControlService.shared
    private let userManager = UserManager.shared
    private let printerManager = BluetoothPrinterManager.shared
    
    //private let printerSDK = PrinterSDKManager.shared
    
    private var printerSDK: PrinterSDKManager {
            PrinterSDKManager.shared
    }
    
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
//    func printTicket(_ ticket: Ticket) {
//      guard let sucName = userManager.nombreEmpleado else { return }
//      printerSDK.printTicket(
//        placa:     ticket.placa,
//        fecha:     formatDate(ticket.hentrada),
//        hora:      formatTime(ticket.hentrada),
//        ubicacion: "San Carlos",
//        sucName:   sucName
//      )
//    }
    func printTicket(_ ticket: Ticket) {
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

      // 1) Consumimos API de sucursal
      controlService.fetchSucursal(sucursalId: sucursalId, jwt: jwt) { result in
        DispatchQueue.main.async {
          self.isLoading = false

          switch result {
          case .failure(let error):
            self.errorMessage = "No se pudo obtener sucursal: \(error.localizedDescription)"
          case .success(let sucursal):
            // 2) Formateamos y enviamos a la impresora
            let placa   = ticket.placa
            let fecha   = self.formatDate(ticket.hentrada)
            let hora    = self.formatTime(ticket.hentrada)
            let nombre  = sucursal.nombre
            let ubic    = sucursal.ubicacion

            self.printerSDK.printTicket(
              placa:     placa,
              fecha:     fecha,
              hora:      hora,
              ubicacion: ubic,
              sucName: nombre
            )
          }
        }
      }
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

