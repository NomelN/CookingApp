import SwiftUI
import PhotosUI

struct AddProductView: View {
    @ObservedObject var viewModel: ProductsViewModel
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var productName = ""
    @State private var expirationDate = Date()
    @State private var productDescription = ""
    @State private var selectedImage: PhotosPickerItem?
    @State private var productImage: UIImage?
    @State private var showingCamera = false
    @State private var showingImagePicker = false
    @State private var isProcessingOCR = false
    @StateObject private var ocrService = OCRService.shared
    
    // Scanner de code-barres
    @State private var showingBarcodeScanner = false
    @State private var scannedBarcode: String?
    @State private var isLoadingProductInfo = false
    @State private var scannerAlertMessage: String?
    
    var body: some View {
        NavigationView {
            ZStack {
                ColorTheme.backgroundLight
                    .ignoresSafeArea()
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Section informations
                        VStack(spacing: 20) {
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(ColorTheme.primaryBlue.opacity(0.15))
                                        .frame(width: 32, height: 32)
                                    Image(systemName: "info.circle.fill")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(ColorTheme.primaryBlue)
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Informations du produit")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(ColorTheme.primaryText)
                                    Text("Renseignez les détails de votre produit")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(ColorTheme.secondaryText)
                                }
                                Spacer()
                            }
                            
                            VStack(spacing: 16) {
                                // Bouton Scanner de code-barres
                                BarcodescannerButtonView(
                                    isLoading: isLoadingProductInfo,
                                    onScanAction: {
                                        showingBarcodeScanner = true
                                    }
                                )
                                
                                CustomTextField(title: "Nom du produit", text: $productName, placeholder: "Ex: Lait, Yaourt...")
                                
                                CustomDatePicker(selection: $expirationDate)
                                
                                CustomTextField(title: "Description (optionnel)", text: $productDescription, placeholder: "Notes additionnelles...")
                            }
                        }
                        .padding(20)
                        .background(ColorTheme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(color: ColorTheme.shadowColor, radius: 8, x: 0, y: 4)
                        
                        // Section photo
                        VStack(spacing: 20) {
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(ColorTheme.primaryGreen.opacity(0.15))
                                        .frame(width: 32, height: 32)
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(ColorTheme.primaryGreen)
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Photo du produit")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(ColorTheme.primaryText)
                                    Text("Prenez une photo pour l'analyse automatique")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(ColorTheme.secondaryText)
                                }
                                Spacer()
                            }
                            VStack(spacing: 16) {
                                if let productImage = productImage {
                                    Image(uiImage: productImage)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(maxWidth: .infinity, idealHeight: 200, maxHeight: 220)
                                        .clipShape(RoundedRectangle(cornerRadius: 20))
                                        .shadow(color: ColorTheme.shadowColor, radius: 8, x: 0, y: 4)
                                        .clipped() // Important: force le clipping
                                } else {
                                    EmptyImagePlaceholderView()
                                }
                                
                                VStack(spacing: 12) {
                                    PhotoButtonsView(
                                        isProcessingOCR: isProcessingOCR,
                                        selectedImage: $selectedImage,
                                        onCameraAction: {
                                            CameraPermissionManager.shared.requestCameraPermission { granted in
                                                DispatchQueue.main.async {
                                                    if granted && UIImagePickerController.isSourceTypeAvailable(.camera) {
                                                        showingCamera = true
                                                    } else if !granted {
                                                        print("❌ Permission caméra refusée")
                                                    }
                                                }
                                            }
                                        }
                                    )
                                    
                                    if isProcessingOCR {
                                        OCRProgressView()
                                    }
                                    
                                    if !UIImagePickerController.isSourceTypeAvailable(.camera) {
                                        CameraWarningView()
                                    }
                                }
                            }
                        }
                        .padding(20)
                        .background(ColorTheme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(color: ColorTheme.shadowColor, radius: 8, x: 0, y: 4)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle("🆕 Nouveau produit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(ColorTheme.cardBackground, for: .navigationBar)
            .foregroundStyle(ColorTheme.primaryBlue)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuler") {
                        dismiss()
                    }
                    .foregroundColor(ColorTheme.secondaryText)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    SaveButtonView(
                        productName: productName,
                        onSave: saveProduct
                    )
                }
            }
            .sheet(isPresented: $showingCamera) {
                CameraPickerView { image in
                    productImage = image
                    processImageWithOCR(image)
                }
            }
            .sheet(isPresented: $showingBarcodeScanner) {
                BarcodeScannerSheet(
                    scannedCode: $scannedBarcode,
                    alertMessage: $scannerAlertMessage
                )
            }
            .onChange(of: selectedImage) {
                Task {
                    if let newItem = selectedImage {
                        if let data = try? await newItem.loadTransferable(type: Data.self) {
                            if let uiImage = UIImage(data: data) {
                                productImage = uiImage
                                processImageWithOCR(uiImage)
                            }
                        }
                    }
                }
            }
            .onChange(of: scannedBarcode) {
                if let barcode = scannedBarcode {
                    showingBarcodeScanner = false
                    fetchProductFromBarcode(barcode)
                }
            }
            .alert("Erreur Scanner", isPresented: .constant(scannerAlertMessage != nil)) {
                Button("OK") {
                    scannerAlertMessage = nil
                }
            } message: {
                Text(scannerAlertMessage ?? "")
            }
        }
        .onChange(of: themeManager.currentTheme) { _ in
            // Force une mise à jour de l'interface lors du changement de thème
        }
    }
    
    private func processImageWithOCR(_ image: UIImage) {
        guard !isProcessingOCR else { return }
        
        isProcessingOCR = true
        
        ocrService.extractProductInfo(from: image) { productInfo in
            DispatchQueue.main.async {
                if let name = productInfo.name, self.productName.isEmpty {
                    self.productName = name
                }
                
                if let date = productInfo.expirationDate {
                    self.expirationDate = date
                }
                
                self.isProcessingOCR = false
            }
        }
    }
    
    private func fetchProductFromBarcode(_ barcode: String) {
        isLoadingProductInfo = true
        
        ProductDatabaseService.shared.fetchProductInfo(barcode: barcode) { productInfo in
            DispatchQueue.main.async {
                self.isLoadingProductInfo = false
                
                if let product = productInfo {
                    // Préremplir les champs avec les informations trouvées
                    if let name = product.displayName, self.productName.isEmpty {
                        // Limiter la longueur du nom pour éviter les problèmes d'UI
                        let truncatedName = name.count > 80 ? String(name.prefix(80)) + "..." : name
                        self.productName = truncatedName
                    }
                    
                    if let description = product.productDescription, self.productDescription.isEmpty {
                        // Limiter la longueur de la description
                        let truncatedDescription = description.count > 200 ? String(description.prefix(200)) + "..." : description
                        self.productDescription = truncatedDescription
                    }
                    
                    // Charger l'image du produit si disponible
                    if let imageUrl = product.bestImageUrl {
                        self.loadImageFromURL(imageUrl)
                    }
                    
                    // Réinitialiser le code scanné pour permettre un nouveau scan
                    self.scannedBarcode = nil
                } else {
                    // Produit non trouvé dans la base de données
                    self.scannerAlertMessage = "Produit non trouvé dans la base de données. Veuillez saisir les informations manuellement."
                    self.scannedBarcode = nil
                }
            }
        }
    }
    
    private func loadImageFromURL(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let data = data, let image = UIImage(data: data) {
                    self.productImage = image
                }
            }
        }.resume()
    }
    
    private func saveProduct() {
        guard !productName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        let imageData = productImage?.jpegData(compressionQuality: 0.7)
        
        viewModel.addProduct(
            name: productName.trimmingCharacters(in: .whitespacesAndNewlines),
            expirationDate: expirationDate,
            description: productDescription.isEmpty ? nil : productDescription.trimmingCharacters(in: .whitespacesAndNewlines),
            imageData: imageData
        )
        
        dismiss()
    }
}

