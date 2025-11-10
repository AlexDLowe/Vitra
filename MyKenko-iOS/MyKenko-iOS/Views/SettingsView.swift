//
//  SettingsView.swift
//  MyKenko-iOS
//
//  Created by Alex Donovan-Lowe on 10/11/2025.
//

import Combine
import SwiftUI
import AuthenticationServices
import MyKenkoCore

struct SettingsView: View {
    @EnvironmentObject private var box: StoreBox
    @EnvironmentObject private var session: SessionManager
    @State private var signInError: String?
    @State private var isProcessingSignIn: Bool = false
    @State private var showGoalEditor = false

    var body: some View {
        NavigationStack {
            List {
                accountSection
                goalSection
                aboutSection
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showGoalEditor) {
                DailyGoalEditorView(
                    title: "Daily Calorie Goal",
                    message: "Update the number of calories you want to consume each day.",
                    initialValue: box.store.dailyGoal.calories
                ) { newGoal in
                    box.store.dailyGoal = DailyGoal(calories: newGoal)
                    box.objectWillChange.send()
                    session.markGoalOnboardingComplete()
                }
            }
        }
    }

    private var accountSection: some View {
        Section("Account") {
            if let user = session.signedInUser {
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
                        session.updateUser(nil)
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

    private var goalSection: some View {
        Section("Nutrition") {
            Button {
                showGoalEditor = true
            } label: {
                HStack {
                    Text("Daily Calorie Goal")
                    Spacer()
                    Text("\(box.store.dailyGoal.calories) kcal")
                        .foregroundStyle(.secondary)
                }
            }
            .disabled(!session.isSignedIn)
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
        AppleSignInCoordinator.configureScopes(for: request)
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

                let user = AppleSignInCoordinator.user(from: credential)
                session.updateUser(user)
                signInError = nil

            case .failure(let error):
                signInError = error.localizedDescription
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(StoreBox(store: InMemoryStore()))
        .environmentObject(SessionManager())
}
