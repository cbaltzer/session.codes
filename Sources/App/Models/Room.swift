//
//  Room.swift
//  
//
//  Created by Christopher Baltzer on 2022-08-14.
//

import Fluent
import Vapor


final class Room: Model, Content {
    static let schema = "rooms"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "token")
    var token: String

    @Field(key: "name")
    var name: String

    @Field(key: "description")
    var description: String
    
    @Parent(key: "owner_id")
    var owner: User
    

    init() { }

    init(id: UUID? = nil, owner: User.IDValue, name: String, description: String) {
        self.id = id
        self.$owner.id = owner
        self.token = generateToken()
        self.name = name
        self.description = description
    }
    
    func generateToken() -> String {
        let chars = UUID().uuidString.replacingOccurrences(of: "-", with: "").trimmingCharacters(in: .whitespacesAndNewlines).randomSample(count: 6)
        let token = String(chars).lowercased()
        return token
    }
}

