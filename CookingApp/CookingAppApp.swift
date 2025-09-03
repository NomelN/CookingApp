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
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(themeManager)
                .preferredColorScheme(themeManager.isDarkMode ? .dark : .light)
                .onAppear {
                    NotificationManager.shared.requestPermission()
                    // Réinitialiser le badge quand l'app s'ouvre
                    NotificationManager.shared.clearAppBadge()
                }
                .animation(.easeInOut(duration: 0.3), value: themeManager.currentTheme)
        }
    }
}

