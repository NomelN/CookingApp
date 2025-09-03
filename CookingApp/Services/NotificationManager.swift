import Foundation
import UserNotifications

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
                if let error = error {
                    print("⚠️ Notification permission error: \(error)")
                } else {
                    print("✅ Notification permission: \(granted)")
                    if granted {
                        // Configurer les catégories de notifications
                        self.setupNotificationCategories()
                    }
                }
            }
        }
    }
    
    func checkPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.hasPermission = settings.authorizationStatus == .authorized
                print("🔔 Notification status: \(settings.authorizationStatus.rawValue)")
                print("   Alert setting: \(settings.alertSetting.rawValue)")
                print("   Badge setting: \(settings.badgeSetting.rawValue)")
                print("   Sound setting: \(settings.soundSetting.rawValue)")
                
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
        print("✅ Notification categories configured")
    }
    
    func scheduleNotification(for product: Product, daysBeforeExpiration: Int = 1) {
        guard hasPermission else {
            print("❌ Notification permission not granted for \(product.name ?? "Unknown")")
            return
        }
        
        guard let expirationDate = product.expirationDate,
              let productName = product.name else { 
            print("❌ Missing expiration date or product name")
            return 
        }
        
        // Calculer la date de notification (à 10h00 pour être plus visible)
        guard let baseNotificationDate = Calendar.current.date(byAdding: .day, value: -daysBeforeExpiration, to: expirationDate) else {
            print("❌ Could not calculate notification date")
            return
        }
        
        var notificationDateComponents = Calendar.current.dateComponents([.year, .month, .day], from: baseNotificationDate)
        notificationDateComponents.hour = 9
        notificationDateComponents.minute = 0
        notificationDateComponents.timeZone = TimeZone.current
        
        guard let finalNotificationDate = Calendar.current.date(from: notificationDateComponents) else {
            print("❌ Could not create notification date")
            return
        }
        
        // Vérifier si la date de notification est dans le futur
        let now = Date()
        if finalNotificationDate <= now {
            print("⚠️ Notification date is in the past: \(finalNotificationDate) (now: \(now))")
            print("   Product: \(productName), expires: \(expirationDate), notify \(daysBeforeExpiration) days before")
            return
        }
        
        print("📅 Scheduling notification for \(productName):")
        print("   Expires: \(expirationDate)")
        print("   Notify: \(finalNotificationDate) (\(daysBeforeExpiration) days before)")
        
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
        content.badge = NSNumber(value: 1)
        content.categoryIdentifier = "EXPIRATION_REMINDER"
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: notificationDateComponents,
            repeats: false
        )
        
        let identifier = "\(product.id?.uuidString ?? UUID().uuidString)_\(daysBeforeExpiration)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Error scheduling notification: \(error)")
            } else {
                print("✅ Notification scheduled for \(productName) - \(daysBeforeExpiration) days before")
                print("   Notification date: \(finalNotificationDate)")
            }
        }
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
    }
    
    func removeAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    // Méthode de debug pour lister toutes les notifications programmées
    func listPendingNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            print("📋 Pending notifications: \(requests.count)")
            for request in requests {
                print("   - ID: \(request.identifier)")
                print("     Title: \(request.content.title)")
                print("     Body: \(request.content.body)")
                if let trigger = request.trigger as? UNCalendarNotificationTrigger,
                   let nextTriggerDate = trigger.nextTriggerDate() {
                    print("     Trigger date: \(nextTriggerDate)")
                }
                print("   ---")
            }
        }
    }
    
    // Méthode pour tester les notifications immédiatement
    func sendTestNotification() {
        print("🧪 Attempting to send test notification...")
        
        // Vérifier d'abord les permissions
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                print("   Permission status: \(settings.authorizationStatus.rawValue)")
                
                guard settings.authorizationStatus == .authorized else {
                    print("❌ No notification permission for test")
                    return
                }
                
                let content = UNMutableNotificationContent()
                content.title = "🧪 Test CookingApp"
                content.body = "Les notifications fonctionnent correctement !"
                content.sound = .default
                content.badge = 1
                
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false)
                let request = UNNotificationRequest(identifier: "test_notification_\(Date().timeIntervalSince1970)", content: content, trigger: trigger)
                
                UNUserNotificationCenter.current().add(request) { error in
                    if let error = error {
                        print("❌ Test notification error: \(error)")
                    } else {
                        print("✅ Test notification scheduled! Check in 3 seconds...")
                    }
                }
            }
        }
    }
    
    // Méthode pour nettoyer et reprogrammer toutes les notifications
    func cleanupAndRescheduleAllNotifications() {
        print("🧹 Cleaning up all notifications and rescheduling...")
        
        // Supprimer toutes les notifications existantes
        removeAllNotifications()
        
        // Re-programmer toutes les notifications actives
        // Cette méthode devrait être appelée depuis ProductsViewModel
        print("✅ Cleanup completed. Call scheduleAllNotifications for each active product.")
    }
    
    // Méthode pour forcer une notification test dans 10 secondes
    func sendImmediateTestNotification() {
        print("🧪 Sending immediate test notification...")
        print("⚠️  IMPORTANT: Mettez l'app en arrière-plan (bouton home) pour voir la notification !")
        
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                guard settings.authorizationStatus == .authorized else {
                    print("❌ No notification permission")
                    return
                }
                
                let content = UNMutableNotificationContent()
                content.title = "🍎 CookingApp Test"
                content.body = "✅ Les notifications fonctionnent ! Mettez l'app en arrière-plan pour les voir."
                content.sound = .default
                content.badge = 1
                content.categoryIdentifier = "EXPIRATION_REMINDER"
                
                // Déclencher dans 15 secondes pour laisser le temps de mettre en arrière-plan
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 15, repeats: false)
                let request = UNNotificationRequest(
                    identifier: "background_test_\(Date().timeIntervalSince1970)", 
                    content: content, 
                    trigger: trigger
                )
                
                UNUserNotificationCenter.current().add(request) { error in
                    if let error = error {
                        print("❌ Background test notification error: \(error)")
                    } else {
                        print("✅ Background test notification scheduled! METTEZ L'APP EN ARRIÈRE-PLAN dans 5 secondes...")
                    }
                }
            }
        }
    }
    
    // Méthode pour vérifier et corriger les notifications d'un produit
    func debugNotificationsForProduct(_ product: Product) {
        guard let productId = product.id?.uuidString,
              let productName = product.name,
              let expirationDate = product.expirationDate else {
            print("❌ Invalid product data for notifications")
            return
        }
        
        print("🔍 Debug notifications for product: \(productName)")
        print("   ID: \(productId)")
        print("   Expires: \(expirationDate)")
        print("   Days until expiration: \(Calendar.current.dateComponents([.day], from: Date(), to: expirationDate).day ?? 0)")
        
        // Lister les notifications programmées pour ce produit
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let productNotifications = requests.filter { $0.identifier.contains(productId) }
            print("   📋 Found \(productNotifications.count) pending notifications:")
            
            for request in productNotifications {
                print("     - \(request.identifier)")
                if let trigger = request.trigger as? UNCalendarNotificationTrigger,
                   let nextDate = trigger.nextTriggerDate() {
                    print("       Trigger: \(nextDate)")
                }
            }
        }
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    // Cette méthode permet d'afficher les notifications même quand l'app est au premier plan
    func userNotificationCenter(_ center: UNUserNotificationCenter, 
                               willPresent notification: UNNotification, 
                               withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("🔔 Notification will present: \(notification.request.identifier)")
        print("   Title: \(notification.request.content.title)")
        print("   Body: \(notification.request.content.body)")
        
        // Afficher la notification même en premier plan avec son, alerte et badge
        completionHandler([.alert, .sound, .badge])
    }
    
    // Cette méthode est appelée quand l'utilisateur tape sur la notification
    func userNotificationCenter(_ center: UNUserNotificationCenter, 
                               didReceive response: UNNotificationResponse, 
                               withCompletionHandler completionHandler: @escaping () -> Void) {
        print("🔔 Notification tapped: \(response.notification.request.identifier)")
        print("   Action: \(response.actionIdentifier)")
        
        // Gérer les actions personnalisées
        switch response.actionIdentifier {
        case "VIEW_PRODUCT":
            print("👀 User wants to view product")
            // TODO: Naviguer vers le produit
        case "MARK_USED":
            print("✅ User wants to mark product as used")
            // TODO: Marquer le produit comme utilisé
        case UNNotificationDefaultActionIdentifier:
            print("📱 User tapped the notification")
            // TODO: Ouvrir l'app sur la liste des produits
        default:
            break
        }
        
        completionHandler()
    }
}

struct NotificationSettings {
    var sevenDaysBefore: Bool = true
    var threeDaysBefore: Bool = true
    var oneDayBefore: Bool = true
    var expirationDay: Bool = true
    
    static let shared = NotificationSettings()
}