struct CameraPickerView: UIViewControllerRepresentable {
    let onImagePicked: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIViewController {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            let errorController = UIViewController()
            DispatchQueue.main.async {
                dismiss()
            }
            return errorController
        }
        
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.allowsEditing = false
        picker.cameraCaptureMode = .photo
        picker.cameraDevice = .rear
        picker.delegate = context.coordinator
        
        // Ajout de gestion d'erreur pour éviter les crashs
        picker.modalPresentationStyle = .fullScreen
        
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPickerView
        
        init(_ parent: CameraPickerView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            defer { parent.dismiss() }
            
            guard let image = info[.originalImage] as? UIImage else {
                print("Erreur: Impossible de récupérer l'image de l'appareil photo")
                return
            }
            
            parent.onImagePicked(image)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

struct CustomTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(ColorTheme.primaryText)
            
            ZStack(alignment: .leading) {
                if text.isEmpty {
                    Text(placeholder)
                        .foregroundColor(ColorTheme.placeholderText)
                        .font(.system(size: 16, weight: .medium).italic())
                        .padding(.horizontal, 18)
                        .padding(.vertical, 18)
                }
                
                TextField("", text: $text, axis: .vertical)
                    .textFieldStyle(PlainTextFieldStyle())
                    .foregroundColor(ColorTheme.primaryText)
                    .font(.system(size: 16, weight: .medium))
                    .padding(18)
                    .autocorrectionDisabled()
                    .lineLimit(2...4)
            }
            .frame(minHeight: 56) // Hauteur minimale fixe pour éviter les sauts de layout
            .background(ColorTheme.fieldBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(ColorTheme.borderLight, lineWidth: 1.5)
            )
            .shadow(color: ColorTheme.shadowColor, radius: 2, x: 0, y: 1)
        }
    }
}

