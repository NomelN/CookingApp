import SwiftUI

struct ColorTheme {
    private static var themeManager: ThemeManager { ThemeManager.shared }
    
    // === FONCTIONS DYNAMIQUES ===
    static func backgroundLight(isDark: Bool) -> Color {
        isDark ? 
        Color(red: 0.08, green: 0.08, blue: 0.10) :  // Noir très doux #141419
        Color(red: 0.97, green: 0.98, blue: 0.99)    // Gris très clair #F7FAFC
    }
    
    static func cardBackground(isDark: Bool) -> Color {
        isDark ?
        Color(red: 0.12, green: 0.12, blue: 0.15) :  // Gris sombre #1F1F26
        Color.white
    }
    
    static func primaryText(isDark: Bool) -> Color {
        isDark ?
        Color(red: 0.95, green: 0.95, blue: 0.97) :  // Blanc doux #F2F2F7
        Color(red: 0.11, green: 0.11, blue: 0.13)    // Noir moderne #1C1C21
    }
    
    static func secondaryText(isDark: Bool) -> Color {
        isDark ?
        Color(red: 0.70, green: 0.70, blue: 0.75) :  // Gris clair mode sombre #B3B3BF
        Color(red: 0.45, green: 0.45, blue: 0.50)    // Gris moderne #737380
    }
    
    static func sectionBackground(isDark: Bool) -> Color {
        isDark ?
        Color(red: 0.10, green: 0.11, blue: 0.13) :  // Bleu très sombre #1A1C21
        Color(red: 0.98, green: 0.99, blue: 1.0)     // Bleu très pâle #FAFDFF
    }
    
    static func shadowColor(isDark: Bool) -> Color {
        isDark ?
        Color.black.opacity(0.25) :  // Ombre plus prononcée en mode sombre
        Color.black.opacity(0.08)
    }
    
    static func borderLight(isDark: Bool) -> Color {
        isDark ?
        Color(red: 0.25, green: 0.25, blue: 0.28) :  // Bordure sombre #404045
        Color(red: 0.90, green: 0.90, blue: 0.92)    // Bordure subtile #E6E6EB
    }
    
    // === PALETTE MODERNE ===
    
    // Couleurs principales
    static let primaryBlue = Color(red: 0.25, green: 0.47, blue: 0.96)    // Bleu moderne #4080FF
    static let primaryGreen = Color(red: 0.13, green: 0.69, blue: 0.30)   // Vert Fresh #22B04C
    static let primaryPurple = Color(red: 0.48, green: 0.40, blue: 0.93)  // Violet moderne #7A67ED
    
    // Couleurs d'accent
    static let accentOrange = Color(red: 1.0, green: 0.58, blue: 0.0)     // Orange vif #FF9500
    static let accentPink = Color(red: 0.96, green: 0.26, blue: 0.62)     // Rose moderne #F5429E
    
    // Couleurs de statut (améliorées)
    static let freshGreen = Color(red: 0.13, green: 0.69, blue: 0.30)     // Même que primaryGreen
    static let warningYellow = Color(red: 1.0, green: 0.73, blue: 0.0)    // Jaune moderne #FFB900
    static let criticalOrange = Color(red: 1.0, green: 0.45, blue: 0.0)   // Orange critique #FF7300
    static let expiredRed = Color(red: 0.96, green: 0.26, blue: 0.21)     // Rouge moderne #F54336
    
    
    // === COULEURS DYNAMIQUES (MODE SOMBRE/CLAIR) ===
    
    // Arrière-plans dynamiques
    static var backgroundLight: Color {
        themeManager.isDarkMode ? 
        Color(red: 0.08, green: 0.08, blue: 0.10) :  // Noir très doux #141419
        Color(red: 0.97, green: 0.98, blue: 0.99)    // Gris très clair #F7FAFC
    }
    
    static var cardBackground: Color {
        themeManager.isDarkMode ?
        Color(red: 0.12, green: 0.12, blue: 0.15) :  // Gris sombre #1F1F26
        Color.white
    }
    
    static var fieldBackground: Color {
        themeManager.isDarkMode ?
        Color(red: 0.15, green: 0.15, blue: 0.18) :  // Gris sombre pour champs #262629
        Color(red: 0.96, green: 0.97, blue: 0.98)    // Gris ultra-léger #F5F7F9
    }
    
    static var sectionBackground: Color {
        themeManager.isDarkMode ?
        Color(red: 0.10, green: 0.11, blue: 0.13) :  // Bleu très sombre #1A1C21
        Color(red: 0.98, green: 0.99, blue: 1.0)     // Bleu très pâle #FAFDFF
    }
    
    // Textes dynamiques
    static var primaryText: Color {
        themeManager.isDarkMode ?
        Color(red: 0.95, green: 0.95, blue: 0.97) :  // Blanc doux #F2F2F7
        Color(red: 0.11, green: 0.11, blue: 0.13)    // Noir moderne #1C1C21
    }
    
    static var secondaryText: Color {
        themeManager.isDarkMode ?
        Color(red: 0.70, green: 0.70, blue: 0.75) :  // Gris clair mode sombre #B3B3BF
        Color(red: 0.45, green: 0.45, blue: 0.50)    // Gris moderne #737380
    }
    
    static var tertiaryText: Color {
        themeManager.isDarkMode ?
        Color(red: 0.55, green: 0.55, blue: 0.60) :  // Gris très clair mode sombre #8C8C99
        Color(red: 0.68, green: 0.68, blue: 0.73)    // Gris clair #AEAEB7
    }
    
    static var placeholderText: Color {
        themeManager.isDarkMode ?
        Color(red: 0.60, green: 0.60, blue: 0.65) :  // Gris placeholder mode sombre #9999A6
        Color(red: 0.60, green: 0.60, blue: 0.67)    // Gris placeholder #9999AB
    }
    
    // Éléments visuels dynamiques
    static var shadowColor: Color {
        themeManager.isDarkMode ?
        Color.black.opacity(0.25) :  // Ombre plus prononcée en mode sombre
        Color.black.opacity(0.08)
    }
    
    static var borderLight: Color {
        themeManager.isDarkMode ?
        Color(red: 0.25, green: 0.25, blue: 0.28) :  // Bordure sombre #404045
        Color(red: 0.90, green: 0.90, blue: 0.92)    // Bordure subtile #E6E6EB
    }
    
    static var borderMedium: Color {
        themeManager.isDarkMode ?
        Color(red: 0.35, green: 0.35, blue: 0.38) :  // Bordure visible mode sombre #595961
        Color(red: 0.83, green: 0.83, blue: 0.86)    // Bordure visible #D4D4DB
    }
    
    // === COMPATIBILITÉ (ancien système) ===
    static let navyBlue = primaryBlue  // Alias pour la compatibilité
    static var backgroundWhite: Color { backgroundLight }
    
    // === DÉGRADÉS MODERNES ===
    static let primaryGradient = LinearGradient(
        colors: [primaryBlue, primaryPurple],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let successGradient = LinearGradient(
        colors: [primaryGreen, Color(red: 0.05, green: 0.55, blue: 0.25)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let warningGradient = LinearGradient(
        colors: [warningYellow, accentOrange],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let accentGradient = LinearGradient(
        colors: [accentOrange, accentPink],
        startPoint: .leading,
        endPoint: .trailing
    )
}