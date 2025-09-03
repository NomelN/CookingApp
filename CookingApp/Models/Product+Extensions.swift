import Foundation
import SwiftUI

extension Product {
    func daysUntilExpiration(from currentDate: Date = Date()) -> Int {
        guard let expirationDate = expirationDate else { return 0 }
        
        let calendar = Calendar.current
        let currentDateStart = calendar.startOfDay(for: currentDate)
        let expirationDateStart = calendar.startOfDay(for: expirationDate)
        
        return calendar.dateComponents([.day], from: currentDateStart, to: expirationDateStart).day ?? 0
    }
    
    var daysUntilExpiration: Int {
        return daysUntilExpiration(from: Date())
    }
    
    func expirationStatus(from currentDate: Date = Date()) -> ExpirationStatus {
        let days = daysUntilExpiration(from: currentDate)
        
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
    
    var expirationStatus: ExpirationStatus {
        return expirationStatus(from: Date())
    }
    
    func statusColor(from currentDate: Date = Date()) -> Color {
        switch expirationStatus(from: currentDate) {
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
    
    var statusColor: Color {
        return statusColor(from: Date())
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

enum ProductFilter: String, CaseIterable {
    case all = "Tous"
    case expired = "Expirés"
    case expiringSoon = "Expire bientôt"
    case fresh = "Frais"
    
    var systemIcon: String {
        switch self {
        case .all:
            return "basket.fill"
        case .expired:
            return "exclamationmark.triangle.fill"
        case .expiringSoon:
            return "clock.fill"
        case .fresh:
            return "checkmark.circle.fill"
        }
    }
    
    func matches(_ product: Product, from currentDate: Date) -> Bool {
        let status = product.expirationStatus(from: currentDate)
        
        switch self {
        case .all:
            return true
        case .expired:
            return status == .expired
        case .expiringSoon:
            return status == .critical || status == .warning
        case .fresh:
            return status == .good
        }
    }
}