//
//  File.swift
//  
//
//  Created by Роман Мисников on 08.11.2020.
//

import Foundation
import Vapor

// MARK: - ConnectedUser
struct ConnectedUser {
    let id: String
    let name: String
    let webSocket: WebSocket
}

extension ConnectedUser: Hashable {
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: ConnectedUser, rhs: ConnectedUser) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - User
struct User: Codable {
    let id: String
    let name: String
}

// MARK: - Message
struct Message: Codable {
    let id: String
    let senderId: String
    let receiverId: String
    let text: String
}
