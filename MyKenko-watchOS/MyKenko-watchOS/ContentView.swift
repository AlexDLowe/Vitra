//
//  ContentView.swift
//  MyKenko-watchOS
//
//  Created by Alex Donovan-Lowe on 06/11/2025.
//

import SwiftUI
import MyKenkoCore
internal import Combine

struct ContentView: View {
    @EnvironmentObject private var box: StoreBox
    @Environment(\.calendar) private var calendar

    var body: some View {
        let entries = box.store.entries(on: .now, in: calendar)
        let consumed = entries.totalCalories()
        let goal = box.store.dailyGoal.calories
        VStack(spacing: 8) {
            ProgressView(value: Double(consumed), total: Double(max(goal, 1)))
                .tint(.green)
            Text("\(consumed)/\(goal) kcal").font(.headline)
            Button("+ 100 kcal") {
                box.store.add(.init(title: "Quick Add", calories: 100, source: .item))
                box.objectWillChange.send()
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
}
