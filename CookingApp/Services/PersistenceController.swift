import CoreData
import Foundation

class PersistenceController: ObservableObject {
    static let shared = PersistenceController()
    
    let container: NSPersistentContainer
    
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "CookingApp")
        
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                print("❌ Core Data error: \(error), \(error.userInfo)")
                // Ne pas faire crasher l'app, juste logger l'erreur
            } else {
                print("✅ Core Data loaded successfully")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    func save() {
        let context = container.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
                print("✅ Core Data saved successfully")
            } catch {
                let nsError = error as NSError
                print("❌ Core Data save error: \(nsError), \(nsError.userInfo)")
                // Ne pas faire crasher l'app
            }
        }
    }
}

extension PersistenceController {
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let viewContext = controller.container.viewContext
        
        for i in 0..<5 {
            let product = Product(context: viewContext)
            product.id = UUID()
            product.name = "Produit d'exemple \(i + 1)"
            product.expirationDate = Calendar.current.date(byAdding: .day, value: i - 2, to: Date())
            product.productDescription = "Description du produit \(i + 1)"
            product.createdAt = Date()
            product.isUsed = false
        }
        
        do {
            try viewContext.save()
            print("✅ Preview data created successfully")
        } catch {
            let nsError = error as NSError
            print("❌ Preview data creation error: \(nsError), \(nsError.userInfo)")
        }
        
        return controller
    }()
}