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
            // Si la date est passée, programmer pour demain à 9h si c'est une notification d'expiration
            if daysBeforeExpiration <= 1 {
                var tomorrowComponents = Calendar.current.dateComponents([.year, .month, .day], from: now.addingTimeInterval(86400))
                tomorrowComponents.hour = 9
                tomorrowComponents.minute = 0
                tomorrowComponents.timeZone = TimeZone.current
                
                guard let tomorrowDate = Calendar.current.date(from: tomorrowComponents) else {
                    return
                }
                notificationDateComponents = tomorrowComponents
            } else {
                return // Ignorer les notifications trop anciennes (7j, 3j)
            }
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
        
        // iOS va incrémenter automatiquement le badge à chaque notification reçue
        content.badge = NSNumber(value: 1)
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: notificationDateComponents,
            repeats: false
        )
        
        let identifier = "\(product.id?.uuidString ?? UUID().uuidString)_\(daysBeforeExpiration)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { _ in
            // Le badge sera géré automatiquement par iOS lors de la réception
        }
    }
    
    func sendImmediateNotification(for product: Product, daysUntilExpiration: Int) {
        guard hasPermission else { return }
        guard let productName = product.name else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "🍎 Attention à vos produits !"
        
        if daysUntilExpiration == 0 {
            content.body = "⚠️ \(productName) expire aujourd'hui !"
        } else if daysUntilExpiration == 1 {
            content.body = "🟡 \(productName) expire demain !"
        } else if daysUntilExpiration == 3 {
            content.body = "🟠 \(productName) expire dans 3 jours !"
        } else if daysUntilExpiration == 7 {
            content.body = "🟠 \(productName) expire dans 7 jours !"
        } else {
            content.body = "🟠 \(productName) expire bientôt !"
        }
        
        content.sound = .default
        content.categoryIdentifier = "EXPIRATION_REMINDER"
        content.badge = NSNumber(value: 1) // iOS va incrémenter le badge
        
        // Notification immédiate (dans 1 seconde)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let identifier = "\(product.id?.uuidString ?? UUID().uuidString)_immediate"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { _ in
            // Le badge sera géré automatiquement par iOS
        }
    }
    
    func scheduleAllNotifications(for product: Product, settings: NotificationSettings) {
        removeNotifications(for: product)
        
        guard !product.isUsed else { return }
        
        // Vérifier si le produit nécessite une notification immédiate
        let daysUntilExpiration = product.daysUntilExpiration
        
        // Notification immédiate si le produit est dans un intervalle critique
        if daysUntilExpiration == 7 || daysUntilExpiration == 3 || daysUntilExpiration == 1 || daysUntilExpiration == 0 {
            sendImmediateNotification(for: product, daysUntilExpiration: daysUntilExpiration)
        }
        
        // Cas spécial : si le produit est déjà expiré (daysUntilExpiration < 0)
        if daysUntilExpiration < 0 {
            sendImmediateNotification(for: product, daysUntilExpiration: 0) // Traiter comme "expire aujourd'hui"
        }
        
        // Programmer les notifications futures normalement
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
            "\(productId)_0",
            "\(productId)_immediate"
        ]
        
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
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
        // Afficher la notification même en premier plan avec son, alerte ET badge
        // iOS va automatiquement incrémenter le badge
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
    
    func clearAppBadge() {
        DispatchQueue.main.async {
            UIApplication.shared.applicationIconBadgeNumber = 0
        }
        // Supprimer aussi les notifications délivrées pour éviter l'accumulation
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
    
    // Fonction de debug pour vérifier les notifications programmées (utilisable manuellement si besoin)
    func debugNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            // Silencieux en production - décommentez les lignes ci-dessous pour débugger
            /*
            print("=== DEBUG NOTIFICATIONS ===")
            print("Nombre total de notifications: \(requests.count)")
            
            for request in requests {
                if let trigger = request.trigger as? UNCalendarNotificationTrigger,
                   let triggerDate = Calendar.current.nextDate(after: Date(), matching: trigger.dateComponents, matchingPolicy: .nextTime) {
                    print("ID: \(request.identifier)")
                    print("Titre: \(request.content.title)")
                    print("Corps: \(request.content.body)")
                    print("Date programmée: \(triggerDate)")
                    print("---")
                }
            }
            */
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