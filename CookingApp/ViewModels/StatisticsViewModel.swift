import Foundation
import CoreData
import SwiftUI

class StatisticsViewModel: ObservableObject {
    private let persistenceController = PersistenceController.shared
    
    @Published var statistics = ProductStatistics()
    @Published var consumedProducts: [Product] = []
    @Published var recentConsumedProducts: [Product] = []
    @Published var currentPeriod: TimePeriod = .month
    
    init() {
        fetchStatistics()
    }
    
    func fetchStatistics() {
        fetchAllProducts()
        fetchConsumedProducts()
        calculateStatistics()
    }
    
    func updatePeriod(_ period: TimePeriod) {
        currentPeriod = period
        fetchStatistics()
    }
    
    private func fetchAllProducts() {
        let context = persistenceController.container.viewContext
        let request: NSFetchRequest<Product> = Product.fetchRequest()
        
        // Filtrer par période si nécessaire
        if currentPeriod != .year {
            let startDate = Calendar.current.date(byAdding: .day, value: currentPeriod.value, to: Date()) ?? Date()
            request.predicate = NSPredicate(format: "createdAt >= %@", startDate as NSDate)
        }
        
        do {
            let allProducts = try context.fetch(request)
            calculateStatisticsFromProducts(allProducts)
        } catch {
            print("Error fetching products for statistics: \(error)")
            statistics = ProductStatistics()
        }
    }
    
    private func fetchConsumedProducts() {
        let context = persistenceController.container.viewContext
        let request: NSFetchRequest<Product> = Product.fetchRequest()
        
        // Filtrer les produits consommés
        var predicates = [NSPredicate(format: "isUsed == YES")]
        
        // Filtrer par période
        if currentPeriod != .year {
            let startDate = Calendar.current.date(byAdding: .day, value: currentPeriod.value, to: Date()) ?? Date()
            predicates.append(NSPredicate(format: "createdAt >= %@", startDate as NSDate))
        }
        
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Product.createdAt, ascending: false)]
        
        do {
            consumedProducts = try context.fetch(request)
            recentConsumedProducts = Array(consumedProducts.prefix(10))
        } catch {
            print("Error fetching consumed products: \(error)")
            consumedProducts = []
            recentConsumedProducts = []
        }
    }
    
    private func calculateStatisticsFromProducts(_ products: [Product]) {
        var stats = ProductStatistics()
        
        stats.totalProducts = products.count
        
        for product in products {
            if product.isUsed {
                stats.consumedProducts += 1
            } else {
                stats.activeProducts += 1
                
                let daysUntilExpiration = product.daysUntilExpiration
                
                switch product.expirationStatus {
                case .good:
                    stats.freshProducts += 1
                case .warning, .critical:
                    stats.expiringProducts += 1
                case .expired:
                    stats.expiredProducts += 1
                }
            }
        }
        
        DispatchQueue.main.async {
            self.statistics = stats
        }
    }
    
    private func calculateStatistics() {
        // Cette méthode peut être appelée après fetchAllProducts et fetchConsumedProducts
        // pour s'assurer que toutes les données sont à jour
    }
}

// MARK: - Structure des statistiques
struct ProductStatistics {
    var totalProducts: Int = 0
    var activeProducts: Int = 0
    var consumedProducts: Int = 0
    var expiredProducts: Int = 0
    var expiringProducts: Int = 0 // Critique + Attention
    var freshProducts: Int = 0
    
    // Statistiques dérivées
    var wasteRate: Double {
        let totalProcessed = consumedProducts + expiredProducts
        return totalProcessed > 0 ? Double(expiredProducts) / Double(totalProcessed) * 100 : 0
    }
    
    var consumptionRate: Double {
        let totalProcessed = consumedProducts + expiredProducts
        return totalProcessed > 0 ? Double(consumedProducts) / Double(totalProcessed) * 100 : 0
    }
    
    var activeRate: Double {
        return totalProducts > 0 ? Double(activeProducts) / Double(totalProducts) * 100 : 0
    }
}