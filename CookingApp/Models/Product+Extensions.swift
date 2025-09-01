import Foundation
import SwiftUI

extension Product {
    var daysUntilExpiration: Int {
        guard let expirationDate = expirationDate else { return 0 }
        return Calendar.current.dateComponents([.day], from: Date(), to: expirationDate).day ?? 0
    }
    
    var expirationStatus: ExpirationStatus {
        let days = daysUntilExpiration
        
        if days < 0 {
            return .expired
        } else if days <= 3 {
            return .critical
        } else if days <= 7 {
            return .warning
        } else {
            return .good
        }
    }
    
    var statusColor: Color {
        switch expirationStatus {
        case .good:
            return ColorTheme.freshGreen
        case .warning:
            return ColorTheme.warningYellow
        case .critical:
            return ColorTheme.criticalOrange
        case .expired:
            return ColorTheme.expiredRed
        }
    }
    
    var image: Image? {
        guard let imageData = imageData,
              let uiImage = UIImage(data: imageData) else {
            return nil
        }
        return Image(uiImage: uiImage)
    }
}

enum ExpirationStatus {
    case good
    case warning
    case critical
    case expired
    
    var description: String {
        switch self {
        case .good:
            return "Frais"
        case .warning:
            return "À consommer bientôt"
        case .critical:
            return "À consommer rapidement"
        case .expired:
            return "Expiré"
        }
    }
}