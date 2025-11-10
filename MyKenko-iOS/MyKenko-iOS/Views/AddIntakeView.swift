//
//  AddIntakeView.swift
//  MyKenko-iOS
//
//  Created by Alex Donovan-Lowe on 06/11/2025.
//

import Combine
import SwiftUI
import MyKenkoCore

struct AddIntakeView: View {
    @EnvironmentObject private var box: StoreBox
    @EnvironmentObject private var session: SessionManager
    @State private var selection = 0
    @State private var itemTitle = ""
    @State private var itemKcal = ""
    @State private var selectedRecipe: Recipe?
    
    private var recipes: [Recipe] {
        guard let userID = session.signedInUser?.identifier else { return [] }
        return box.store.recipes.filter { $0.ownerIdentifier == userID }
    }


    var body: some View {
        VStack(spacing: 16) {
            Picker("Mode", selection: $selection) {
                Text("Per Item").tag(0)
                Text("From Recipe").tag(1)
            }
            .pickerStyle(.segmented)
            .onChange(of: selection) { newValue in
                if newValue == 1, selectedRecipe == nil {
                    selectedRecipe = recipes.first
                }
            }
            if selection == 0 {
                GlassCard {
                    VStack(spacing: 12) {
                        TextField("Item name", text: $itemTitle)
                        TextField("Calories", text: $itemKcal)
                            .keyboardType(.numberPad)
                        Button("Add to Day") {
                            if let kcal = Int(itemKcal), !itemTitle.isEmpty {
                                box.store.add(.init(title: itemTitle, calories: kcal, source: .item))
                                box.objectWillChange.send()
                                itemTitle = ""; itemKcal = ""
                            }
                        }.buttonStyle(.borderedProminent)
                        Button("Save as Database Item") { /* optional future */ }
                            .buttonStyle(.bordered)
                    }
                }
            } else {
                GlassCard {
                    VStack(spacing: 12) {
                        Picker("Recipe", selection: $selectedRecipe) {
                            ForEach(recipes) { r in
                                Text(r.title).tag(Optional(r))
                            }
                        }
                        .disabled(recipes.isEmpty)
                        
                        Button("Add to Day") {
                            guard let r = selectedRecipe else { return }
                            let kcal = r.caloriesPerServing ?? 0
                            box.store.add(.init(title: r.title, calories: kcal, source: .recipe))
                            box.objectWillChange.send()
                            selectedRecipe = nil
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(selectedRecipe == nil)
                    }
                }
            }
            Spacer()
        }
        .padding()
        .navigationTitle("Add Intake")
        .onAppear {
            if selectedRecipe == nil {
                selectedRecipe = recipes.first
            }
        }
        .onChange(of: recipes) { newRecipes in
            guard let selectedRecipe else {
                self.selectedRecipe = newRecipes.first
                return
            }
            if !newRecipes.contains(selectedRecipe) {
                self.selectedRecipe = newRecipes.first
            }
        }
    }
}
