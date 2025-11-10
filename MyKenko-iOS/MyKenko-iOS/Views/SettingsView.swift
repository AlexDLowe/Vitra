//
//  SettingsView.swift
//  MyKenko-iOS
//
//  Created by Alex Donovan-Lowe on 10/11/2025.
//

import SwiftUI
import AuthenticationServices

struct AppleSignInUser {
    let displayName: String
    let email: String?
    let identifier: String
}

struct SettingsView: View {
    @State private var signedInUser: AppleSignInUser?
    @State private var signInError: String?
    @State private var isProcessingSignIn: Bool = false

    var body: some View {
        NavigationStack {
            List {
                accountSection
                aboutSection
            }
            .navigationTitle("Settings")
        }
    }

    private var accountSection: some View {
        Section("Account") {
            if let user = signedInUser {
                VStack(alignment: .leading, spacing: 4) {
                    Text(user.displayName)
                        .font(.headline)
                    if let email = user.email {
                        Text(email)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Text("Apple ID: \(user.identifier)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)

                Button(role: .destructive) {
                    withAnimation {
                        signedInUser = nil
                        signInError = nil
                    }
                } label: {
                    Text("Sign Out")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Sign in to sync your preferences across devices.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    SignInWithAppleButton(.signIn, onRequest: configureAppleIDRequest, onCompletion: handleAppleIDResult)
                        .signInWithAppleButtonStyle(.black)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .accessibilityIdentifier("signInWithAppleButton")
                        .disabled(isProcessingSignIn)

                    if let error = signInError {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .transition(.opacity)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 4)
            }
        }
    }

    private var aboutSection: some View {
        Section("About") {
            VStack(alignment: .leading, spacing: 4) {
                Text("MyKenko")
                    .font(.headline)
                Text("Version 1.0")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("Track your wellness journey with personalized insights and nutrition guidance.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
        }
    }

    private func configureAppleIDRequest(_ request: ASAuthorizationAppleIDRequest) {
        request.requestedScopes = [.fullName, .email]
        isProcessingSignIn = true
        signInError = nil
    }

    private func handleAppleIDResult(_ result: Result<ASAuthorization, Error>) {
        DispatchQueue.main.async {
            isProcessingSignIn = false

            switch result {
            case .success(let authorization):
                guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                    signInError = "Unable to parse Apple ID credential."
                    return
                }

                let nameComponents = credential.fullName
                let formatter = PersonNameComponentsFormatter()
                formatter.style = .default
                let fullName = nameComponents.flatMap { formatter.string(from: $0) }?.trimmingCharacters(in: .whitespacesAndNewlines)

                let displayName = [fullName, credential.email].compactMap { $0 }.first ?? "Signed in"

                signedInUser = AppleSignInUser(
                    displayName: displayName,
                    email: credential.email,
                    identifier: credential.user
                )
                signInError = nil

            case .failure(let error):
                signInError = error.localizedDescription
            }
        }
    }
}

#Preview {
    SettingsView()
}
