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
    @State private var selection = 0
    @State private var itemTitle = ""
    @State private var itemKcal = ""
    @State private var selectedRecipe: Recipe?

    var body: some View {
        VStack(spacing: 16) {
            Picker("Mode", selection: $selection) {
                Text("Per Item").tag(0)
                Text("From Recipe").tag(1)
            }
            .pickerStyle(.segmented)

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
                            ForEach(box.store.recipes) { r in
                                Text(r.title).tag(Optional(r))
                            }
                        }
                        Button("Add to Day") {
                            guard let r = selectedRecipe else { return }
                            let kcal = r.caloriesPerServing ?? 0
                            box.store.add(.init(title: r.title, calories: kcal, source: .recipe))
                            box.objectWillChange.send()
                            selectedRecipe = nil
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            Spacer()
        }
        .padding()
        .navigationTitle("Add Intake")
    }
}
