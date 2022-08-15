import Fluent
import Vapor

func routes(_ app: Application) throws {

    
    app.get { req async throws in
        try await req.view.render("index", ["pageTitle": "session.codes"])
    }

    
    app.get("login") { req async throws in
        try await req.view.render("login", ["pageTitle": "Login : session.codes"])
    }
    
    app.get("signup") { req async throws in
        try await req.view.render("signup", ["pageTitle": "Sign Up : session.codes"])
    }
    
 
    
    
    try app.register(collection: AuthController())
    try app.register(collection: RoomController())
}
