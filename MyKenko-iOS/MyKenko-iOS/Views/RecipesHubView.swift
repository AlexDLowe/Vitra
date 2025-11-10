//
//  RecipesHubView.swift
//  MyKenko-iOS
//
//  Created by Alex Donovan-Lowe on 06/11/2025.
//  Last edited on 10/11/2025.

import Combine
import SwiftUI
import MyKenkoCore

struct RecipesHubView: View {
    @EnvironmentObject private var box: StoreBox
    @EnvironmentObject private var session: SessionManager
    @State private var showingAdd = false
    private var recipes: [Recipe] {
        guard let userID = session.signedInUser?.identifier else { return [] }
        return box.store.recipes.filter { $0.ownerIdentifier == userID }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Your Recipes")
                                .font(.title3.bold())

                            if recipes.isEmpty {
                                ContentUnavailableView(
                                    "No recipes yet",
                                    systemImage: "book",
                                    description: Text("Create a recipe to make it easy to log later.")
                                )
                                .frame(maxWidth: .infinity)
                            } else {
                                ForEach(recipes) { recipe in
                                    HStack(alignment: .center, spacing: 12) {
                                        NavigationLink(destination: RecipeDetailView(recipeID: recipe.id)) {
                                            HStack {
                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text(recipe.title)
                                                        .font(.headline)
                                                    if let calories = recipe.caloriesPerServing {
                                                        Text("\(calories) kcal/serving")
                                                            .font(.subheadline)
                                                            .foregroundStyle(.secondary)
                                                    }
                                                }
                                                Spacer()
                                                Image(systemName: "chevron.right")
                                                    .foregroundStyle(.tertiary)
                                            }
                                            .contentShape(Rectangle())
                                        }
                                        .buttonStyle(.plain)

                                        Button("Add to Day") {
                                            let kcal = recipe.caloriesPerServing ?? 0
                                            box.store.add(.init(title: recipe.title, calories: kcal, source: .recipe))
                                            box.objectWillChange.send()
                                        }
                                        .buttonStyle(.bordered)
                                    }
                                    Divider()
                                }
                            }
                        }
                    }
                GlassCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Add a Recipe").font(.headline)
                        Button("Create New") { showingAdd = true }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                }
                        .padding()
            }
                    .navigationTitle("Recipes")
        }
        .sheet(isPresented: $showingAdd) {
            RecipeEditorView(mode: .create, ownerIdentifier: session.signedInUser?.identifier) { recipe in
                box.store.add(recipe)
                box.objectWillChange.send()
            }
        }
    }
}
