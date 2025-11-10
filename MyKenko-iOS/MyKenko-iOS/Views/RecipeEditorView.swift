//
//  RecipeEditorView.swift
//  MyKenko-iOS
//
//  Created by Alex Donovan-Lowe 10/11/2025.
//

import Combine
import SwiftUI
import MyKenkoCore

struct RecipeEditorView: View {
    enum Mode {
        case create
        case edit

        var title: String {
            switch self {
            case .create: return "Add Recipe"
            case .edit: return "Edit Recipe"
            }
        }

        var actionTitle: String {
            switch self {
            case .create: return "Save"
            case .edit: return "Update"
            }
        }
    }

    @Environment(\.dismiss) private var dismiss

    let mode: Mode
    let ownerIdentifier: String?
    let onSave: (Recipe) -> Void
    private let originalRecipe: Recipe?

    @State private var title: String
    @State private var caloriesPerServing: String
    @State private var body: String

    init(mode: Mode, recipe: Recipe? = nil, ownerIdentifier: String?, onSave: @escaping (Recipe) -> Void) {
        self.mode = mode
        self.ownerIdentifier = ownerIdentifier
        self.onSave = onSave
        self.originalRecipe = recipe

        _title = State(initialValue: recipe?.title ?? "")
        if let value = recipe?.caloriesPerServing {
            _caloriesPerServing = State(initialValue: String(value))
        } else {
            _caloriesPerServing = State(initialValue: "")
        }
        _body = State(initialValue: recipe?.body ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Title", text: $title)
                    TextField("Calories per serving", text: $caloriesPerServing)
                        .keyboardType(.numberPad)
                }

                Section("Ingredients / Steps") {
                    TextField("Notes", text: $body, axis: .vertical)
                        .lineLimit(4...10)
                }
            }
            .navigationTitle(mode.title)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(mode.actionTitle) { save() }
                        .disabled(!canSave)
                }

                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private var canSave: Bool {
        guard let _ = ownerIdentifier ?? originalRecipe?.ownerIdentifier else { return false }
        return !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func save() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        let caloriesValue = Int(caloriesPerServing)
        var recipe = originalRecipe ?? Recipe(title: trimmedTitle,
                                              body: body,
                                              caloriesPerServing: caloriesValue,
                                              ownerIdentifier: ownerIdentifier)
        recipe.title = trimmedTitle
        recipe.body = body
        recipe.caloriesPerServing = caloriesValue
        if recipe.ownerIdentifier == nil {
            recipe.ownerIdentifier = ownerIdentifier
        }

        onSave(recipe)
        dismiss()
    }
}
