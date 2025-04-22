//
//  AuthResponse.swift
//  ParkingiOS
//
//  Created by mac on 4/16/25.
//

import Foundation

struct AuthResponse: Codable {
    let jwt: String
    let idEmpleado: Int
    let nombreEmpleado: String
    let mac: String
    let idsucursal: Int
    let idempresa: Int
    let role: String
}
