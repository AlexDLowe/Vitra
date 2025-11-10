//
//  DailyGoalEditorView.swift
//  MyKenko-iOS
//
//  Created by Alex Donovan-Lowe on 10/11/2025.
//
//  Reusable sheet that lets the user review and update their calorie goal.
//

import SwiftUI

struct DailyGoalEditorView: View {
    let title: String
    let message: String?
    let onSave: (Int) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var calorieText: String
    @State private var errorMessage: String?

    init(title: String, message: String? = nil, initialValue: Int, onSave: @escaping (Int) -> Void) {
        self.title = title
        self.message = message
        self.onSave = onSave
        _calorieText = State(initialValue: String(initialValue))
    }

    var body: some View {
        NavigationStack {
            Form {
                if let message {
                    Text(message)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .listRowBackground(Color.clear)
                }

                Section("Daily Calories") {
                    TextField("Calories", text: $calorieText)
                        .keyboardType(.numberPad)
                        .onChange(of: calorieText) { _ in
                            errorMessage = nil
                        }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveGoal() }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func saveGoal() {
        guard let value = Int(calorieText.trimmingCharacters(in: .whitespaces)), value > 0 else {
            errorMessage = "Enter a positive number of calories."
            return
        }

        onSave(value)
        dismiss()
    }
}

#Preview {
    DailyGoalEditorView(title: "Daily Calorie Goal", message: "Preview", initialValue: 2200) { _ in }
}
