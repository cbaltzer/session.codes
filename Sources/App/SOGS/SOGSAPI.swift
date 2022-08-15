//
//  SOGSAPI.swift
//  
//
//  Created by Christopher Baltzer on 2022-08-14.
//

import Foundation
import Vapor
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

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
            print("Getting room: \(token)")
            let roomReq = SOGS.API().getRequest(endpoint: "/room/\(token)")
            let data = try await asyncData(for: roomReq)
            
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
            
            try await asyncData(for: createReq)
        }
        
        func delRoom(token: String) async throws {
            var delReq = SOGS.API().getRequest(endpoint: "/room/\(token)")
            delReq.httpMethod = "DELETE"
            
            try await asyncData(for: delReq)
        }
        
        func addMod(token: String, mod: Moderator) async throws {
            var modReq = SOGS.API().getRequest(endpoint: "/room/\(token)/moderator")
            modReq.httpMethod = "POST"
            modReq.addValue("application/json", forHTTPHeaderField: "Content-Type")
            modReq.addValue("application/json", forHTTPHeaderField: "Accept")
            modReq.httpBody = try JSONEncoder().encode(mod)
            
            try await asyncData(for: modReq)
        }
        
        func delMod(token: String, mod: Moderator) async throws {
            var modReq = SOGS.API().getRequest(endpoint: "/room/\(token)/moderator")
            modReq.httpMethod = "DELETE"
            modReq.addValue("application/json", forHTTPHeaderField: "Content-Type")
            modReq.addValue("application/json", forHTTPHeaderField: "Accept")
            modReq.httpBody = try JSONEncoder().encode(mod)
            
            try await asyncData(for: modReq)
        }
        
        
        @discardableResult func asyncData(for request: URLRequest) async throws -> Data {
            return try await Task { () -> Data in
                let semaphore = DispatchSemaphore(value: 0)
                var data = Data()
                var response: URLResponse?
                var error: Error?
                                
                let task = URLSession.shared.dataTask(with: request) { d, res, err in
                    if let resData = d {
                        data = resData
                    }
                    response = res
                    error = err
                    
                    semaphore.signal()
                }
                
                task.resume()
                _ = semaphore.wait(timeout: .now() + 30)
                
                if let response = response as? HTTPURLResponse {
                    print("response: \(response.statusCode)")
                    if response.statusCode != 200 {
                        print("aborting")
                        throw Abort(.unauthorized)
                    }
                }
                
                if error != nil {
                    throw Abort(.internalServerError)
                }
                
                return data
            }.result.get()
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
