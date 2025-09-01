import SwiftUI
import PhotosUI

struct AddProductView: View {
    @ObservedObject var viewModel: ProductsViewModel
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
    
    var body: some View {
        NavigationView {
            ZStack {
                ColorTheme.backgroundGray
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Section informations
                        VStack(spacing: 20) {
                            HStack {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(ColorTheme.primaryGreen)
                                Text("Informations du produit")
                                    .font(.headline)
                                    .foregroundColor(ColorTheme.primaryText)
                                Spacer()
                            }
                            
                            VStack(spacing: 16) {
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
                            HStack {
                                Image(systemName: "camera.fill")
                                    .foregroundColor(ColorTheme.secondaryBlue)
                                Text("Photo du produit")
                                    .font(.headline)
                                    .foregroundColor(ColorTheme.primaryText)
                                Spacer()
                            }
                            VStack(spacing: 16) {
                                if let productImage = productImage {
                                    Image(uiImage: productImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(height: 220)
                                        .clipShape(RoundedRectangle(cornerRadius: 20))
                                        .shadow(color: ColorTheme.shadowColor, radius: 8, x: 0, y: 4)
                                } else {
                                    EmptyImagePlaceholderView()
                                }
                                
                                VStack(spacing: 12) {
                                    PhotoButtonsView(
                                        isProcessingOCR: isProcessingOCR,
                                        selectedImage: $selectedImage,
                                        onCameraAction: {
                                            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                                                showingCamera = true
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
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.allowsEditing = false
        picker.cameraCaptureMode = .photo
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPickerView
        
        init(_ parent: CameraPickerView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onImagePicked(image)
            }
            parent.dismiss()
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
            
            TextField(placeholder, text: $text, axis: .vertical)
                .textFieldStyle(PlainTextFieldStyle())
                .padding(16)
                .background(ColorTheme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(ColorTheme.primaryGreen.opacity(0.3), lineWidth: 1)
                )
                .autocorrectionDisabled()
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
            
            DatePicker("", selection: $selection, displayedComponents: .date)
                .datePickerStyle(CompactDatePickerStyle())
                .padding(16)
                .background(ColorTheme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
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
    
    private var cameraBackgroundFill: AnyShapeStyle {
        if cameraAvailable {
            return AnyShapeStyle(ColorTheme.primaryGradient)
        } else {
            return AnyShapeStyle(Color.gray.opacity(0.3))
        }
    }
    
    var body: some View {
        HStack {
            Image(systemName: "camera.fill")
            Text("Appareil photo")
        }
        .font(.subheadline)
        .fontWeight(.medium)
        .foregroundColor(.white)
        .padding(.vertical, 12)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(cameraBackgroundFill)
        )
    }
}

struct GalleryButtonContent: View {
    var body: some View {
        HStack {
            Image(systemName: "photo.fill")
            Text("Galerie")
        }
        .font(.subheadline)
        .fontWeight(.medium)
        .foregroundColor(ColorTheme.secondaryBlue)
        .padding(.vertical, 12)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 25)
                .stroke(ColorTheme.secondaryBlue, lineWidth: 2)
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
        colors: [ColorTheme.primaryGreen.opacity(0.1), ColorTheme.secondaryBlue.opacity(0.1)],
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
                        .foregroundColor(ColorTheme.primaryGreen)
                    
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

struct SaveButtonView: View {
    let productName: String
    let onSave: () -> Void
    
    private var isEmpty: Bool {
        productName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private var buttonBackground: AnyShapeStyle {
        if isEmpty {
            return AnyShapeStyle(Color.gray.opacity(0.3))
        } else {
            return AnyShapeStyle(ColorTheme.primaryGradient)
        }
    }
    
    var body: some View {
        Button("Enregistrer") {
            onSave()
        }
        .font(.subheadline)
        .fontWeight(.semibold)
        .foregroundColor(.white)
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(buttonBackground)
        )
        .disabled(isEmpty)
    }
}

#Preview {
    AddProductView(viewModel: ProductsViewModel())
}