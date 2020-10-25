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
}
