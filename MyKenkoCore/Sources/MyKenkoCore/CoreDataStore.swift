// CoreDataStore.swift
// MyKenkoCore

import Foundation
import CoreData

@available(iOS 17.0, macOS 10.15, watchOS 6.0, *)
public final class CoreDataStore: DataStore {
    private let container: NSPersistentContainer
    private var context: NSManagedObjectContext { container.viewContext }
    private var cachedExercises: [Exercise] = []
    private var cachedRoutines: [Routine] = []

    public init(container: NSPersistentContainer) {
        self.container = container
        // Use a named NSMergePolicy value rather than the old Obj-C global to avoid
        // concurrency/sendable diagnostics.
        self.context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        self.context.automaticallyMergesChangesFromParent = true
    }

    public convenience init(name: String = "MyKenkoModel", cloudKitContainerIdentifier: String? = nil) {
        let model = CoreDataStore.buildModel()

        // Use NSPersistentCloudKitContainer when available, fallback to NSPersistentContainer
        // on older platforms. Only enable NSPersistentCloudKitContainer when a
        // CloudKit container identifier is explicitly provided — otherwise use a
        // plain NSPersistentContainer so CloudKit validation (which requires
        // additional model constraints) isn't triggered unintentionally.
        let container: NSPersistentContainer
        if let id = cloudKitContainerIdentifier {
            if #available(iOS 17.0, macOS 10.15, watchOS 6.0, *) {
                let ck = NSPersistentCloudKitContainer(name: name, managedObjectModel: model)
                for desc in ck.persistentStoreDescriptions {
                    desc.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: id)
                }
                container = ck
            } else {
                // CloudKit not available on this platform — fall back to plain container
                container = NSPersistentContainer(name: name, managedObjectModel: model)
            }
        } else {
            // No CloudKit identifier requested — use plain persistent container
            container = NSPersistentContainer(name: name, managedObjectModel: model)
        }

        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Failed to load persistent stores: \(error)")
            }
        }

        self.init(container: container)
    }

    // MARK: - Model
    private static func buildModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        // Ingredient
        let ingredient = NSEntityDescription()
        ingredient.name = "IngredientEntity"
        ingredient.managedObjectClassName = "NSManagedObject"
        // keep attributes array for ingredient; we'll append the inverse relationship later
        var ingredientIDAttr = CoreDataStore.attribute(name: "id", type: .UUIDAttributeType, optional: false)
        ingredientIDAttr.defaultValue = UUID()
        var ingredientNameAttr = CoreDataStore.attribute(name: "name", type: .stringAttributeType, optional: false)
        ingredientNameAttr.defaultValue = ""
        var ingredientQtyAttr = CoreDataStore.attribute(name: "quantity", type: .stringAttributeType, optional: false)
        ingredientQtyAttr.defaultValue = ""
        let ingredientAttrs = [ingredientIDAttr, ingredientNameAttr, ingredientQtyAttr]
        ingredient.properties = ingredientAttrs

        // Recipe
        let recipe = NSEntityDescription()
        recipe.name = "RecipeEntity"
        recipe.managedObjectClassName = "NSManagedObject"

        let recipeIngredients = NSRelationshipDescription()
        recipeIngredients.name = "ingredients"
        recipeIngredients.destinationEntity = ingredient
        recipeIngredients.minCount = 0
        recipeIngredients.maxCount = 0 // to-many
        recipeIngredients.deleteRule = .cascadeDeleteRule
        // isToMany is a get-only property on some SDKs; the min/max counts describe cardinality.
        recipeIngredients.inverseRelationship = nil
        // Make the to-many relationship optional (no ingredients is allowed)
        recipeIngredients.isOptional = true
        // Explicitly mark as to-many and unordered for CloudKit compatibility
        recipeIngredients.isOrdered = false

        var recipeID = CoreDataStore.attribute(name: "id", type: .UUIDAttributeType, optional: false)
        recipeID.defaultValue = UUID()
        var recipeTitle = CoreDataStore.attribute(name: "title", type: .stringAttributeType, optional: false)
        recipeTitle.defaultValue = ""
        var recipeBody = CoreDataStore.attribute(name: "body", type: .stringAttributeType, optional: false)
        recipeBody.defaultValue = ""
        let recipeOwner = CoreDataStore.attribute(name: "ownerIdentifier", type: .stringAttributeType, optional: true)
        recipe.properties = [
            recipeID,
            recipeTitle,
            recipeBody,
            recipeOwner,
            CoreDataStore.attribute(name: "caloriesPerServing", type: .integer64AttributeType, optional: true),
            recipeIngredients
        ]

        // Create the inverse relationship on Ingredient back to Recipe (required for CloudKit)
        let ingredientRecipe = NSRelationshipDescription()
        ingredientRecipe.name = "recipe"
        ingredientRecipe.destinationEntity = recipe
        ingredientRecipe.minCount = 0
        ingredientRecipe.maxCount = 1 // to-one
        ingredientRecipe.deleteRule = .nullifyDeleteRule
        ingredientRecipe.isOptional = true
        // Explicitly mark as to-one and unordered
        ingredientRecipe.isOrdered = false

        // Wire the inverses
        recipeIngredients.inverseRelationship = ingredientRecipe
        ingredientRecipe.inverseRelationship = recipeIngredients

        // Append the inverse relationship to the ingredient's properties
        ingredient.properties = ingredientAttrs + [ingredientRecipe]

        // CalorieEntry
        let entry = NSEntityDescription()
        entry.name = "CalorieEntryEntity"
        entry.managedObjectClassName = "NSManagedObject"
        // Create attributes so we can set default values required by CloudKit integration
        var entryID = CoreDataStore.attribute(name: "id", type: .UUIDAttributeType, optional: false)
        entryID.defaultValue = UUID()
        var entryDate = CoreDataStore.attribute(name: "date", type: .dateAttributeType, optional: false)
        // Default date to now for CloudKit compatibility (attributes must be optional or have defaults)
        entryDate.defaultValue = Date()
        var entryTitle = CoreDataStore.attribute(name: "title", type: .stringAttributeType, optional: false)
        entryTitle.defaultValue = ""
        var entryCalories = CoreDataStore.attribute(name: "calories", type: .integer64AttributeType, optional: false)
        entryCalories.defaultValue = NSNumber(value: 0)
        var entrySource = CoreDataStore.attribute(name: "source", type: .stringAttributeType, optional: false)
        entrySource.defaultValue = "item"
        let entryRecipeID = CoreDataStore.attribute(name: "recipeID", type: .UUIDAttributeType, optional: true)

        entry.properties = [entryID, entryDate, entryTitle, entryCalories, entrySource, entryRecipeID]

        // DailyGoal
        let goal = NSEntityDescription()
        goal.name = "DailyGoalEntity"
        goal.managedObjectClassName = "NSManagedObject"
        var goalCalories = CoreDataStore.attribute(name: "calories", type: .integer64AttributeType, optional: false)
        goalCalories.defaultValue = NSNumber(value: 2200)
        goal.properties = [goalCalories]

        model.entities = [ingredient, recipe, entry, goal]
        return model
    }

    private static func attribute(name: String, type: NSAttributeType, optional: Bool) -> NSAttributeDescription {
        let a = NSAttributeDescription()
        a.name = name
        a.attributeType = type
        a.isOptional = optional
        return a
    }

    // MARK: - Helper conversions
    private func recipeFromManaged(_ mo: NSManagedObject) -> Recipe {
        let id = (mo.value(forKey: "id") as? UUID) ?? UUID()
        let title = (mo.value(forKey: "title") as? String) ?? ""
        let body = (mo.value(forKey: "body") as? String) ?? ""
        let caloriesPerServing = (mo.value(forKey: "caloriesPerServing") as? NSNumber)?.intValue
        let ownerIdentifier = mo.value(forKey: "ownerIdentifier") as? String
        var ingredients: [Ingredient] = []
        if let set = mo.value(forKey: "ingredients") as? NSSet {
            for case let im as NSManagedObject in set {
                let iid = (im.value(forKey: "id") as? UUID) ?? UUID()
                let name = (im.value(forKey: "name") as? String) ?? ""
                let qty = (im.value(forKey: "quantity") as? String) ?? ""
                ingredients.append(Ingredient(id: iid, name: name, quantity: qty))
            }
        }
        return Recipe(id: id,
                      title: title,
                      body: body,
                      caloriesPerServing: caloriesPerServing,
                      ingredients: ingredients,
                      ownerIdentifier: ownerIdentifier)
    }

    // MARK: - DataStore conformance
    public func entries(on day: Date, in calendar: Calendar = .current) -> [CalorieEntry] {
        var result: [CalorieEntry] = []
        context.performAndWait {
            let req = NSFetchRequest<NSManagedObject>(entityName: "CalorieEntryEntity")
            let calStart = calendar.startOfDay(for: day)
            let next = calendar.date(byAdding: .day, value: 1, to: calStart)!
            req.predicate = NSPredicate(format: "(date >= %@) AND (date < %@)", calStart as NSDate, next as NSDate)
            req.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
            if let rows = try? context.fetch(req) {
                result = rows.map { mo in
                    let id = (mo.value(forKey: "id") as? UUID) ?? UUID()
                    let date = (mo.value(forKey: "date") as? Date) ?? Date()
                    let title = (mo.value(forKey: "title") as? String) ?? ""
                    let calories = (mo.value(forKey: "calories") as? NSNumber)?.intValue ?? 0
                    let srcRaw = (mo.value(forKey: "source") as? String) ?? "item"
                    let src = CalorieEntry.Source(rawValue: srcRaw) ?? .item
                    return CalorieEntry(id: id, date: date, title: title, calories: calories, source: src)
                }
            }
        }
        return result
    }

    public func add(_ entry: CalorieEntry) {
        context.performAndWait {
            let ent = NSEntityDescription.insertNewObject(forEntityName: "CalorieEntryEntity", into: context)
            ent.setValue(entry.id, forKey: "id")
            ent.setValue(entry.date, forKey: "date")
            ent.setValue(entry.title, forKey: "title")
            ent.setValue(NSNumber(value: entry.calories), forKey: "calories")
            ent.setValue(entry.source.rawValue, forKey: "source")
            try? context.save()
        }
    }

    public func remove(entryID: UUID) {
        context.performAndWait {
            let req = NSFetchRequest<NSManagedObject>(entityName: "CalorieEntryEntity")
            req.predicate = NSPredicate(format: "id == %@", entryID as CVarArg)
            if let rows = try? context.fetch(req) {
                for r in rows { context.delete(r) }
                try? context.save()
            }
        }
    }

    public var recipes: [Recipe] {
        var result: [Recipe] = []
        context.performAndWait {
            let req = NSFetchRequest<NSManagedObject>(entityName: "RecipeEntity")
            if let rows = try? context.fetch(req) {
                result = rows.map { recipeFromManaged($0) }
            }
        }
        return result
    }

    public func add(_ recipe: Recipe) {
        context.performAndWait {
            let rmo = NSEntityDescription.insertNewObject(forEntityName: "RecipeEntity", into: context)
            rmo.setValue(recipe.id, forKey: "id")
            rmo.setValue(recipe.title, forKey: "title")
            rmo.setValue(recipe.body, forKey: "body")
            rmo.setValue(recipe.ownerIdentifier, forKey: "ownerIdentifier")
            if let cps = recipe.caloriesPerServing { rmo.setValue(NSNumber(value: cps), forKey: "caloriesPerServing") }

            var set: [NSManagedObject] = []
            for ing in recipe.ingredients {
                let imo = NSEntityDescription.insertNewObject(forEntityName: "IngredientEntity", into: context)
                imo.setValue(ing.id, forKey: "id")
                imo.setValue(ing.name, forKey: "name")
                imo.setValue(ing.quantity, forKey: "quantity")
                set.append(imo)
            }
            let ns = NSSet(array: set)
            rmo.setValue(ns, forKey: "ingredients")
            try? context.save()
        }
    }

    public func update(_ recipe: Recipe) {
        context.performAndWait {
            let req = NSFetchRequest<NSManagedObject>(entityName: "RecipeEntity")
            req.predicate = NSPredicate(format: "id == %@", recipe.id as CVarArg)
            if let rows = try? context.fetch(req), let rmo = rows.first {
                rmo.setValue(recipe.title, forKey: "title")
                rmo.setValue(recipe.body, forKey: "body")
                if let cps = recipe.caloriesPerServing {
                        rmo.setValue(NSNumber(value: cps), forKey: "caloriesPerServing")
                    } else {
                        rmo.setValue(nil, forKey: "caloriesPerServing")
                    }
                    rmo.setValue(recipe.ownerIdentifier, forKey: "ownerIdentifier")
                if let existing = rmo.value(forKey: "ingredients") as? NSSet {
                    for case let im as NSManagedObject in existing { context.delete(im) }
                }
                var set: [NSManagedObject] = []
                for ing in recipe.ingredients {
                    let imo = NSEntityDescription.insertNewObject(forEntityName: "IngredientEntity", into: context)
                    imo.setValue(ing.id, forKey: "id")
                    imo.setValue(ing.name, forKey: "name")
                    imo.setValue(ing.quantity, forKey: "quantity")
                    set.append(imo)
                }
                let ns = NSSet(array: set)
                rmo.setValue(ns, forKey: "ingredients")
                try? context.save()
            }
        }
    }

    public func remove(recipeID: UUID) {
        context.performAndWait {
            let req = NSFetchRequest<NSManagedObject>(entityName: "RecipeEntity")
            req.predicate = NSPredicate(format: "id == %@", recipeID as CVarArg)
            if let rows = try? context.fetch(req) {
                for r in rows { context.delete(r) }
                try? context.save()
            }
        }
    }
    
    public var exercises: [Exercise] {
        var result: [Exercise] = []
        context.performAndWait { result = cachedExercises }
        return result
    }

    public func add(_ exercise: Exercise) {
        context.performAndWait {
            cachedExercises.append(exercise)
        }
    }

    public func update(_ exercise: Exercise) {
        context.performAndWait {
            if let idx = cachedExercises.firstIndex(where: { $0.id == exercise.id }) {
                cachedExercises[idx] = exercise
            }
        }
    }

    public func remove(exerciseID: UUID) {
        context.performAndWait {
            cachedExercises.removeAll { $0.id == exerciseID }
        }
    }

    public var routines: [Routine] {
        var result: [Routine] = []
        context.performAndWait { result = cachedRoutines }
        return result
    }

    public func add(_ routine: Routine) {
        context.performAndWait {
            cachedRoutines.append(routine)
        }
    }

    public func update(_ routine: Routine) {
        context.performAndWait {
            if let idx = cachedRoutines.firstIndex(where: { $0.id == routine.id }) {
                cachedRoutines[idx] = routine
            }
        }
    }

    public func remove(routineID: UUID) {
        context.performAndWait {
            cachedRoutines.removeAll { $0.id == routineID }
        }
    }
    
    public var dailyGoal: DailyGoal {
        get {
            var g = DailyGoal(calories: 2200)
            context.performAndWait {
                let req = NSFetchRequest<NSManagedObject>(entityName: "DailyGoalEntity")
                if let rows = try? context.fetch(req), let mo = rows.first {
                    let cals = (mo.value(forKey: "calories") as? NSNumber)?.intValue ?? 2200
                    g = DailyGoal(calories: cals)
                } else {
                    let mo = NSEntityDescription.insertNewObject(forEntityName: "DailyGoalEntity", into: context)
                    mo.setValue(NSNumber(value: 2200), forKey: "calories")
                    try? context.save()
                }
            }
            return g
        }
        set {
            context.performAndWait {
                let req = NSFetchRequest<NSManagedObject>(entityName: "DailyGoalEntity")
                if let rows = try? context.fetch(req), let mo = rows.first {
                    mo.setValue(NSNumber(value: newValue.calories), forKey: "calories")
                } else {
                    let mo = NSEntityDescription.insertNewObject(forEntityName: "DailyGoalEntity", into: context)
                    mo.setValue(NSNumber(value: newValue.calories), forKey: "calories")
                }
                try? context.save()
            }
        }
    }
}

@available(iOS 17.0, macOS 10.15, watchOS 6.0, *)
extension CoreDataStore: @unchecked Sendable {}