struct CustomDatePicker: View {
    @Binding var selection: Date
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Date d'expiration")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(ColorTheme.primaryText)
            
            HStack {
                DatePicker("", selection: $selection, displayedComponents: .date)
                    .datePickerStyle(CompactDatePickerStyle())
                    .foregroundColor(ColorTheme.primaryText)
                    .labelsHidden()
                    .font(.system(size: 16, weight: .medium))
                
                Spacer()
            }
            .padding(18)
            .background(ColorTheme.fieldBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(ColorTheme.borderLight, lineWidth: 1.5)
            )
            .shadow(color: ColorTheme.shadowColor, radius: 2, x: 0, y: 1)
        }
    }
}

struct PhotoButtonsView: View {
    let isProcessingOCR: Bool
    @Binding var selectedImage: PhotosPickerItem?
    let onCameraAction: () -> Void
    
    private var cameraAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Bouton Appareil photo
            Button(action: onCameraAction) {
                CameraButtonContent()
            }
            .disabled(isProcessingOCR || !cameraAvailable)
            
            // Bouton Galerie
            PhotosPicker(selection: $selectedImage, matching: .images) {
                GalleryButtonContent()
            }
            .disabled(isProcessingOCR)
        }
    }
}

struct CameraButtonContent: View {
    private var cameraAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "camera.fill")
                .font(.system(size: 16, weight: .semibold))
            Text("Appareil photo")
                .fontWeight(.semibold)
        }
        .font(.subheadline)
        .foregroundColor(.white)
        .padding(.vertical, 14)
        .padding(.horizontal, 24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    cameraAvailable ? 
                    ColorTheme.primaryGradient : 
                    LinearGradient(colors: [Color.gray.opacity(0.6)], startPoint: .leading, endPoint: .trailing)
                )
                .shadow(color: cameraAvailable ? ColorTheme.primaryBlue.opacity(0.3) : Color.clear, radius: 8, x: 0, y: 4)
        )
        .scaleEffect(cameraAvailable ? 1.0 : 0.95)
        .opacity(cameraAvailable ? 1.0 : 0.7)
    }
}

