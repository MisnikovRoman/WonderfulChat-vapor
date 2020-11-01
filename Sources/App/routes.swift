import Vapor

struct Chat: Content {
    let id: String
}


func routes(_ app: Application) throws {
    let chatController = ChatController()

    app.get { _ in return "It works!" }
    app.webSocket("chat", onUpgrade: chatController.createChat)
}
