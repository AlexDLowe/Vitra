//
//  StoreBox.swift
//  MyKenkoCore
//
//  Created by Alex Donovan-Lowe on 07/11/2025.
//

import Combine
import Foundation

@available(iOS 13.0, macOS 10.15, watchOS 6.0, *)
public final class StoreBox: ObservableObject {
    @Published public var store: any DataStore

    public init(store: any DataStore) {
        self.store = store
    }
}

// Optional helpers so views don’t forget to trigger publishes on struct mutations:
@available(iOS 13.0, macOS 10.15, watchOS 6.0, *)
public extension StoreBox {
    func addEntry(_ e: CalorieEntry) {
        objectWillChange.send()
        store.add(e)
    }
    func removeEntry(id: UUID) {
        objectWillChange.send()
        store.remove(entryID: id)
    }
    func addRecipe(_ r: Recipe) {
        objectWillChange.send()
        store.add(r)
    }
}
