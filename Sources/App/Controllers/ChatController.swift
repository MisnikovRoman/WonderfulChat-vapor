//
//  File.swift
//  
//
//  Created by Роман Мисников on 01.11.2020.
//

import Vapor

struct User {
    let id: String
    let name: String
    let webSocket: WebSocket
}

class ChatController {
    
    private var users: [User] = []

    func createChat(_ request: Request, socket: WebSocket) {
        
        users.removeAll { $0.webSocket.isClosed }
        onCreateConnection(request: request, socket: socket)

        socket.onText { socket, text in
            print("💬", text)
        }
        
        _ = socket.onClose.always { [weak self] _ in
            self?.notifyActiveUsers()
        }
    }
}

private extension ChatController {
    func onCreateConnection(request: Request, socket: WebSocket) {
        guard let id = request.headers["id"].first,
              let name = request.headers["name"].first else { return }
        let newUser = User(id: id, name: name, webSocket: socket)
        users.append(newUser)
        
        notifyActiveUsers()
    }
    
    func notifyActiveUsers() {
        users.forEach { user in
            let names = users
                .filter { !$0.webSocket.isClosed }
                .filter { $0.id != user.id }
                .map { $0.name }
                .joined(separator: ", ")
            user.webSocket.send("\(names)")
        }
    }
}
