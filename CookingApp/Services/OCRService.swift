import Vision
import UIKit
import Foundation

class OCRService: ObservableObject {
    static let shared = OCRService()
    
    private init() {}
    
    func extractText(from image: UIImage, completion: @escaping ([String]) -> Void) {
        guard let cgImage = image.cgImage else {
            completion([])
            return
        }
        
        let request = VNRecognizeTextRequest { request, error in
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                completion([])
                return
            }
            
            let recognizedStrings = observations.compactMap { observation in
                return observation.topCandidates(1).first?.string
            }
            
            DispatchQueue.main.async {
                completion(recognizedStrings)
            }
        }
        
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        do {
            try handler.perform([request])
        } catch {
            print("Failed to perform OCR: \(error)")
            completion([])
        }
    }
    
    func extractProductInfo(from image: UIImage, completion: @escaping (ProductInfo) -> Void) {
        extractText(from: image) { recognizedStrings in
            let productInfo = self.parseProductInfo(from: recognizedStrings)
            completion(productInfo)
        }
    }
    
    private func parseProductInfo(from texts: [String]) -> ProductInfo {
        var productName: String?
        var expirationDate: Date?
        
        let dateFormatter = DateFormatter()
        let dateFormats = [
            "dd/MM/yyyy",
            "dd.MM.yyyy",
            "dd-MM-yyyy",
            "MM/dd/yyyy",
            "yyyy-MM-dd",
            "dd/MM/yy",
            "dd.MM.yy",
            "dd-MM-yy"
        ]
        
        for text in texts {
            if expirationDate == nil {
                for format in dateFormats {
                    dateFormatter.dateFormat = format
                    if let date = dateFormatter.date(from: text.trimmingCharacters(in: .whitespacesAndNewlines)) {
                        expirationDate = date
                        break
                    }
                }
                
                let dateKeywords = ["expire", "expiry", "best before", "use by", "à consommer avant le", "DLC", "DDM"]
                for keyword in dateKeywords {
                    if text.lowercased().contains(keyword.lowercased()) {
                        let components = text.components(separatedBy: .whitespacesAndNewlines)
                        for component in components {
                            for format in dateFormats {
                                dateFormatter.dateFormat = format
                                if let date = dateFormatter.date(from: component) {
                                    expirationDate = date
                                    break
                                }
                            }
                            if expirationDate != nil { break }
                        }
                    }
                }
            }
            
            if productName == nil && text.count > 3 && text.count < 50 {
                let lowercasedText = text.lowercased()
                let blacklistedWords = ["expire", "expiry", "best before", "use by", "ingredients", "nutrition", "barcode"]
                
                if !blacklistedWords.contains(where: { lowercasedText.contains($0) }) &&
                   !text.allSatisfy({ $0.isNumber || $0.isPunctuation }) {
                    productName = text.trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
        }
        
        return ProductInfo(name: productName, expirationDate: expirationDate)
    }
}

struct ProductInfo {
    let name: String?
    let expirationDate: Date?
}