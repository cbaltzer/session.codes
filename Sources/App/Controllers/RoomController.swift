//
//  RoomController.swift
//  
//
//  Created by Christopher Baltzer on 2022-08-14.
//

import Fluent
import Vapor

struct RoomController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let protected = routes.grouped([
            User.credentialsAuthenticator(),
            User.redirectMiddleware(path: "/login")
        ]).grouped("app")
        
        
        protected.get("home", use: home)
        protected.post("createRoom", use: createRoom)
        protected.post("delRoom", ":room", use: delRoom)
        protected.post("addMod", ":room", use: addMod)
        protected.post("delMod", ":room", ":mod", use: delMod)
    }

    
    func home(req: Request) async throws -> View {
        let user = try req.auth.require(User.self)
            
        let ownedRooms = try await Room.query(on: req.db).filter(\.$owner.$id == user.id!).all()

        var rooms: [SOGSRoom] = []
        for ownedRoom in ownedRooms {
            var sogsRoom = try await SOGS.API().getRoom(token: ownedRoom.token)
            if sogsRoom.moderators == nil {
                sogsRoom.moderators = []
            }
            if sogsRoom.token != nil {
                rooms.append(sogsRoom)
            }
        }
        
        return try await req.view.render("home", HomeContent(pageTitle: "Dashboard : session.codes",
                                                             loggedIn: true,
                                                             rooms: rooms))
    }

    
    func createRoom(req: Request) async throws -> Response {
        let user = try req.auth.require(User.self)
        try SOGSRoom.validate(content: req)
        let toCreate = try req.content.decode(SOGSRoom.self)
        
        let newRoom = Room(owner: user.id!, name: toCreate.name!, description: toCreate.description!)
        try await SOGS.API().createRoom(token: newRoom.token, name: newRoom.name, description: newRoom.description, admin: toCreate.admin!)
        
        try await newRoom.save(on: req.db)
        return req.redirect(to: "/app/home")
    }
    
    
    func delRoom(req: Request) async throws -> Response {
        guard let room = try await ownedRoom(req: req) else {
            throw Abort(.unauthorized)
        }
        
        try await SOGS.API().delRoom(token: room.token)
        try await room.delete(force: true, on: req.db)
        
        return req.redirect(to: "/app/home")
    }
    
    
    func addMod(req: Request) async throws -> Response {
        guard let room = try await ownedRoom(req: req) else {
            throw Abort(.unauthorized)
        }
        
        try Moderator.validate(content: req)
        var mod = try req.content.decode(Moderator.self)
        
        mod.hidden = Bool(mod.hiddenCheck ?? "false")
        mod.admin = Bool(mod.adminCheck ?? "false")
        
        
        try await SOGS.API().addMod(token: room.token, mod: mod)
        
        return req.redirect(to: "/app/home")
    }
    
    
    func delMod(req: Request) async throws -> Response {
        guard let room = try await ownedRoom(req: req) else {
            throw Abort(.unauthorized)
        }
        
        guard let modID = req.parameters.get("mod") else {
            throw Abort(.badRequest)
        }
        
        let mod = Moderator(id: modID, hidden: false, admin: false)
        
        try await SOGS.API().delMod(token: room.token, mod: mod)
        
        return req.redirect(to: "/app/home")
    }
    
    
    
    
    func ownedRoom(req: Request) async throws -> Room? {
        let user = try req.auth.require(User.self)
        guard let roomToken = req.parameters.get("room") else {
            throw Abort(.badRequest)
        }
        
        guard let room = try await Room.query(on: req.db).filter(\.$token == roomToken).first() else {
            throw Abort(.unauthorized)
        }
        
        if room.$owner.id != user.id {
            throw Abort(.unauthorized)
        }
        
        return room
    }
}

