//
//  SessionManager.swift
//  MyKenko-iOS
//
//  Created by Alex Donovan-Lowe on 10/11/2025.
//
//  Coordinates the authenticated user state and lightweight onboarding flags.
//

import Combine
import Foundation

@MainActor
final class SessionManager: ObservableObject {
    @Published private(set) var signedInUser: AppleSignInUser?

    private let defaults = UserDefaults.standard
    private let userKey = "session.signedInUser"
    private var goalKey: String? {
        signedInUser.map { "session.goalOnboardingComplete.\($0.identifier)" }
    }

    init() {
        if let data = defaults.data(forKey: userKey),
           let user = try? JSONDecoder().decode(AppleSignInUser.self, from: data) {
            signedInUser = user
        }
    }

    var isSignedIn: Bool { signedInUser != nil }

    func updateUser(_ user: AppleSignInUser?) {
        signedInUser = user

        if let user, let data = try? JSONEncoder().encode(user) {
            defaults.set(data, forKey: userKey)
        } else {
            defaults.removeObject(forKey: userKey)
        }
    }

    var needsGoalOnboarding: Bool {
        guard let key = goalKey else { return false }
        return !defaults.bool(forKey: key)
    }

    func markGoalOnboardingComplete() {
        guard let key = goalKey else { return }
        defaults.set(true, forKey: key)
    }
}
