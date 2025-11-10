//
//  AppleSignInUser.swift
//  MyKenko-iOS
//
//  Created by Alex Donovan-Lowe on 10/11/2025.
//
//  Created to share the signed-in user state across the application.
//

import Foundation

struct AppleSignInUser: Codable, Equatable {
    let displayName: String
    let email: String?
    let identifier: String
}
