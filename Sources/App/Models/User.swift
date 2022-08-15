import Fluent
import Vapor


final class User: Model, Content {
    static let schema = "users"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "username")
    var username: String

    @Field(key: "password_hash")
    var passwordHash: String

    @Children(for: \.$owner)
    var rooms: [Room]
    
    
    init() { }

    init(id: UUID? = nil, username: String, passwordHash: String) {
        self.id = id
        self.username = username
        self.passwordHash = passwordHash
    }
}

extension User: SessionAuthenticatable {
    typealias SessionID = UUID
    var sessionID: SessionID {
        return self.id ?? UUID()
    }
}

extension User: ModelSessionAuthenticatable { }

struct UserSessionAuthenticator: AsyncSessionAuthenticator {
    typealias User = App.User
    func authenticate(sessionID: UUID, for request: Request) async throws {
        
        guard let user = try await User.find(sessionID, on: request.db) else {
            throw Abort(.notFound)
        }
        
        request.auth.login(user)
    }
}

extension User: ModelCredentialsAuthenticatable {
    static let usernameKey = \User.$username
    static let passwordHashKey = \User.$passwordHash

    func verify(password: String) throws -> Bool {
        try Bcrypt.verify(password, created: self.passwordHash)
    }
}


extension User {
    struct Create: Content {
        var username: String
        var password: String
        var confirmPassword: String
    }
}

extension User.Create: Validatable {
    static func validations(_ validations: inout Validations) {
        validations.add("username", as: String.self, is: .count(3...))
        validations.add("password", as: String.self, is: .count(8...))
    }
}
