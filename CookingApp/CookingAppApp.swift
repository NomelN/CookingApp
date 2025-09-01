//
//  CookingAppApp.swift
//  CookingApp
//
//  Created by Mickaël Nomel on 01/09/2025.
//

import SwiftUI

@main
struct CookingAppApp: App {
    let persistenceController = PersistenceController.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}

