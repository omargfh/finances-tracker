//
//  FMangerApp.swift
//  FManger
//
//  Created by Omar Ibrahim on 3/2/22.
//

import SwiftUI

@main
struct FMangerApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
