//
//  ContentView.swift
//  MyKenko-iOS
//  Created by Alex Donovan-Lowe on 06/11/2025.
//  This is the code for the portion of the app that let's you switch between different views using a tab bar.
//

import SwiftUI
import AuthenticationServices
import MyKenkoCore
import Combine

struct ContentView: View {
    @EnvironmentObject private var box: StoreBox
    @EnvironmentObject private var session: SessionManager
    @State private var showGoalPrompt = false
    @State private var pendingGoalValue: Int = 2200

    var body: some View {
        Group {
            if session.isSignedIn {
                MainTabView()
            } else {
                SignInSplashView()
            }
        }
        .onAppear(perform: evaluateGoalPrompt)
        .onChange(of: session.signedInUser) { _ in
            evaluateGoalPrompt()
        }
        .sheet(isPresented: $showGoalPrompt) {
            DailyGoalEditorView(
                title: "Daily Calorie Goal",
                message: "Set the number of calories you aim to consume each day.",
                initialValue: pendingGoalValue
            ) { newGoal in
                box.store.dailyGoal = DailyGoal(calories: newGoal)
                box.objectWillChange.send()
                session.markGoalOnboardingComplete()
                showGoalPrompt = false
            }
        }
    }

    private func evaluateGoalPrompt() {
        guard session.isSignedIn else {
            showGoalPrompt = false
            return
        }

        pendingGoalValue = box.store.dailyGoal.calories
        if session.needsGoalOnboarding {
            showGoalPrompt = true
        } else {
            showGoalPrompt = false
        }
    }
}

private struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Home", systemImage: "house.fill") }
            RecipesHubView()
                .tabItem { Label("Recipes", systemImage: "book.pages.fill") }
            AddIntakeView()
                .tabItem { Label("Add", systemImage: "plus.app.fill") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
    }
}

private struct SignInSplashView: View {
    @EnvironmentObject private var session: SessionManager
    @State private var signInError: String?
    @State private var isProcessing = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            VStack(spacing: 12) {
                Image(systemName: "heart.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 96, height: 96)
                    .foregroundStyle(.pink)
                Text("Welcome to MyKenko")
                    .font(.largeTitle).bold()
                    .multilineTextAlignment(.center)
                Text("Sign in with your Apple ID to sync your nutrition goals across devices.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 12) {
                SignInWithAppleButton(.signIn, onRequest: configureRequest, onCompletion: handleResult)
                    .signInWithAppleButtonStyle(.black)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .disabled(isProcessing)

                if let signInError {
                    Text(signInError)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 32)

            Spacer()
        }
        .padding()
    }

    private func configureRequest(_ request: ASAuthorizationAppleIDRequest) {
        AppleSignInCoordinator.configureScopes(for: request)
        isProcessing = true
        signInError = nil
    }

    private func handleResult(_ result: Result<ASAuthorization, Error>) {
        isProcessing = false

        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                signInError = "Unable to parse Apple ID credential."
                return
            }

            let user = AppleSignInCoordinator.user(from: credential)
            session.updateUser(user)

        case .failure(let error):
            signInError = error.localizedDescription
        }
    }
}
