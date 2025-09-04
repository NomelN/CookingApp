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
        notificationDateComponents.timeZone = nil
        
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
                tomorrowComponents.timeZone = nil
                
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
        
        // Laisser iOS gérer le badge automatiquement
        content.badge = nil
        
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
        
        // Titre totalement unique pour chaque notification (inclure nom du produit)
        if daysUntilExpiration == 0 {
            content.title = "⚠️ \(productName) - Expiré"
            content.body = "Ce produit expire aujourd'hui !"
        } else if daysUntilExpiration == 1 {
            content.title = "🟡 \(productName) - 1 jour"
            content.body = "Ce produit expire demain"
        } else if daysUntilExpiration == 3 {
            content.title = "🟠 \(productName) - 3 jours"
            content.body = "Ce produit expire dans 3 jours"
        } else if daysUntilExpiration == 7 {
            content.title = "🟠 \(productName) - 7 jours" 
            content.body = "Ce produit expire dans 7 jours"
        } else {
            content.title = "🍎 \(productName) - Attention"
            content.body = "Ce produit expire bientôt"
        }
        
        content.sound = .default
        content.categoryIdentifier = "EXPIRATION_REMINDER"
        content.badge = nil
        // Éviter le regroupement en donnant un threadIdentifier unique
        content.threadIdentifier = product.id?.uuidString ?? UUID().uuidString
        
        // Échelonner légèrement les notifications pour éviter la collision
        let delay = Double.random(in: 0.1...2.0)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        let identifier = "\(product.id?.uuidString ?? UUID().uuidString)_immediate_\(daysUntilExpiration)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Erreur lors de l'envoi de la notification immédiate: \(error)")
            }
        }
    }
    
    func sendImmediateNotificationsForAllProducts(products: [Product]) {
        // Grouper les produits par nombre de jours restants
        let activeProducts = products.filter { !$0.isUsed }
        let groupedProducts = Dictionary(grouping: activeProducts) { product in
            max(0, product.daysUntilExpiration) // Traiter les négatifs comme 0
        }
        
        // Envoyer une notification pour chaque groupe de produits
        for (daysUntil, productsInGroup) in groupedProducts {
            // Pour chaque intervalle critique
            if daysUntil == 7 || daysUntil == 3 || daysUntil == 1 || daysUntil == 0 {
                for product in productsInGroup {
                    sendImmediateNotification(for: product, daysUntilExpiration: daysUntil)
                }
            }
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
        completionHandler([.alert, .sound, .badge])
        
        // Incrémenter manuellement le badge car willPresent peut ne pas le faire
        DispatchQueue.main.async {
            let currentBadge = UIApplication.shared.applicationIconBadgeNumber
            UIApplication.shared.applicationIconBadgeNumber = currentBadge + 1
        }
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