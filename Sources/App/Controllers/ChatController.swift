//
//  File.swift
//  
//
//  Created by Роман Мисников on 01.11.2020.
//

import Vapor

class ChatController {
    
    private var users = Set<ConnectedUser>()

    func createChat(_ request: Request, socket: WebSocket) {
        
        users.removeAll { $0.webSocket.isClosed }
        
        guard let newUser = parseUser(request: request, webSocket: socket) else { return }
        onCreateConnection(newUser: newUser)
        
        socket.onText { [weak self] socket, text in
            print("💬", text)
            if let message = text.toModel(Message.self) {
                // resend message
                let sender = self?.users.first { $0.id == message.senderId}
                let receiver = self?.users.first { $0.id != message.senderId } // ⚠️ Отправка случайному пользователю
                receiver?.webSocket.send(text)
                print("↔️ Send from \"\(sender?.name ?? "")\" to \"\(receiver?.name ?? "")\" message \"\(message.text)\"")
            }
        }
        
        _ = socket.onClose.whenComplete { [weak self] _ in
            print("👣 User closed session \(request.headers["name"].first)")
            self?.notifyActiveUsers()
        }
    }
}

private extension ChatController {
    
    func parseUser(request: Request, webSocket: WebSocket) -> ConnectedUser? {
        guard let id = request.headers["id"].first,
              let name = request.headers["name"].first else { return nil }
        return ConnectedUser(id: id, name: name, webSocket: webSocket)
    }
    
    func onCreateConnection(newUser: ConnectedUser) {
        print("👋🏻 New user connected: \(newUser.name)")
        users.insert(newUser)
        notifyActiveUsers()
    }
    
    func notifyActiveUsers() {
        users.removeAll { $0.webSocket.isClosed }
        
        print("👨‍👩‍👦‍👦 Connected users: \(users.map { $0.name })")
        
        users.forEach { user in
            let activeUsersExceptSelf = users
                .filter { !$0.webSocket.isClosed }
                .filter { $0.id != user.id }
                .map { User(id: $0.id, name: $0.name) }
                .toJsonString()
            user.webSocket.send(activeUsersExceptSelf)
        }
    }
}

private extension Set {
    mutating func removeAll(where condition: (Element) -> Bool) {
        forEach {
            if condition($0) {
                self.remove($0)
            }
        }
    }
}

// MARK: - Decoding
private extension String {
    func toModel<T: Decodable>(_ type: T.Type) -> T? {
        let data = Data(self.utf8)
        let model = try? JSONDecoder().decode(T.self, from: data)
        return model
    }
}

private extension Encodable {
    func toJsonString() -> String {
        guard let data = try? JSONEncoder().encode(self),
              let json = String(data: data, encoding: .utf8)
        else {
            assertionFailure("Невозможно декодировать данные")
            return ""
        }
        return json
    }
}
