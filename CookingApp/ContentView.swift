//
//  ContentView.swift
//  CookingApp
//
//  Created by Mickaël Nomel on 01/09/2025.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        DashboardView()
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
