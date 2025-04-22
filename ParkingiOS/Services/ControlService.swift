import Foundation

class ControlService {
    static let shared = ControlService()
    
    func fetchTickets(estado: Int, sucursalId: Int, jwt: String, completion: @escaping (Result<[Ticket], Error>) -> Void) {
        let urlString = "http://186.4.230.233:8081/ParkingClub/tickets/estado/\(estado)/sucursal/\(sucursalId)"
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "URL inválida"])))
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
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No se recibieron datos"])))
                return
            }
            
            do {
                let tickets = try JSONDecoder().decode([Ticket].self, from: data)
                completion(.success(tickets))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}