struct GalleryButtonContent: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "photo.fill")
                .font(.system(size: 16, weight: .semibold))
            Text("Galerie")
                .fontWeight(.semibold)
        }
        .font(.subheadline)
        .foregroundColor(ColorTheme.primaryBlue)
        .padding(.vertical, 14)
        .padding(.horizontal, 24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(ColorTheme.sectionBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(ColorTheme.primaryBlue.opacity(0.3), lineWidth: 1.5)
                )
                .shadow(color: ColorTheme.shadowColor, radius: 4, x: 0, y: 2)
        )
    }
}

struct OCRProgressView: View {
    var body: some View {
        HStack {
            ProgressView()
                .scaleEffect(0.8)
                .tint(ColorTheme.primaryGreen)
            Text("Analyse de l'image...")
                .font(.caption)
                .foregroundColor(ColorTheme.primaryGreen)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(ColorTheme.primaryGreen.opacity(0.1))
        )
    }
}

struct CameraWarningView: View {
    var body: some View {
        Text("📱 Appareil photo non disponible (simulateur)")
            .font(.caption)
            .foregroundColor(ColorTheme.accentOrange)
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(ColorTheme.accentOrange.opacity(0.1))
            )
    }
}

struct EmptyImagePlaceholderView: View {
    private let placeholderGradient = LinearGradient(
        colors: [ColorTheme.primaryBlue.opacity(0.1), ColorTheme.primaryGreen.opacity(0.1)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    var body: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(placeholderGradient)
            .frame(height: 220)
            .overlay(
                VStack(spacing: 16) {
                    Image(systemName: "camera.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(ColorTheme.primaryBlue)
                    
                    Text("Ajouter une photo")
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(ColorTheme.primaryText)
                    
                    Text("L'OCR analysera automatiquement l'image")
                        .font(.caption)
                        .foregroundColor(ColorTheme.secondaryText)
                        .multilineTextAlignment(.center)
                }
            )
    }
}

struct BarcodescannerButtonView: View {
    let isLoading: Bool
    let onScanAction: () -> Void
    
    var body: some View {
        Button(action: onScanAction) {
            HStack(spacing: 12) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(.white)
                } else {
                    Image(systemName: "barcode.viewfinder")
                        .font(.system(size: 18, weight: .semibold))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(isLoading ? "Recherche en cours..." : "Scanner un code-barres")
                        .font(.system(size: 16, weight: .semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text(isLoading ? "Veuillez patienter" : "Identification automatique")
                        .font(.system(size: 12, weight: .medium))
                        .opacity(0.9)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .opacity(0.7)
            }
            .foregroundColor(.white)
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        isLoading ?
                        LinearGradient(colors: [Color.orange.opacity(0.8), Color.orange], startPoint: .leading, endPoint: .trailing) :
                        LinearGradient(colors: [ColorTheme.primaryPurple, ColorTheme.primaryBlue], startPoint: .leading, endPoint: .trailing)
                    )
                    .shadow(color: isLoading ? Color.orange.opacity(0.3) : ColorTheme.primaryPurple.opacity(0.3), radius: 8, x: 0, y: 4)
            )
        }
        .disabled(isLoading)
        .scaleEffect(isLoading ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isLoading)
    }
}

struct SaveButtonView: View {
    let productName: String
    let onSave: () -> Void
    
    private var isEmpty: Bool {
        productName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        Button("Enregistrer") {
            onSave()
        }
        .font(.system(size: 16, weight: .semibold))
        .foregroundColor(.white)
        .padding(.vertical, 10)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    isEmpty ? 
                    LinearGradient(colors: [Color.gray.opacity(0.4)], startPoint: .leading, endPoint: .trailing) :
                    ColorTheme.successGradient
                )
                .shadow(
                    color: isEmpty ? Color.clear : ColorTheme.primaryGreen.opacity(0.4), 
                    radius: 6, x: 0, y: 3
                )
        )
        .scaleEffect(isEmpty ? 0.95 : 1.0)
        .opacity(isEmpty ? 0.6 : 1.0)
        .disabled(isEmpty)
        .animation(.easeInOut(duration: 0.2), value: isEmpty)
    }
}

#Preview {
    AddProductView(viewModel: ProductsViewModel())
}