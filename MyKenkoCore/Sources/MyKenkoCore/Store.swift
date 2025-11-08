//
//  Store.swift
//  MyKenkoCore
//
//  Created by Alex Donovan-Lowe on 06/11/2025.
//

import Foundation

public protocol DataStore: Sendable {
    // Entries
    func entries(on day: Date, in calendar: Calendar) -> [CalorieEntry]
    mutating func add(_ entry: CalorieEntry)
    mutating func remove(entryID: UUID)

    // Recipes
    var recipes: [Recipe] { get }
    mutating func add(_ recipe: Recipe)
    mutating func update(_ recipe: Recipe)
    mutating func remove(recipeID: UUID)

    // Goals
    var dailyGoal: DailyGoal { get set }
}

public struct InMemoryStore: DataStore {
    private(set) public var allEntries: [CalorieEntry]
    private(set) public var recipes: [Recipe]
    public var dailyGoal: DailyGoal

    public init(allEntries: [CalorieEntry] = [],
                recipes: [Recipe] = [],
                dailyGoal: DailyGoal = .init(calories: 2200)) {
        self.allEntries = allEntries
        self.recipes = recipes
        self.dailyGoal = dailyGoal
    }

    public func entries(on day: Date, in calendar: Calendar = .current) -> [CalorieEntry] {
        allEntries.filter { calendar.isDate($0.date, inSameDayAs: day) }
                  .sorted { $0.date > $1.date }
    }

    public mutating func add(_ entry: CalorieEntry) { allEntries.append(entry) }
    public mutating func remove(entryID: UUID) {
        allEntries.removeAll { $0.id == entryID }
    }

    public mutating func add(_ recipe: Recipe) { recipes.append(recipe) }
    public mutating func update(_ recipe: Recipe) {
        if let idx = recipes.firstIndex(where: { $0.id == recipe.id }) {
            recipes[idx] = recipe
        }
    }
    public mutating func remove(recipeID: UUID) { recipes.removeAll { $0.id == recipeID } }
}

public extension Array where Element == CalorieEntry {
    func totalCalories() -> Int { reduce(0) { $0 + $1.calories } }
}
