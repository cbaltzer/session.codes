import Fluent
import FluentPostgresDriver
import Leaf
import Vapor

// configures your application
public func configure(_ app: Application) throws {
    // uncomment to serve files from /Public folder
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    
    app.sessions.use(.memory)
    app.sessions.configuration.cookieName = "session_codes"
    
    app.middleware.use(app.sessions.middleware)
    app.middleware.use(User.sessionAuthenticator())
    

    
    guard let dbString = Environment.get("DATABASE_URL"), var postgresConfig = PostgresConfiguration(url: dbString) else {
        fatalError("No database string")
    }
    
    
    postgresConfig.tlsConfiguration = .makeClientConfiguration()
    postgresConfig.tlsConfiguration?.certificateVerification = .fullVerification
    
    
    app.databases.use(.postgres(configuration: postgresConfig), as: .psql)

    
    // Setup migrations
    app.migrations.add(User.Migration())
    app.migrations.add(Room.Migration())
    
    
    app.views.use(.leaf)
    

    // register routes
    try routes(app)
}
