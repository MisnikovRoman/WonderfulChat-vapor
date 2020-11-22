//
//  File.swift
//  
//
//  Created by Роман Мисников on 01.11.2020.
//

import Vapor

class ChatController {
    
    // Echo bot which replays with same message to sender
    private let isEchoBotActive = true
    private let echoBot = User(id: "echo_bot_0", name: "🤖 Echo Bot")
    
    private var users = Set<ConnectedUser>()

    func createChat(_ request: Request, socket: WebSocket) {
        
        users.removeAll { $0.webSocket.isClosed }
        
        guard let newUser = parseUser(request: request, webSocket: socket) else { return }
        onCreateConnection(newUser: newUser)
        
        socket.onText { [weak self] socket, text in
            guard let self = self else { return }
            print("💬 Incoming text message:", text)
            
            if let message = text.toModel(Message.self) {
                if self.isEchoBotActive, message.receiverId == self.echoBot.id {
                    self.replyAsEchoBot(to: message.senderId, with: message.text)
                } else {
                    self.resendToReceiver(message)
                }
            }
        }
        
        socket.onClose.whenComplete { [weak self] _ in
            self?.users.removeAll { $0.id == request.headers["id"].first }
            print("👣 User closed session \(request.headers["name"].first ?? "")")
            self?.notifyActiveUsers()
        }
    }
}


// MARK: - Private
private extension ChatController {
    
    func parseUser(request: Request, webSocket: WebSocket) -> ConnectedUser? {
        guard let id = request.headers["id"].first,
              let name = request.headers["name"].first else { return nil }
        return ConnectedUser(id: id, name: name, webSocket: webSocket)
    }
    
    func onCreateConnection(newUser: ConnectedUser) {
        print("👋🏻 New user connected: \(newUser.name)")
        
        users
            .filter { $0.id == newUser.id }
            .forEach { $0.webSocket.close(code: .init(codeNumber: 4001)) } // дублирующийся пользователь
        
        users.insert(newUser)
        notifyActiveUsers()
    }
    
    // отправка всем активным пользователям обновленного списка активных пользователей
    func notifyActiveUsers() {
        users.removeAll { $0.webSocket.isClosed }
        
        print("👨‍👩‍👦‍👦 Connected users: \(users.map { $0.name })")
        
        users.forEach { user in
            var activeUsersExceptSelf = users
                .filter { !$0.webSocket.isClosed }
                .filter { $0.id != user.id }
                .map { User(id: $0.id, name: $0.name) }
            
            // add echo bot to list of active users
            isEchoBotActive ? activeUsersExceptSelf.append(echoBot) : ()
            
            user.webSocket.send(activeUsersExceptSelf.toJsonString())
        }
    }
    
    // пересылка сообщения от отправителя получателю
    func resendToReceiver(_ message: Message) {
        let sender = users.first { $0.id == message.senderId }
        let receiver = users.first { $0.id != message.senderId }
        
        receiver?.webSocket.send(message.toJsonString())
        
        print("↔️ Send from \"\(sender?.name ?? "")\" to \"\(receiver?.name ?? "")\" message \"\(message.text)\"")
    }
    
    func replyAsEchoBot(to userId: String, with message: String) {
        guard let user = users.first(where: { $0.id == userId }) else { return }
        let encodedMessage = Message(id: UUID().uuidString, senderId: echoBot.id, receiverId: user.id, text: message).toJsonString()
        user.webSocket.send(encodedMessage)
        print("🤖 Echoed to \"\(userId)\" with \"\(message)\"")
    }
}

// MARK: - Set extension
private extension Set {
    mutating func removeAll(where condition: (Element) -> Bool) {
        forEach {
            if condition($0) && self.contains($0) {
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

