//
//  MyKenko_iOSApp.swift
//  MyKenko-iOS
//
//  Created by Alex Donovan-Lowe on 06/11/2025.
//

import SwiftUI
import CoreData
import MyKenkoCore

@main
struct MyKenko_iOSApp: App {
    @StateObject private var box: StoreBox

    init() {
        // Use the explicit iCloud container identifier configured for this app
        let cloudKitID = "iCloud.com.AlexDonovanLowe.MyKenko"

        // Create a CoreData-backed store configured for CloudKit.
        let coreStore = CoreDataStore(cloudKitContainerIdentifier: cloudKitID)
        _box = StateObject(wrappedValue: StoreBox(store: coreStore))
    }

    var body: some Scene {
            WindowGroup {
                ContentView()
                    .environmentObject(box)
        }
    }
}
