import Foundation

class ControlService {
    
    struct Sucursal: Decodable {
        let nombre: String
        let ubicacion: String
    }

    
    static let shared = ControlService()
    
    func fetchTickets(estado: Int,
                      sucursalId: Int,
                      jwt: String,
                      completion: @escaping (Result<[Ticket], Error>) -> Void) {
        
        let urlString = "http://186.4.230.233:8081/ParkingClub/tickets/estado/\(estado)/sucursal/\(sucursalId)"
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "",
                                        code: -1,
                                        userInfo: [NSLocalizedDescriptionKey: "URL inválida"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(jwt)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "",
                                            code: -1,
                                            userInfo: [NSLocalizedDescriptionKey: "No se recibieron datos"])))
                return
            }
            
            do {
                // 1) Configurar JSONDecoder con un DateFormatter que acepte fracciones
                let decoder = JSONDecoder()
                let df = DateFormatter()
                df.locale = Locale(identifier: "en_US_POSIX")
                df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
                decoder.dateDecodingStrategy = .formatted(df)
                
                // 2) Decodificar el arreglo de Tickets
                let tickets = try decoder.decode([Ticket].self, from: data)
                completion(.success(tickets))
                
            } catch {
                // Si falla, imprime el error para depuración
                print("❌ Error al decodificar Tickets:", error)
                completion(.failure(error))
            }
        }.resume()
    }
    
    
    func fetchSucursal(sucursalId: Int,
                         jwt: String,
                         completion: @escaping (Result<Sucursal, Error>) -> Void) {
        let urlString = "http://186.4.230.233:8081/ParkingClub/sucursal/\(sucursalId)"
        guard let url = URL(string: urlString) else {
          completion(.failure(NSError(domain: "", code: -1,
            userInfo: [NSLocalizedDescriptionKey: "URL inválida para sucursal"])))
          return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(jwt)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, response, error in
          if let error = error {
            completion(.failure(error)); return
          }
          guard let data = data else {
            completion(.failure(NSError(domain: "", code: -1,
              userInfo: [NSLocalizedDescriptionKey: "No se recibieron datos de sucursal"])))
            return
          }
          do {
            let decoder = JSONDecoder()
            let sucursal = try decoder.decode(Sucursal.self, from: data)
            completion(.success(sucursal))
          } catch {
            print("❌ Error decodificando Sucursal:", error)
            completion(.failure(error))
          }
        }.resume()
      }
}
