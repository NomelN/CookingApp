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
        guard let expirationDate = product.expirationDate,
              let productName = product.name else { return }
        
        let notificationDate = Calendar.current.date(byAdding: .day, value: -daysBeforeExpiration, to: expirationDate)
        
        guard let notificationDate = notificationDate,
              notificationDate > Date() else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Produit bientôt expiré"
        
        if daysBeforeExpiration == 0 {
            content.body = "\(productName) expire aujourd'hui !"
        } else if daysBeforeExpiration == 1 {
            content.body = "\(productName) expire demain."
        } else {
            content.body = "\(productName) expire dans \(daysBeforeExpiration) jours."
        }
        
        content.sound = .default
        content.badge = 1
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: notificationDate),
            repeats: false
        )
        
        let identifier = "\(product.id?.uuidString ?? UUID().uuidString)_\(daysBeforeExpiration)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
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
}

struct NotificationSettings {
    var sevenDaysBefore: Bool = true
    var threeDaysBefore: Bool = true
    var oneDayBefore: Bool = true
    var expirationDay: Bool = true
    
    static let shared = NotificationSettings()
}