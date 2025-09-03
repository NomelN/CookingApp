import Foundation

class ProductDatabaseService {
    static let shared = ProductDatabaseService()
    
    private let rateLimiter = RateLimiter(maxRequests: 90, timeWindow: 60) // 90/min pour rester sous la limite
    
    private init() {}
    
    func fetchProductInfo(barcode: String, completion: @escaping (ProductInfo?) -> Void) {
        // Vérifier le rate limiting
        guard rateLimiter.canMakeRequest() else {
            print("⚠️ Rate limit atteint, requête reportée")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.fetchProductInfo(barcode: barcode, completion: completion)
            }
            return
        }
        
        let urlString = "https://world.openfoodfacts.net/api/v0/product/\(barcode).json"
        
        guard let url = URL(string: urlString) else {
            DispatchQueue.main.async {
                completion(nil)
            }
            return
        }
        
        print("🔍 Recherche du produit avec le code-barres: \(barcode)")
        
        // Créer une requête avec User-Agent personnalisé
        var request = URLRequest(url: url)
        request.setValue("CookingApp/1.0 (nomelmickael51@gmail.com)", forHTTPHeaderField: "User-Agent")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                // Gestion d'erreurs réseau améliorée
                if let error = error {
                    print("❌ Erreur réseau: \(error.localizedDescription)")
                    completion(nil)
                    return
                }
                
                // Vérifier la réponse HTTP
                if let httpResponse = response as? HTTPURLResponse {
                    switch httpResponse.statusCode {
                    case 200:
                        break // OK
                    case 429:
                        print("⚠️ Rate limit dépassé côté serveur")
                        completion(nil)
                        return
                    case 404:
                        print("❌ Produit non trouvé (404)")
                        completion(nil)
                        return
                    default:
                        print("❌ Erreur HTTP \(httpResponse.statusCode)")
                        completion(nil)
                        return
                    }
                }
                
                guard let data = data else {
                    print("❌ Aucune donnée reçue")
                    completion(nil)
                    return
                }
                
                do {
                    let result = try JSONDecoder().decode(OpenFoodFactsResponse.self, from: data)
                    
                    if result.status == 1, let product = result.product {
                        print("✅ Produit trouvé: \(product.displayName ?? "Sans nom")")
                        let productInfo = ProductInfo(
                            displayName: product.displayName,
                            productDescription: product.productDescription,
                            bestImageUrl: product.bestImageUrl
                        )
                        completion(productInfo)
                    } else {
                        print("❌ Produit non trouvé dans la base de données (status: \(result.status))")
                        completion(nil)
                    }
                } catch {
                    print("❌ Erreur de décodage JSON: \(error)")
                    completion(nil)
                }
            }
        }.resume()
    }
}

// Modèles pour décoder la réponse JSON
struct OpenFoodFactsResponse: Codable {
    let status: Int
    let statusVerbose: String?
    let product: OpenFoodFactsProduct?
    
    enum CodingKeys: String, CodingKey {
        case status
        case statusVerbose = "status_verbose"
        case product
    }
}

struct OpenFoodFactsProduct: Codable {
    let productName: String?
    let productNameFr: String?
    let brands: String?
    let categories: String?
    let imageUrl: String?
    let imageFrontUrl: String?
    let imageFrontSmallUrl: String?
    let nutriscoreGrade: String?
    let ecoscore: String?
    let ingredientsText: String?
    
    enum CodingKeys: String, CodingKey {
        case productName = "product_name"
        case productNameFr = "product_name_fr"
        case brands, categories
        case imageUrl = "image_url"
        case imageFrontUrl = "image_front_url"
        case imageFrontSmallUrl = "image_front_small_url"
        case nutriscoreGrade = "nutriscore_grade"
        case ecoscore = "ecoscore_grade"
        case ingredientsText = "ingredients_text"
    }
    
    // Nom du produit avec préférence pour le français
    var displayName: String? {
        return productNameFr ?? productName
    }
    
    // URL d'image optimisée
    var bestImageUrl: String? {
        return imageFrontSmallUrl ?? imageFrontUrl ?? imageUrl
    }
    
    // Description combinée pour l'utilisateur
    var productDescription: String? {
        var components: [String] = []
        
        if let brands = brands, !brands.isEmpty {
            components.append("Marque: \(brands)")
        }
        
        if let categories = categories, !categories.isEmpty {
            let categoryList = categories.split(separator: ",").prefix(3).map { $0.trimmingCharacters(in: .whitespaces) }.joined(separator: ", ")
            components.append("Catégorie: \(categoryList)")
        }
        
        if let nutriscore = nutriscoreGrade, !nutriscore.isEmpty {
            components.append("Nutri-Score: \(nutriscore.uppercased())")
        }
        
        return components.isEmpty ? nil : components.joined(separator: " • ")
    }
}

// Structure simplifiée pour l'interface utilisateur
struct ProductInfo {
    let displayName: String?
    let productDescription: String?
    let bestImageUrl: String?
}

// Rate Limiter pour respecter les limites de l'API Open Food Facts
class RateLimiter {
    private let maxRequests: Int
    private let timeWindow: TimeInterval
    private var requestTimes: [Date] = []
    private let queue = DispatchQueue(label: "rateLimiter", attributes: .concurrent)
    
    init(maxRequests: Int, timeWindow: TimeInterval) {
        self.maxRequests = maxRequests
        self.timeWindow = timeWindow
    }
    
    func canMakeRequest() -> Bool {
        return queue.sync(flags: .barrier) {
            let now = Date()
            let cutoff = now.addingTimeInterval(-timeWindow)
            
            // Nettoyer les anciennes requêtes
            requestTimes = requestTimes.filter { $0 > cutoff }
            
            // Vérifier si on peut faire une nouvelle requête
            if requestTimes.count < maxRequests {
                requestTimes.append(now)
                return true
            }
            
            return false
        }
    }
}