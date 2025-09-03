import Foundation

class ProductDatabaseService {
    static let shared = ProductDatabaseService()
    
    private init() {}
    
    func fetchProductInfo(barcode: String, completion: @escaping (ProductInfo?) -> Void) {
        // Exemple avec Open Food Facts
        let urlString = "https://world.openfoodfacts.org/api/v0/product/\(barcode).json"
        
        guard let url = URL(string: urlString) else {
            DispatchQueue.main.async {
                completion(nil)
            }
            return
        }
        
        print("🔍 Recherche du produit avec le code-barres: \(barcode)")
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                guard let data = data, error == nil else {
                    print("❌ Erreur réseau: \(error?.localizedDescription ?? "Unknown error")")
                    completion(nil)
                    return
                }
                
                do {
                    let result = try JSONDecoder().decode(OpenFoodFactsResponse.self, from: data)
                    
                    if let product = result.product {
                        print("✅ Produit trouvé: \(product.productName ?? "Sans nom")")
                        // Convertir OpenFoodFactsProduct vers ProductInfo
                        let productInfo = ProductInfo(
                            displayName: product.displayName,
                            productDescription: product.productDescription,
                            bestImageUrl: product.bestImageUrl
                        )
                        completion(productInfo)
                    } else {
                        print("❌ Produit non trouvé dans la base de données")
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