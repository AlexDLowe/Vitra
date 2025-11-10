//
//  RecipeDetailView.swift
//  MyKenko-iOS
//
//  Created by Alex Donovan-Lowe 10/11/2025.
//

import Combine
import SwiftUI
import MyKenkoCore

struct RecipeDetailView: View {
    let recipeID: UUID

    @EnvironmentObject private var box: StoreBox
    @EnvironmentObject private var session: SessionManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingEditor = false

    private var recipe: Recipe? {
        box.store.recipes.first(where: { $0.id == recipeID })
    }

    private var canEdit: Bool {
        guard let recipe, let currentUser = session.signedInUser?.identifier else { return false }
        return recipe.ownerIdentifier == currentUser
    }

    var body: some View {
        Group {
            if let recipe {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(recipe.title)
                                .font(.largeTitle.bold())
                            if let calories = recipe.caloriesPerServing {
                                Text("\(calories) kcal per serving")
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        if !recipe.body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Details")
                                    .font(.title3.bold())
                                Text(recipe.body)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding()
                                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                        }
                    }
                    .padding()
                }
                .background(Color(uiColor: .systemGroupedBackground))
            } else {
                VStack(spacing: 16) {
                    Text("Recipe unavailable")
                        .font(.headline)
                    Button("Back") { dismiss() }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if canEdit {
                    Button("Edit") { showingEditor = true }
                }
            }
        }
        .sheet(isPresented: $showingEditor) {
            if let recipe = recipe {
                RecipeEditorView(mode: .edit, recipe: recipe, ownerIdentifier: session.signedInUser?.identifier) { updated in
                    box.store.update(updated)
                    box.objectWillChange.send()
                }
            }
        }
    }
}
