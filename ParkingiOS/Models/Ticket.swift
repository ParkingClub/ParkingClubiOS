//
//  Ticket.swift
//  ParkingiOS
//
//  Created by mac on 4/17/25.
//

import Foundation

struct Ticket: Codable, Identifiable {
    let id: Int
    let placa: String
    let hentrada: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case placa
        case hentrada
    }
}
