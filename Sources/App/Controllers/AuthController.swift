import Fluent
import Vapor

struct AuthController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let auth = routes.grouped("auth")
        
        let protected = auth.grouped([
            User.credentialsAuthenticator(),
            User.redirectMiddleware(path: "/login?error=true")
        ])
        
        protected.post("login", use: login)
        auth.post("signup", use: signup)
    }

    
    func login(req: Request) async throws -> Response {
        try req.auth.require(User.self)
        return req.redirect(to: "/app/home")
    }

    
    func signup(req: Request) async throws -> Response {
        try User.Create.validate(content: req)
        let create = try req.content.decode(User.Create.self)
        guard create.password == create.confirmPassword else {
            return req.redirect(to: "/signup?error=true")
        }
        
        let user = try User(
            username: create.username,
            passwordHash: Bcrypt.hash(create.password)
        )
        
        try await user.save(on: req.db)
        return req.redirect(to: "/login?success=true")
    }


}
