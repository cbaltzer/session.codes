//
//  HomeContent.swift
//  
//
//  Created by Christopher Baltzer on 2022-08-14.
//

import Foundation
import Vapor

struct HomeContent: Content {
    var pageTitle: String
    var loggedIn: Bool
    var rooms: [SOGSRoom]
}
