import Foundation

// ─── 1) Modelo para cada registro ─────────────────────
struct TicketRecord: Identifiable, Decodable {
    let id: Int
    let placa: String
    let hentrada: Date
    let hsalida: Date
    let monto: Double
    let tipoPago: String
    let empleadoCierre: String

    enum CodingKeys: String, CodingKey {
        case id, placa, hentrada, hsalida, monto
        case tipoPago       = "tipo_pago"
        case empleadoCierre = "empleado_cierre"
    }
    
    init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            id             = try c.decode(Int.self,         forKey: .id)
            placa          = try c.decode(String.self,      forKey: .placa)
            hentrada       = try c.decode(Date.self,        forKey: .hentrada)
            hsalida        = try c.decode(Date.self,        forKey: .hsalida)
            monto          = try c.decode(Double.self,      forKey: .monto)
            // Si tipo_pago viene null o no existe, lo tomamos como "E"
            tipoPago       = try c.decodeIfPresent(String.self, forKey: .tipoPago) ?? "E"
            // Para empleado_cierre también podrías default a "" o "N/A"
            empleadoCierre = try c.decodeIfPresent(String.self, forKey: .empleadoCierre) ?? ""
        }

}

// ─── 2) Servicio para cargar los tickets ──────────────
//class RecaudacionesService {
//    static let shared = RecaudacionesService()
//    private init() {}
//
//    func fetchTickets(
//        estado: Int,
//        sucursalId: Int,
//        jwt: String,
//        completion: @escaping (Result<[TicketRecord], Error>) -> Void
//    ) {
//        // ← Aquí cambiamos a tu endpoint verdadero:
//        let urlString = "http://186.4.230.233:8081/ParkingClub/tickets/estado_pago/\(estado)/sucursal/\(sucursalId)"
//        guard let url = URL(string: urlString) else {
//            completion(.failure(NSError(
//                domain: "", code: -1,
//                userInfo: [NSLocalizedDescriptionKey: "URL inválida"])))
//            return
//        }
//
//        var req = URLRequest(url: url)
//        req.httpMethod = "GET"
//        req.setValue("Bearer \(jwt)", forHTTPHeaderField: "Authorization")
//
//        URLSession.shared.dataTask(with: req) { data, _, error in
//            if let error = error {
//                completion(.failure(error)); return
//            }
//            guard let data = data, !data.isEmpty else {
//                completion(.failure(NSError(
//                    domain: "", code: -1,
//                    userInfo: [NSLocalizedDescriptionKey: "Sin datos"])))
//                return
//            }
//
//            let decoder = JSONDecoder()
//            let df = DateFormatter()
//            df.locale     = Locale(identifier: "en_US_POSIX")
//            df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
//            decoder.dateDecodingStrategy = .formatted(df)
//
//            do {
//                let tickets = try decoder.decode([TicketRecord].self, from: data)
//                completion(.success(tickets))
//            } catch {
//                #if DEBUG
//                print("🔴 JSON Recaudaciones:", String(data: data, encoding: .utf8) ?? "")
//                print("🔴 Error decodificando:", error)
//                #endif
//                completion(.failure(error))
//            }
//        }.resume()
//    }
//}
class RecaudacionesService {
    static let shared = RecaudacionesService()
    private init() {}

    func fetchTickets(
        estado: Int,
        sucursalId: Int,
        periodo: String,      // <-- nuevo parámetro
        jwt: String,
        completion: @escaping (Result<[TicketRecord], Error>) -> Void
    ) {
        let urlString = "http://186.4.230.233:8081/ParkingClub/tickets/estado/\(estado)/sucursal/\(sucursalId)/periodo/\(periodo)"
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(
                domain: "", code: -1,
                userInfo: [NSLocalizedDescriptionKey: "URL inválida"])))
            return
        }

        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.setValue("Bearer \(jwt)", forHTTPHeaderField: "Authorization")

        // ... resto idéntico (JSONDecoder, date formatter, etc.)
        URLSession.shared.dataTask(with: req) { data, _, error in
            if let error = error {
                completion(.failure(error)); return
            }
            guard let data = data, !data.isEmpty else {
                completion(.failure(NSError(
                    domain: "", code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Sin datos"])))
                return
            }

            let decoder = JSONDecoder()
            let df = DateFormatter()
            df.locale     = Locale(identifier: "en_US_POSIX")
            df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
            decoder.dateDecodingStrategy = .formatted(df)

            do {
                let tickets = try decoder.decode([TicketRecord].self, from: data)
                completion(.success(tickets))
            } catch {
                #if DEBUG
                print("🔴 JSON Recaudaciones:", String(data: data, encoding: .utf8) ?? "")
                print("🔴 Error decodificando:", error)
                #endif
                completion(.failure(error))
            }
        }.resume()
    }
}
