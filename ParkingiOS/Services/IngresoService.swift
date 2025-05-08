//
//  IngresoService.swift
//  ParkingiOS
//
//  Created by mac on 5/6/25.
//

import Foundation

class IngresoService {
    static let shared = IngresoService()

    func ingresarTicket(placa: String, empleadoId: Int, jwt: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = URL(string: "http://186.4.230.233:8081/ParkingClub/tickets") else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "URL inválida"])))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(jwt)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "placa": placa,
            "empleado": ["id": empleadoId],
            "estado": 0
        ]
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        } catch {
            completion(.failure(error))
            return
        }

        URLSession.shared.dataTask(with: request) { _, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            if let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) {
                completion(.success(()))
            } else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Error en servidor"])))
            }
        }.resume()
    }
}
