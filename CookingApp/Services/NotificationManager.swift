import Foundation
import UserNotifications
import UIKit

class NotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    
    @Published var hasPermission = false
    
    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        checkPermission()
    }
    
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                self.hasPermission = granted
                if granted {
                    // Configurer les catégories de notifications
                    self.setupNotificationCategories()
                }
            }
        }
    }
    
    func checkPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.hasPermission = settings.authorizationStatus == .authorized
                
                if settings.authorizationStatus == .authorized && settings.alertSetting == .enabled {
                    self.setupNotificationCategories()
                }
            }
        }
    }
    
    private func setupNotificationCategories() {
        let viewAction = UNNotificationAction(
            identifier: "VIEW_PRODUCT",
            title: "Voir le produit",
            options: [.foreground]
        )
        
        let markUsedAction = UNNotificationAction(
            identifier: "MARK_USED",
            title: "Marquer comme utilisé",
            options: []
        )
        
        let expirationCategory = UNNotificationCategory(
            identifier: "EXPIRATION_REMINDER",
            actions: [viewAction, markUsedAction],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([expirationCategory])
    }
    
    func scheduleNotification(for product: Product, daysBeforeExpiration: Int = 1) {
        guard hasPermission else { return }
        
        guard let expirationDate = product.expirationDate,
              let productName = product.name else { return }
        
        // Calculer la date de notification (à 9h00)
        guard let baseNotificationDate = Calendar.current.date(byAdding: .day, value: -daysBeforeExpiration, to: expirationDate) else {
            return
        }
        
        var notificationDateComponents = Calendar.current.dateComponents([.year, .month, .day], from: baseNotificationDate)
        notificationDateComponents.hour = 9
        notificationDateComponents.minute = 0
        notificationDateComponents.timeZone = TimeZone.current
        
        guard let finalNotificationDate = Calendar.current.date(from: notificationDateComponents) else {
            return
        }
        
        // Vérifier si la date de notification est dans le futur
        let now = Date()
        if finalNotificationDate <= now {
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "🍎 Attention à vos produits !"
        
        if daysBeforeExpiration == 0 {
            content.body = "⚠️ \(productName) expire aujourd'hui !"
        } else if daysBeforeExpiration == 1 {
            content.body = "🟡 \(productName) expire demain."
        } else {
            content.body = "🟠 \(productName) expire dans \(daysBeforeExpiration) jours."
        }
        
        content.sound = .default
        content.categoryIdentifier = "EXPIRATION_REMINDER"
        
        // Calculer le badge basé sur les notifications programmées pour aujourd'hui et les prochains jours
        calculateBadgeForNotification(content: content, currentDate: Date())
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: notificationDateComponents,
            repeats: false
        )
        
        let identifier = "\(product.id?.uuidString ?? UUID().uuidString)_\(daysBeforeExpiration)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { _ in }
    }
    
    func scheduleAllNotifications(for product: Product, settings: NotificationSettings) {
        removeNotifications(for: product)
        
        guard !product.isUsed else { return }
        
        if settings.sevenDaysBefore {
            scheduleNotification(for: product, daysBeforeExpiration: 7)
        }
        
        if settings.threeDaysBefore {
            scheduleNotification(for: product, daysBeforeExpiration: 3)
        }
        
        if settings.oneDayBefore {
            scheduleNotification(for: product, daysBeforeExpiration: 1)
        }
        
        if settings.expirationDay {
            scheduleNotification(for: product, daysBeforeExpiration: 0)
        }
    }
    
    func removeNotifications(for product: Product) {
        guard let productId = product.id?.uuidString else { return }
        
        let identifiers = [
            "\(productId)_7",
            "\(productId)_3",
            "\(productId)_1",
            "\(productId)_0"
        ]
        
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
        
        // Mettre à jour le badge après suppression
        updateAppBadgeCount()
    }
    
    func removeAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        // Effacer le badge quand toutes les notifications sont supprimées
        clearAppBadge()
    }
    
    
    // MARK: - UNUserNotificationCenterDelegate
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, 
                               willPresent notification: UNNotification, 
                               withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Incrémenter le badge quand une notification arrive
        DispatchQueue.main.async {
            let currentBadge = UIApplication.shared.applicationIconBadgeNumber
            UIApplication.shared.applicationIconBadgeNumber = currentBadge + 1
        }
        
        // Afficher la notification même en premier plan avec son, alerte et badge
        completionHandler([.alert, .sound, .badge])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, 
                               didReceive response: UNNotificationResponse, 
                               withCompletionHandler completionHandler: @escaping () -> Void) {
        // Gérer les actions personnalisées
        switch response.actionIdentifier {
        case "VIEW_PRODUCT":
            // TODO: Naviguer vers le produit
            break
        case "MARK_USED":
            // TODO: Marquer le produit comme utilisé
            break
        case UNNotificationDefaultActionIdentifier:
            // TODO: Ouvrir l'app sur la liste des produits
            break
        default:
            break
        }
        
        completionHandler()
    }
    
    // MARK: - Badge Management
    
    private func calculateBadgeForNotification(content: UNMutableNotificationContent, currentDate: Date) {
        // Laisser iOS gérer l'incrémentation automatique avec la valeur 1
        content.badge = NSNumber(value: 1)
    }
    
    private func calculateAndSetBadgeCount(for content: UNMutableNotificationContent) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            // Compter les notifications uniques (par produit)
            let uniqueProductIds = Set(requests.compactMap { request in
                request.identifier.components(separatedBy: "_").first
            })
            
            let badgeCount = uniqueProductIds.count + 1 // +1 pour la nouvelle notification
            content.badge = NSNumber(value: badgeCount)
        }
    }
    
    func clearAppBadge() {
        DispatchQueue.main.async {
            UIApplication.shared.applicationIconBadgeNumber = 0
        }
        // Supprimer aussi les notifications délivrées pour éviter l'accumulation
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
    
    func updateAppBadgeCount() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            // Compter les notifications uniques (par produit)
            let uniqueProductIds = Set(requests.compactMap { request in
                request.identifier.components(separatedBy: "_").first
            })
            
            DispatchQueue.main.async {
                UIApplication.shared.applicationIconBadgeNumber = uniqueProductIds.count
            }
        }
    }
}

struct NotificationSettings {
    var sevenDaysBefore: Bool = true
    var threeDaysBefore: Bool = true
    var oneDayBefore: Bool = true
    var expirationDay: Bool = true
    
    static let shared = NotificationSettings()
}