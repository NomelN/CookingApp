import Foundation
import CoreData
import SwiftUI
import Combine

class ProductsViewModel: ObservableObject {
    private let persistenceController = PersistenceController.shared
    private let notificationManager = NotificationManager.shared
    private var refreshTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    @Published var products: [Product] = []
    @Published var searchText = ""
    @Published var lastRefresh = Date()
    @Published var selectedFilter: ProductFilter = .all
    
    var filteredProducts: [Product] {
        let baseProducts = products.filter { !$0.isUsed }
        
        // Appliquer le filtre par statut
        let statusFilteredProducts = baseProducts.filter { product in
            selectedFilter.matches(product, from: lastRefresh)
        }
        
        // Appliquer le filtre de recherche
        if searchText.isEmpty {
            return statusFilteredProducts
        } else {
            return statusFilteredProducts.filter { product in
                product.name?.localizedCaseInsensitiveContains(searchText) ?? false
            }
        }
    }
    
    var sortedProducts: [Product] {
        filteredProducts.sorted { product1, product2 in
            guard let date1 = product1.expirationDate,
                  let date2 = product2.expirationDate else {
                return false
            }
            return date1 < date2
        }
    }
    
    init() {
        fetchProducts()
        startAutoRefresh()
        
        // Observer pour rafraîchir quand l'app revient au premier plan
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { _ in
                DispatchQueue.main.async {
                    self.lastRefresh = Date()
                    self.objectWillChange.send()
                }
            }
            .store(in: &cancellables)
    }
    
    deinit {
        stopAutoRefresh()
    }
    
    private func startAutoRefresh() {
        // Rafraîchir toutes les heures pour recalculer les jours restants
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { _ in
            DispatchQueue.main.async {
                self.lastRefresh = Date()
                self.objectWillChange.send()
            }
        }
        
        // Rafraîchir à minuit pour le changement de jour
        let midnight = Calendar.current.startOfDay(for: Date().addingTimeInterval(86400))
        let timeUntilMidnight = midnight.timeIntervalSince(Date())
        
        DispatchQueue.main.asyncAfter(deadline: .now() + timeUntilMidnight) {
            self.startDailyRefresh()
        }
    }
    
    private func startDailyRefresh() {
        // Timer quotidien à minuit
        Timer.scheduledTimer(withTimeInterval: 86400, repeats: true) { _ in
            DispatchQueue.main.async {
                self.lastRefresh = Date()
                self.objectWillChange.send()
            }
        }
    }
    
    private func stopAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
    func fetchProducts() {
        let request: NSFetchRequest<Product> = Product.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Product.expirationDate, ascending: true)]
        request.predicate = NSPredicate(format: "isUsed == NO")
        request.fetchBatchSize = 20 // Optimisation pour les grandes listes
        
        do {
            products = try persistenceController.container.viewContext.fetch(request)
        } catch {
            print("Error fetching products: \(error)")
            products = []
        }
    }
    
    func addProduct(name: String, expirationDate: Date, description: String?, imageData: Data?) {
        let context = persistenceController.container.viewContext
        
        let product = Product(context: context)
        product.id = UUID()
        product.name = name
        product.expirationDate = expirationDate
        product.productDescription = description
        product.imageData = imageData
        product.createdAt = Date()
        product.isUsed = false
        
        persistenceController.save()
        fetchProducts()
        
        notificationManager.scheduleAllNotifications(for: product, settings: NotificationSettings.shared)
    }
    
    func updateProduct(_ product: Product, name: String, expirationDate: Date, description: String?, imageData: Data?) {
        product.name = name
        product.expirationDate = expirationDate
        product.productDescription = description
        if let imageData = imageData {
            product.imageData = imageData
        }
        
        persistenceController.save()
        fetchProducts()
        
        notificationManager.scheduleAllNotifications(for: product, settings: NotificationSettings.shared)
    }
    
    func markAsUsed(_ product: Product) {
        product.isUsed = true
        notificationManager.removeNotifications(for: product)
        persistenceController.save()
        fetchProducts()
    }
    
    func deleteProduct(_ product: Product) {
        let context = persistenceController.container.viewContext
        notificationManager.removeNotifications(for: product)
        context.delete(product)
        persistenceController.save()
        fetchProducts()
    }
    
    func deleteProducts(at offsets: IndexSet) {
        let context = persistenceController.container.viewContext
        
        for index in offsets {
            context.delete(sortedProducts[index])
        }
        
        persistenceController.save()
        fetchProducts()
    }
    
    func refreshExpirationCalculations() {
        DispatchQueue.main.async {
            self.lastRefresh = Date()
            self.objectWillChange.send()
        }
    }
    
    func forceRefreshView() {
        DispatchQueue.main.async {
            self.lastRefresh = Date()
            self.products = self.products
            self.objectWillChange.send()
        }
    }
}