//
//  CreateRoom.swift
//  
//
//  Created by Christopher Baltzer on 2022-08-14.
//

import Fluent


extension Room {
    struct Migration: AsyncMigration {
        var name: String { "CreateRoom" }

        func prepare(on database: Database) async throws {
            try await database.schema("rooms")
                .id()
                .field("token", .string, .required)
                .field("name", .string, .required)
                .field("description", .string, .required)
                .field("owner_id", .uuid, .required, .references("users", "id"))
                .unique(on: "token")
                .create()
        }

        func revert(on database: Database) async throws {
            try await database.schema("rooms").delete()
        }
    }
}

