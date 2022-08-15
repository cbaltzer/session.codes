//
//  SOGSAPI.swift
//  
//
//  Created by Christopher Baltzer on 2022-08-14.
//

import Foundation
import Vapor

struct SOGS {
    
    struct API {
        static let base = Environment.get("SOGS_API_ENDPOINT") ?? "https://session.codes"
        static let apiKey = Environment.get("SOGS_API_KEY") ?? "7467415d8424434fa367a252b912dc62"
        
        func getRequest(endpoint: String) -> URLRequest {
            let upstream = URL(string: "\(SOGS.API.base)\(endpoint)")!
            var upstreamReq = URLRequest(url: upstream)
            upstreamReq.addValue("Bearer \(SOGS.API.apiKey)", forHTTPHeaderField: "Authorization")
            
            return upstreamReq
        }
        
        func getRoom(token: String) async throws -> SOGSRoom {
            let roomReq = SOGS.API().getRequest(endpoint: "/room/\(token)")
            let (data, _) = try await URLSession.shared.data(for: roomReq)
            
            let room: SOGSRoom = try! JSONDecoder().decode(SOGSRoom.self, from: data)
            return room
        }
        
        func createRoom(token: String, name: String, description: String, admin: String) async throws {
            var createReq = SOGS.API().getRequest(endpoint: "/room")
            createReq.httpMethod = "POST"
            createReq.addValue("application/json", forHTTPHeaderField: "Content-Type")
            createReq.addValue("application/json", forHTTPHeaderField: "Accept")
            
            let room = SOGSRoom(token: token, name: name, description: description, admin: admin)
            createReq.httpBody = try JSONEncoder().encode(room)
            
            let (_, res) = try await URLSession.shared.data(for: createReq)
            if let response = res as? HTTPURLResponse {
                if response.statusCode != 200 {
                    throw Abort(.unauthorized)
                }
            }
        }
        
        func delRoom(token: String) async throws {
            var createReq = SOGS.API().getRequest(endpoint: "/room/\(token)")
            createReq.httpMethod = "DELETE"
            
            let (_, res) = try await URLSession.shared.data(for: createReq)
            if let response = res as? HTTPURLResponse {
                if response.statusCode != 200 {
                    throw Abort(.unauthorized)
                }
            }
        }
        
        func addMod(token: String, mod: Moderator) async throws {
            var modReq = SOGS.API().getRequest(endpoint: "/room/\(token)/moderator")
            modReq.httpMethod = "POST"
            modReq.addValue("application/json", forHTTPHeaderField: "Content-Type")
            modReq.addValue("application/json", forHTTPHeaderField: "Accept")
            modReq.httpBody = try JSONEncoder().encode(mod)
            
            let (_, res) = try await URLSession.shared.data(for: modReq)
            if let response = res as? HTTPURLResponse {
                if response.statusCode != 200 {
                    throw Abort(.unauthorized)
                }
            }
        }
        
        func delMod(token: String, mod: Moderator) async throws {
            var modReq = SOGS.API().getRequest(endpoint: "/room/\(token)/moderator")
            modReq.httpMethod = "DELETE"
            modReq.addValue("application/json", forHTTPHeaderField: "Content-Type")
            modReq.addValue("application/json", forHTTPHeaderField: "Accept")
            modReq.httpBody = try JSONEncoder().encode(mod)
            
            let (_, res) = try await URLSession.shared.data(for: modReq)
            print("Got upstream response")
            if let response = res as? HTTPURLResponse {
                if response.statusCode != 200 {
                    throw Abort(.unauthorized)
                }
            }
        }
    }
}


struct SOGSRoom: Content {
    var token: String?
    var name: String?
    var description: String?
    var url: String?
    var admin: String?
    var messages: Int?
    var activeUsers: String?
    var moderators: [String]? = []
}


extension SOGSRoom: Validatable {
    static func validations(_ validations: inout Validations) {
        validations.add("name", as: String.self, is: .count(2...))
        validations.add("description", as: String.self, is: .count(1...))
        validations.add("admin", as: String.self, is: .count(65...67) )
        validations.add("admin", as: String.self, is: .alphanumeric)
    }
}


struct Moderator: Content {
    var id: String?
    var hidden: Bool? = false
    var admin: Bool? = false
    
    
    var hiddenCheck: String?
    var adminCheck: String?
}


extension Moderator: Validatable {
    static func validations(_ validations: inout Validations) {
        validations.add("id", as: String.self, is: .alphanumeric)
        validations.add("id", as: String.self, is: .count(65...67))
    }
}
