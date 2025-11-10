//
//  Domain.swift
//  MyKenkoCore
//
//  Created by Alex Donovan-Lowe on 06/11/2025.
//

import Foundation

public struct CalorieEntry: Identifiable, Codable, Equatable, Sendable {
    public enum Source: String, Codable, Sendable { case item, recipe }
    public let id: UUID
    public var date: Date
    public var title: String
    public var calories: Int
    public var source: Source

    public init(id: UUID = .init(),
                date: Date = .init(),
                title: String,
                calories: Int,
                source: Source) {
        self.id = id
        self.date = date
        self.title = title
        self.calories = calories
        self.source = source
    }
}

public struct Ingredient: Identifiable, Codable, Equatable, Sendable, Hashable {
    public let id: UUID
    public var name: String
    public var quantity: String
    public init(id: UUID = .init(), name: String, quantity: String) {
        self.id = id; self.name = name; self.quantity = quantity
    }
}

public struct Recipe: Identifiable, Codable, Equatable, Sendable, Hashable {
    public enum Tag: String, Codable, CaseIterable, Hashable, Sendable {
        case vegetarian = "Vegetarian"
        case vegan = "Vegan"
        case glutenFree = "Gluten-Free"
        case dairyFree = "Dairy-Free"
        case pescatarian = "Pescatarian"
    }
    public let id: UUID
    public var title: String
    public var tags: [Tag]
    public var body: String
    public var caloriesPerServing: Int?
    public var ingredients: [Ingredient]
    public var ownerIdentifier: String?

    public init(id: UUID = .init(),
                title: String,
                tags: [Tag] = [],
                body: String,
                caloriesPerServing: Int? = nil,
                ingredients: [Ingredient] = [],
                ownerIdentifier: String? = nil) {
        self.id = id
        self.title = title
        self.tags = tags
        self.body = body
        self.caloriesPerServing = caloriesPerServing
        self.ingredients = ingredients
        self.ownerIdentifier = ownerIdentifier
    }
}

public struct DailyGoal: Codable, Equatable, Sendable {
    public var calories: Int
    public init(calories: Int) { self.calories = calories }
}
