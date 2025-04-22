//
//  AuthService.swift
//  ParkingiOS
//
//  Created by mac on 4/16/25.
//

import Foundation

class AuthService {
    static let shared = AuthService() // Singleton para acceder al servicio desde cualquier parte
    
    func login(username: String, password: String, completion: @escaping (Result<AuthResponse, Error>) -> Void) {
        // URL de la API
        guard let url = URL(string: "http://186.4.230.233:8081/ParkingClub/auth/authenticate") else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "URL inválida"])))
            return
        }
        
        // Configurar la solicitud POST
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Crear el cuerpo de la solicitud con los datos
        let loginData = ["username": username, "password": password]
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: loginData, options: [])
        } catch {
            completion(.failure(error))
            return
        }
        
        // Realizar la solicitud
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No se recibió datos"])))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let authResponse = try decoder.decode(AuthResponse.self, from: data)
                completion(.success(authResponse))
            } catch {
                completion(.failure(error))
            }
        }
        task.resume()
    }
}
