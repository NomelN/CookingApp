import SwiftUI
import PhotosUI

struct EditProductView: View {
    let product: Product
    @ObservedObject var viewModel: ProductsViewModel
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var productName = ""
    @State private var expirationDate = Date()
    @State private var productDescription = ""
    @State private var selectedImage: PhotosPickerItem?
    @State private var productImage: UIImage?
    @State private var showingCamera = false
    @State private var hasImageChanged = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Informations du produit") {
                    TextField("Nom du produit", text: $productName)
                        .foregroundColor(ColorTheme.primaryText)
                    
                    DatePicker("Date d'expiration", selection: $expirationDate, displayedComponents: .date)
                        .datePickerStyle(CompactDatePickerStyle())
                        .foregroundColor(ColorTheme.primaryText)
                    
                    TextField("Description (optionnel)", text: $productDescription, axis: .vertical)
                        .lineLimit(3)
                        .foregroundColor(ColorTheme.primaryText)
                }
                
                Section("Photo") {
                    VStack {
                        if let productImage = productImage {
                            Image(uiImage: productImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        } else if let existingImage = product.image {
                            existingImage
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        } else {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 200)
                                .overlay(
                                    VStack(spacing: 8) {
                                        Image(systemName: "camera")
                                            .font(.system(size: 40))
                                            .foregroundColor(.gray)
                                        
                                        Text("Ajouter une photo")
                                            .foregroundColor(.gray)
                                    }
                                )
                        }
                        
                        HStack(spacing: 16) {
                            Button("Appareil photo") {
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
                            .buttonStyle(.bordered)
                            .disabled(!UIImagePickerController.isSourceTypeAvailable(.camera))
                            
                            PhotosPicker(selection: $selectedImage, matching: .images) {
                                Text("Galerie")
                            }
                            .buttonStyle(.bordered)
                            
                            if productImage != nil || product.imageData != nil {
                                Button("Supprimer") {
                                    productImage = nil
                                    hasImageChanged = true
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.red)
                            }
                        }
                        .padding(.top, 8)
                        
                        if !UIImagePickerController.isSourceTypeAvailable(.camera) {
                            Text("Appareil photo non disponible (simulateur)")
                                .font(.caption)
                                .foregroundColor(.orange)
                                .padding(.top, 4)
                        }
                    }
                }
                
                Section {
                    Button("Supprimer le produit", role: .destructive) {
                        viewModel.deleteProduct(product)
                        dismiss()
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(ColorTheme.backgroundLight)
            .navigationTitle("Modifier produit")
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
                    Button("Enregistrer") {
                        saveProduct()
                    }
                    .foregroundColor(productName.isEmpty ? ColorTheme.secondaryText : ColorTheme.primaryGreen)
                    .disabled(productName.isEmpty)
                }
            }
            .sheet(isPresented: $showingCamera) {
                CameraPickerView { image in
                    productImage = image
                    hasImageChanged = true
                }
            }
            .onChange(of: selectedImage) {
                Task {
                    if let newItem = selectedImage {
                        if let data = try? await newItem.loadTransferable(type: Data.self) {
                            if let uiImage = UIImage(data: data) {
                                productImage = uiImage
                                hasImageChanged = true
                            }
                        }
                    }
                }
            }
            .onAppear {
                setupInitialValues()
            }
        }
    }
    
    private func setupInitialValues() {
        productName = product.name ?? ""
        expirationDate = product.expirationDate ?? Date()
        productDescription = product.productDescription ?? ""
    }
    
    private func saveProduct() {
        var imageData: Data?
        
        if hasImageChanged {
            imageData = productImage?.jpegData(compressionQuality: 0.7)
        } else {
            imageData = product.imageData
        }
        
        viewModel.updateProduct(
            product,
            name: productName,
            expirationDate: expirationDate,
            description: productDescription.isEmpty ? nil : productDescription,
            imageData: imageData
        )
        
        dismiss()
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let product = Product(context: context)
    product.name = "Exemple"
    product.expirationDate = Date()
    
    return EditProductView(product: product, viewModel: ProductsViewModel())
}