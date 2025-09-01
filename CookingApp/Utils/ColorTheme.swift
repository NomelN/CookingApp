import SwiftUI

struct ColorTheme {
    // Couleurs principales
    static let primaryGreen = Color(red: 0.2, green: 0.7, blue: 0.4)
    static let secondaryBlue = Color(red: 0.1, green: 0.4, blue: 0.8)
    static let accentOrange = Color(red: 1.0, green: 0.6, blue: 0.2)
    
    // Couleurs de statut améliorées
    static let freshGreen = Color(red: 0.2, green: 0.8, blue: 0.3)
    static let warningYellow = Color(red: 1.0, green: 0.8, blue: 0.0)
    static let criticalOrange = Color(red: 1.0, green: 0.5, blue: 0.0)
    static let expiredRed = Color(red: 0.9, green: 0.2, blue: 0.2)
    
    // Couleurs de fond
    static let backgroundGray = Color(red: 0.97, green: 0.97, blue: 0.98)
    static let cardBackground = Color.white
    static let shadowColor = Color.black.opacity(0.1)
    
    // Couleurs de texte
    static let primaryText = Color(red: 0.1, green: 0.1, blue: 0.1)
    static let secondaryText = Color(red: 0.5, green: 0.5, blue: 0.5)
    
    // Dégradés
    static let primaryGradient = LinearGradient(
        colors: [primaryGreen, secondaryBlue],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let accentGradient = LinearGradient(
        colors: [accentOrange, Color.orange],
        startPoint: .leading,
        endPoint: .trailing
    )
}