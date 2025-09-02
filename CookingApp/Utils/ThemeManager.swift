import SwiftUI
import Combine

enum ThemeMode: String, CaseIterable {
    case light = "light"
    case dark = "dark"
    
    var displayName: String {
        switch self {
        case .light:
            return "Clair"
        case .dark:
            return "Sombre"
        }
    }
    
    var iconName: String {
        switch self {
        case .light:
            return "sun.max.fill"
        case .dark:
            return "moon.fill"
        }
    }
}

class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @Published var currentTheme: ThemeMode {
        didSet {
            UserDefaults.standard.set(currentTheme.rawValue, forKey: "selectedTheme")
        }
    }
    
    private init() {
        let savedTheme = UserDefaults.standard.string(forKey: "selectedTheme") ?? ThemeMode.light.rawValue
        self.currentTheme = ThemeMode(rawValue: savedTheme) ?? .light
    }
    
    func setTheme(_ theme: ThemeMode) {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentTheme = theme
        }
    }
    
    var isDarkMode: Bool {
        currentTheme == .dark
    }
}