//
//  AppleSignInCoordinator.swift
//  MyKenko-iOS
//
//  Created by Alex Donovan-Lowe on 10/11/2025.
//
//  Shared helpers to translate Sign in with Apple results into app models.
//

import AuthenticationServices
import Foundation

enum AppleSignInCoordinator {
    static func configureScopes(for request: ASAuthorizationAppleIDRequest) {
        request.requestedScopes = [.fullName, .email]
    }

    static func user(from credential: ASAuthorizationAppleIDCredential) -> AppleSignInUser {
        let nameComponents = credential.fullName
        let formatter = PersonNameComponentsFormatter()
        formatter.style = .default
        let fullName = nameComponents.flatMap { formatter.string(from: $0) }?.trimmingCharacters(in: .whitespacesAndNewlines)

        let displayName = [fullName, credential.email].compactMap { $0 }.first ?? "Signed in"

        return AppleSignInUser(
            displayName: displayName,
            email: credential.email,
            identifier: credential.user
        )
    }
}
