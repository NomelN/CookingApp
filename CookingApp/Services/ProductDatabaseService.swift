import Foundation

class ProductDatabaseService {
    static let shared = ProductDatabaseService()
    
    private let rateLimiter = RateLimiter(maxRequests: 90, timeWindow: 60) // 90/min pour rester sous la limite
    private let urlSession: URLSession
    
    private init() {
        // Configuration URLSession avec timeout pour éviter les hangs
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 10.0 // 10 secondes
        configuration.timeoutIntervalForResource = 30.0 // 30 secondes total
        self.urlSession = URLSession(configuration: configuration)
    }
    
    func fetchProductInfo(barcode: String, completion: @escaping (ProductInfo?) -> Void) {
        // Vérifier le rate limiting
        guard rateLimiter.canMakeRequest() else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.fetchProductInfo(barcode: barcode, completion: completion)
            }
            return
        }
        
        let urlString = "https://world.openfoodfacts.org/api/v0/product/\(barcode).json"
        
        guard let url = URL(string: urlString) else {
            DispatchQueue.main.async {
                completion(nil)
            }
            return
        }
        
        
        // Créer une requête avec User-Agent personnalisé
        var request = URLRequest(url: url)
        request.setValue("CookingApp/1.0 (nomelmickael51@gmail.com)", forHTTPHeaderField: "User-Agent")
        
        urlSession.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(nil)
                    return
                }
                
                // Vérifier la réponse HTTP
                if let httpResponse = response as? HTTPURLResponse {
                    switch httpResponse.statusCode {
                    case 200:
                        break // OK
                    case 429, 404:
                        completion(nil)
                        return
                    default:
                        completion(nil)
                        return
                    }
                }
                
                guard let data = data else {
                    completion(nil)
                    return
                }
                
                do {
                    let result = try JSONDecoder().decode(OpenFoodFactsResponse.self, from: data)
                    
                    if result.status == 1, let product = result.product {
                        let productInfo = ProductInfo(
                            displayName: product.displayName,
                            productDescription: product.productDescription,
                            bestImageUrl: product.bestImageUrl
                        )
                        completion(productInfo)
                    } else {
                        completion(nil)
                    }
                } catch {
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
    
    // URL d'image optimisée - utilise .org au lieu de .net pour éviter les erreurs de connexion
    var bestImageUrl: String? {
        let imageUrl = imageFrontSmallUrl ?? imageFrontUrl ?? self.imageUrl
        // Remplacer .net par .org pour les URLs d'images si nécessaire
        return imageUrl?.replacingOccurrences(of: "openfoodfacts.net", with: "openfoodfacts.org")
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