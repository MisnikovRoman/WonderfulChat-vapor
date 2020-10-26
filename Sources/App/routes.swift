import Vapor

struct Chat: Content {
    let id: String
}

func routes(_ app: Application) throws {
    app.get { req in
        return "It works!"
    }

    app.get("chat") { req -> Chat in
        return Chat(id: "\(Int.random(in: 0...1000))")
    }

    app.webSocket("roman") { request, socket in
        socket.onText { socket, text in
            print("💬", text)
            socket.send("🤖 Server response: \(String(text.reversed()))")
        }
    }
}
