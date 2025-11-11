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
    
    // Exercises
    var exercises: [Exercise] { get }
    mutating func add(_ exercise: Exercise)
    mutating func update(_ exercise: Exercise)
    mutating func remove(exerciseID: UUID)

    // Routines
    var routines: [Routine] { get }
    mutating func add(_ routine: Routine)
    mutating func update(_ routine: Routine)
    mutating func remove(routineID: UUID)
    
    // Goals
    var dailyGoal: DailyGoal { get set }
}

public struct InMemoryStore: DataStore {
    private(set) public var allEntries: [CalorieEntry]
    private(set) public var recipes: [Recipe]
    private(set) public var exercises: [Exercise]
    private(set) public var routines: [Routine]
    public var dailyGoal: DailyGoal

    public init(allEntries: [CalorieEntry] = [],
                recipes: [Recipe] = [],
                exercises: [Exercise] = [],
                routines: [Routine] = [],
                dailyGoal: DailyGoal = .init(calories: 2200)) {
        self.allEntries = allEntries
        self.recipes = recipes
        self.exercises = exercises
        self.routines = routines
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
    
    public mutating func add(_ exercise: Exercise) { exercises.append(exercise) }
    public mutating func update(_ exercise: Exercise) {
        if let idx = exercises.firstIndex(where: { $0.id == exercise.id }) {
            exercises[idx] = exercise
        }
    }
    public mutating func remove(exerciseID: UUID) { exercises.removeAll { $0.id == exerciseID } }

    public mutating func add(_ routine: Routine) { routines.append(routine) }
    public mutating func update(_ routine: Routine) {
        if let idx = routines.firstIndex(where: { $0.id == routine.id }) {
            routines[idx] = routine
        }
    }
    public mutating func remove(routineID: UUID) { routines.removeAll { $0.id == routineID } }
}

public extension Array where Element == CalorieEntry {
    func totalCalories() -> Int { reduce(0) { $0 + $1.calories } }
}
