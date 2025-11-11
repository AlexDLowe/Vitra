//
//  SampleData.swift
//  MyKenkoCore
//
//  Created by Alex Donovan-Lowe on 06/11/2025.
//

import Foundation

@available(*, deprecated, message: "Sample data is deprecated. Use the app's CloudKit-backed persistence instead.")
public enum SampleData {
    public static func store() -> InMemoryStore {
        var s = InMemoryStore(
            allEntries: [],
            recipes: [
                Recipe(title: "Chicken Caesar Wrap",
                       body: "Grill chicken, toss with lettuce and Caesar dressing, wrap in tortilla.",
                       caloriesPerServing: 420,
                       ingredients: [
                        Ingredient(name: "Chicken", quantity: "120 g"),
                        Ingredient(name: "Tortilla", quantity: "1"),
                        Ingredient(name: "Romaine", quantity: "1 cup")
                       ])
            ],
            exercises: [
                Exercise(name: "Push Ups", numberOfSets: 3, repetitionsPerSet: 12, instructions: "Keep a flat back."),
                Exercise(name: "Air Squats", numberOfSets: 4, repetitionsPerSet: 15)
            ],
            routines: [
                Routine(name: "Full Body Blast")
            ],
            dailyGoal: DailyGoal(calories: 2200)
        )
        // a couple of today entries
        s.add(CalorieEntry(title: "Oat Latte", calories: 120, source: .item))
        s.add(CalorieEntry(title: "Wrap (½)", calories: 210, source: .recipe))
        return s
    }
}
