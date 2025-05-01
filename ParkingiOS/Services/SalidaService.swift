import Foundation

// 1) Modelo que refleja la respuesta JSON
struct TarifaMontoDetalle: Decodable,Identifiable {
    let id: Int
    let placa: String
    let hentrada: Date
    let hsalida: Date
    let monto: Double
}

// 2) Servicio singleton para llamadas a la API
class SalidaService {
    static let shared = SalidaService()
    private init() {}

    /// Consulta la tarifa de salida para una sucursal y placa dadas
    func fetchTarifaMontoDetalle(
        sucursalId: Int,
        placa: String,
        jwt: String,
        completion: @escaping (Result<TarifaMontoDetalle, Error>) -> Void
    ) {
        // 2.1) Construir URL dinámica
        let urlString = "http://186.4.230.233:8081/ParkingClub/tarifaMonto/\(sucursalId)/\(placa)/detalle"
        guard let url = URL(string: urlString) else {
            let err = NSError(domain: "", code: -1,
                              userInfo: [NSLocalizedDescriptionKey: "URL inválida"])
            completion(.failure(err))
            return
        }

        // 2.2) Configurar request con token Bearer
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(jwt)", forHTTPHeaderField: "Authorization")

        // 2.3) Ejecutar la petición
        URLSession.shared.dataTask(with: request) { data, response, error in
            // Error de red
            if let error = error {
                completion(.failure(error))
                return
            }
            // Sin datos
            guard let data = data else {
                let err = NSError(domain: "", code: -1,
                                  userInfo: [NSLocalizedDescriptionKey: "No se recibieron datos"])
                completion(.failure(err))
                return
            }
            do {
                let decoder = JSONDecoder()
                let df = DateFormatter()
                df.locale = Locale(identifier: "en_US_POSIX")
                df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
                decoder.dateDecodingStrategy = .formatted(df)

                // 2.5) Decodificar la respuesta en TarifaMontoDetalle
                let detalle = try decoder.decode(TarifaMontoDetalle.self, from: data)
                completion(.success(detalle))

            } catch {
                print("❌ Error al decodificar TarifaMontoDetalle:", error)
                completion(.failure(error))
            }
        }.resume()
    }
    func procesarSalida(
            ticketId: Int,
            mfinal: Double,
            tpago: String,
            empleadoCierreId: Int,
            jwt: String,
            completion: @escaping (Result<Void, Error>) -> Void
        ) {
            let urlString = "http://186.4.230.233:8081/ParkingClub/tickets/\(ticketId)"
            guard let url = URL(string: urlString) else {
                let err = NSError(domain: "", code: -1,
                                  userInfo: [NSLocalizedDescriptionKey: "URL inválida"])
                completion(.failure(err))
                return
            }

            var request = URLRequest(url: url)
            request.httpMethod = "PUT"  // o "POST" según tu API
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(jwt)", forHTTPHeaderField: "Authorization")

            let body: [String: Any] = [
                "mfinal": mfinal,
                "estado": 1,
                "tpago": tpago,
                "empleadoCierre": ["id": empleadoCierreId]
            ]

            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
            } catch {
                completion(.failure(error))
                return
            }

            URLSession.shared.dataTask(with: request) { _, response, error in
                if let error = error {
                    completion(.failure(error)); return
                }
                guard let http = response as? HTTPURLResponse,
                      200..<300 ~= http.statusCode else {
                    let code = (response as? HTTPURLResponse)?.statusCode ?? -1
                    let err = NSError(domain: "",
                                      code: code,
                                      userInfo: [NSLocalizedDescriptionKey: "HTTP \(code)"])
                    completion(.failure(err)); return
                }
                completion(.success(()))
            }.resume()
        }
}
