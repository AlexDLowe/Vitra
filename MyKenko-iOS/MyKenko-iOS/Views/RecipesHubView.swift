//
//  RecipesHubView.swift
//  MyKenko-iOS
//
//  Created by Alex Donovan-Lowe on 06/11/2025.
//

import Combine
import SwiftUI
import MyKenkoCore

struct RecipesHubView: View {
    @EnvironmentObject private var box: StoreBox
    @State private var showingAdd = false
    @State private var draft = Recipe(title: "", body: "", caloriesPerServing: nil)

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                GlassCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recipes").font(.title3).bold()
                        ForEach(box.store.recipes) { r in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(r.title).font(.headline)
                                    if let c = r.caloriesPerServing {
                                        Text("\(c) kcal/serving").foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                                Button("Add to Day") {
                                    let kcal = r.caloriesPerServing ?? 0
                                    box.store.add(.init(title: r.title, calories: kcal, source: .recipe))
                                    box.objectWillChange.send()
                                }
                                .buttonStyle(.bordered)
                            }
                            Divider()
                        }
                        HStack {
                            Button("Your Recipes") {}
                            Spacer()
                            Button("Edit / Change") {}
                        }
                        .buttonStyle(.bordered)
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
        .sheet(isPresented: $showingAdd) {
            AddRecipeSheet(draft: $draft)
                .environmentObject(box)
        }
    }
}

private struct AddRecipeSheet: View {
    @EnvironmentObject private var box: StoreBox
    @Environment(\.dismiss) private var dismiss
    @Binding var draft: Recipe
    @State private var title = ""
    @State private var tags: [Recipe.Tag] = []
    @State private var kcal = ""
    @State private var ingredients = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    
                    TextField("Title", text: $title)
                    TextField("Calories per serving (optional)", text: $kcal)
                        .keyboardType(.numberPad)
                    TextField("Ingredients (free text)", text: $ingredients, axis: .vertical)
                        .lineLimit(4...8)
                }
                Section("Tags") {
                    TagSelectorView(selectedTags: $tags)
                }
            }
            .navigationTitle("Add Recipe")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let c = Int(kcal)
                        let recipe = Recipe(title: title, tags: tags, body: ingredients, caloriesPerServing: c)
                        box.store.add(recipe)
                        box.objectWillChange.send()
                        dismiss()
                    }
                }

                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
