//
//  ContentView.swift
//  MyKenko-iOS
//  Created by Alex Donovan-Lowe on 06/11/2025.
//  This is the code for the portion of the app that let's you switch between different views using a tab bar.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Home", systemImage: "house.fill") }
            RecipesHubView()
                .tabItem { Label("Recipes", systemImage: "book.pages.fill") }
            AddIntakeView()
                .tabItem { Label("Add", systemImage: "plus.app.fill") }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
