//
//  HomeView.swift
//  MyKenko-iOS
//
//  Created by Alex Donovan-Lowe on 06/11/2025.
//

import Combine
import SwiftUI
import MyKenkoCore

struct HomeView: View {
    @EnvironmentObject private var box: StoreBox
    @Environment(\.calendar) private var calendar
    @State private var showQuickAdd = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                GlassCard {
                    let entries = box.store.entries(on: .now, in: calendar)
                    let consumed = entries.totalCalories()
                    let goal = box.store.dailyGoal.calories
                    VStack(spacing: 12) {
                        ProgressRing(progress: Double(consumed) / Double(max(goal, 1)))
                            .frame(width: 160, height: 160)
                        Text("\(consumed) / \(goal) kcal")
                            .font(.title2).bold()
                        Text(remainingText(consumed: consumed, goal: goal))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }

                GlassCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Quick Add").font(.headline)
                        HStack {
                            Button("Per Item") { showQuickAdd = true }
                                .buttonStyle(.borderedProminent)
                            Button("From Recipe") { /* present picker */ }
                                .buttonStyle(.bordered)
                        }
                    }
                }

                GlassCard {
                    let entries = box.store.entries(on: .now, in: calendar)
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Today’s Entries").font(.headline)
                        ForEach(entries) { e in
                            HStack {
                                Text(e.title)
                                Spacer()
                                Text("\(e.calories) kcal")
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 6)
                            .contentShape(Rectangle())
                            .onLongPressGesture {
                                box.store.remove(entryID: e.id)
                                box.objectWillChange.send()
                            }
                            Divider()
                        }
                    }
                }
            }
            .padding()
        }
        .sheet(isPresented: $showQuickAdd) {
            QuickAddSheet()
                .environmentObject(box)
                .presentationDetents([.medium, .large])
        }
    }

    private func remainingText(consumed: Int, goal: Int) -> String {
        let remaining = goal - consumed
        if remaining >= 0 { return "\(remaining) kcal remaining" }
        return "\(-remaining) kcal over goal"
    }
}

private struct QuickAddSheet: View {
    @EnvironmentObject private var box: StoreBox
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var calories = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("Item name", text: $title)
                TextField("Calories", text: $calories)
                    .keyboardType(.numberPad)
            }
            .navigationTitle("Add Item")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        if let kcal = Int(calories), !title.isEmpty {
                            box.store.add(.init(title: title, calories: kcal, source: .item))
                            box.objectWillChange.send()
                            dismiss()
                        }
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
