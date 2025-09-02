import Foundation
import UserNotifications

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var hasPermission = false
    
    init() {
        checkPermission()
    }
    
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                self.hasPermission = granted
            }
        }
    }
    
    func checkPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.hasPermission = settings.authorizationStatus == .authorized
            }
        }
    }
    
    func scheduleNotification(for product: Product, daysBeforeExpiration: Int = 1) {
        guard hasPermission else {
            print("Notification permission not granted")
            return
        }
        
        guard let expirationDate = product.expirationDate,
              let productName = product.name else { 
            print("Missing expiration date or product name")
            return 
        }
        
        // Calculer la date de notification (à 10h00 pour être plus visible)
        var notificationDateComponents = Calendar.current.dateComponents([.year, .month, .day], from: expirationDate)
        notificationDateComponents.day! -= daysBeforeExpiration
        notificationDateComponents.hour = 10
        notificationDateComponents.minute = 0
        
        guard let notificationDate = Calendar.current.date(from: notificationDateComponents),
              notificationDate > Date() else { 
            print("Notification date is in the past: \(String(describing: Calendar.current.date(from: notificationDateComponents)))")
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
                print("   Notification date: \(notificationDate)")
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
        guard hasPermission else {
            print("No notification permission")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "🧪 Test CookingApp"
        content.body = "Les notifications fonctionnent correctement !"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        let request = UNNotificationRequest(identifier: "test_notification", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Test notification error: \(error)")
            } else {
                print("✅ Test notification sent!")
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