import SwiftUI

struct DashboardView: View {
    var body: some View {
        MainTabView()
    }
}

struct MainTabView: View {
    @StateObject private var viewModel = ProductsViewModel()
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var showingAddProduct = false
    
    var body: some View {
        TabView {
            // Onglet Produits
            NavigationView {
                ZStack {
                    ColorTheme.backgroundLight(isDark: themeManager.isDarkMode)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 0) {
                        // Filtre par statut
                        ProductFilterView(viewModel: viewModel)
                        
                        if viewModel.sortedProducts.isEmpty {
                            EmptyStateView()
                        } else {
                            ProductListView(viewModel: viewModel)
                        }
                    }
                }
                .navigationTitle("Mes Produits")
                .navigationBarTitleDisplayMode(.large)
                .searchable(text: $viewModel.searchText, prompt: "Rechercher un produit")
                .toolbarBackground(ColorTheme.cardBackground(isDark: themeManager.isDarkMode), for: .navigationBar)
                .foregroundStyle(ColorTheme.primaryBlue)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            showingAddProduct = true
                        }) {
                            AddButtonView()
                        }
                    }
                }
                .sheet(isPresented: $showingAddProduct) {
                    AddProductView(viewModel: viewModel)
                }
                .onAppear {
                    viewModel.forceRefreshView()
                }
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .tabItem {
                Image(systemName: "basket.fill")
                Text("Produits")
            }
            
            // Onglet Statistiques
            StatisticsView()
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("Statistiques")
                }
            
            // Onglet Paramètres
            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("Paramètres")
                }
        }
        .accentColor(ColorTheme.primaryBlue)
        .onAppear {
            viewModel.forceRefreshView()
        }
    }
}

struct ProductListView: View {
    @ObservedObject var viewModel: ProductsViewModel
    @State private var selectedProduct: Product?
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.sortedProducts, id: \.id) { product in
                    ProductCardView(product: product, viewModel: viewModel)
                        .onTapGesture {
                            selectedProduct = product
                        }
                        .contextMenu {
                            Button(action: {
                                withAnimation(.spring()) {
                                    viewModel.markAsUsed(product)
                                }
                            }) {
                                Label("Marquer comme utilisé", systemImage: "checkmark.circle.fill")
                            }
                            
                            Button(action: {
                                selectedProduct = product
                            }) {
                                Label("Modifier", systemImage: "pencil")
                            }
                            
                            Button(action: {
                                viewModel.deleteProduct(product)
                            }) {
                                Label("Supprimer", systemImage: "trash")
                            }
                            .foregroundColor(.red)
                        }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .sheet(item: $selectedProduct) { product in
            EditProductView(product: product, viewModel: viewModel)
        }
    }
}

struct ProductCardView: View {
    let product: Product
    @ObservedObject var viewModel: ProductsViewModel
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var showingConsumeAlert = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                // Image du produit
                Group {
                    if let image = product.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    } else {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(LinearGradient(
                                colors: [ColorTheme.primaryGreen.opacity(0.3), ColorTheme.primaryBlue.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 80, height: 80)
                            .overlay(
                                Image(systemName: "photo.fill")
                                    .font(.title2)
                                    .foregroundColor(ColorTheme.primaryGreen)
                            )
                    }
                }
                
                VStack(alignment: .leading, spacing: 10) {
                    // En-tête avec nom et bouton consommé
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(product.name ?? "Produit")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(ColorTheme.primaryText(isDark: themeManager.isDarkMode))
                                .lineLimit(1)
                            
                            if let description = product.productDescription, !description.isEmpty {
                                Text(description)
                                    .font(.subheadline)
                                    .foregroundColor(ColorTheme.secondaryText(isDark: themeManager.isDarkMode))
                                    .lineLimit(1)
                            }
                        }
                        
                        Spacer()
                        
                        // Bouton marquer comme consommé
                        Button(action: {
                            showingConsumeAlert = true
                        }) {
                            Image(systemName: "checkmark.circle")
                                .font(.title2)
                                .foregroundColor(ColorTheme.primaryGreen)
                                .background(
                                    Circle()
                                        .fill(ColorTheme.primaryGreen.opacity(0.1))
                                        .frame(width: 32, height: 32)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    // Affichage des jours restants
                    HStack {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(product.statusColor(from: viewModel.lastRefresh))
                                .frame(width: 10, height: 10)
                            
                            let currentDays = product.daysUntilExpiration(from: viewModel.lastRefresh)
                            if currentDays >= 0 {
                                Text("\(currentDays) jour\(currentDays > 1 ? "s" : "") restant\(currentDays > 1 ? "s" : "")")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(product.statusColor(from: viewModel.lastRefresh))
                            } else {
                                Text("Expiré depuis \(abs(currentDays)) jour\(abs(currentDays) > 1 ? "s" : "")")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(ColorTheme.expiredRed)
                            }
                        }
                        
                        Spacer()
                    }
                }
            }
            .padding(20)
            
            // Barre de date en bas avec progression
            VStack(spacing: 0) {
                // Barre de progression
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(ColorTheme.borderLight(isDark: themeManager.isDarkMode))
                            .frame(height: 3)
                        
                        Rectangle()
                            .fill(progressBarColor.opacity(0.8))
                            .frame(width: max(0, geometry.size.width * progressPercentage), height: 3)
                    }
                }
                .frame(height: 3)
                
                // Informations de date
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar.badge.clock")
                            .foregroundColor(ColorTheme.secondaryText(isDark: themeManager.isDarkMode))
                            .font(.caption)
                        
                        if let expirationDate = product.expirationDate {
                            Text("Expire le \(expirationDate, formatter: dateFormatter)")
                                .font(.caption)
                                .foregroundColor(ColorTheme.secondaryText(isDark: themeManager.isDarkMode))
                        }
                    }
                    
                    Spacer()
                    
                    Text(product.expirationStatus(from: viewModel.lastRefresh).description.uppercased())
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(product.statusColor(from: viewModel.lastRefresh))
                        .tracking(0.5)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
            .background(ColorTheme.sectionBackground(isDark: themeManager.isDarkMode))
        }
        .background(ColorTheme.cardBackground(isDark: themeManager.isDarkMode))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: ColorTheme.shadowColor(isDark: themeManager.isDarkMode).opacity(0.15), radius: 12, x: 0, y: 6)
        .scaleEffect(1.0)
        .animation(.easeInOut(duration: 0.2), value: product.isUsed)
        .alert("Marquer comme consommé", isPresented: $showingConsumeAlert) {
            Button("Annuler", role: .cancel) { }
            Button("Consommer", role: .destructive) {
                withAnimation(.spring()) {
                    viewModel.markAsUsed(product)
                }
            }
        } message: {
            Text("Êtes-vous sûr de vouloir marquer \"\(product.name ?? "ce produit")\" comme consommé ?")
        }
    }
    
    private var progressPercentage: Double {
        let daysRemaining = product.daysUntilExpiration(from: viewModel.lastRefresh)
        let status = product.expirationStatus(from: viewModel.lastRefresh)
        
        // Si expiré ou expire aujourd'hui : jauge complète (100%)
        if daysRemaining <= 0 {
            return 1.0
        }
        
        let progress: Double
        
        // Logique simple selon les états
        switch status {
        case .expired:
            progress = 1.0 // 100% - rouge
        case .critical: // 1-3 jours
            progress = 0.8 + (Double(3 - daysRemaining) * 0.2 / 3.0) // 80% à 100%
        case .warning: // 4-7 jours  
            progress = 0.5 + (Double(7 - daysRemaining) * 0.3 / 4.0) // 50% à 80%
        case .good: // >7 jours
            if daysRemaining > 30 {
                progress = 0.0 // Pas de progression pour produits très frais
            } else {
                progress = Double(30 - daysRemaining) * 0.5 / 23.0 // 0% à 50%
            }
        }
        
        return max(0.0, min(1.0, progress))
    }
    
    private var progressBarColor: Color {
        let currentStatus = product.expirationStatus(from: viewModel.lastRefresh)
        switch currentStatus {
        case .good:
            return ColorTheme.freshGreen
        case .warning:
            return ColorTheme.warningYellow
        case .critical:
            return ColorTheme.criticalOrange
        case .expired:
            return ColorTheme.expiredRed
        }
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter
    }()
}

struct EmptyStateView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(ColorTheme.primaryGradient)
                        .frame(width: 120, height: 120)
                        .shadow(color: ColorTheme.primaryGreen.opacity(0.3), radius: 20, x: 0, y: 10)
                    
                    Image(systemName: "basket.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.white)
                }
                
                VStack(spacing: 12) {
                    Text("🍎 Votre frigo est vide !")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(ColorTheme.primaryText(isDark: themeManager.isDarkMode))
                    
                    Text("Commencez à ajouter vos produits alimentaires pour suivre leurs dates d'expiration et réduire le gaspillage")
                        .font(.body)
                        .foregroundColor(ColorTheme.secondaryText(isDark: themeManager.isDarkMode))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 40)
                }
            }
            
            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    Circle()
                        .fill(ColorTheme.primaryGreen)
                        .frame(width: 8, height: 8)
                    Text("Prenez une photo de vos produits")
                        .font(.subheadline)
                        .foregroundColor(ColorTheme.secondaryText(isDark: themeManager.isDarkMode))
                    Spacer()
                }
                
                HStack(spacing: 12) {
                    Circle()
                        .fill(ColorTheme.primaryBlue)
                        .frame(width: 8, height: 8)
                    Text("Recevez des rappels avant expiration")
                        .font(.subheadline)
                        .foregroundColor(ColorTheme.secondaryText(isDark: themeManager.isDarkMode))
                    Spacer()
                }
                
                HStack(spacing: 12) {
                    Circle()
                        .fill(ColorTheme.accentOrange)
                        .frame(width: 8, height: 8)
                    Text("Réduisez le gaspillage alimentaire")
                        .font(.subheadline)
                        .foregroundColor(ColorTheme.secondaryText(isDark: themeManager.isDarkMode))
                    Spacer()
                }
            }
            .padding(.horizontal, 40)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(ColorTheme.cardBackground(isDark: themeManager.isDarkMode))
                    .shadow(color: ColorTheme.shadowColor(isDark: themeManager.isDarkMode), radius: 8, x: 0, y: 4)
            )
            .padding(.horizontal, 32)
        }
        .padding(.vertical, 40)
    }
}

struct ProductFilterView: View {
    @ObservedObject var viewModel: ProductsViewModel
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(ProductFilter.allCases, id: \.rawValue) { filter in
                    FilterButton(
                        filter: filter,
                        isSelected: viewModel.selectedFilter == filter,
                        count: countForFilter(filter)
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.selectedFilter = filter
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 12)
    }
    
    private func countForFilter(_ filter: ProductFilter) -> Int {
        let baseProducts = viewModel.products.filter { !$0.isUsed }
        return baseProducts.filter { product in
            filter.matches(product, from: viewModel.lastRefresh)
        }.count
    }
}

struct FilterButton: View {
    let filter: ProductFilter
    let isSelected: Bool
    let count: Int
    let action: () -> Void
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: filter.systemIcon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isSelected ? .white : filterColor)
                
                Text(filter.rawValue)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isSelected ? .white : ColorTheme.primaryText(isDark: themeManager.isDarkMode))
                
                if count > 0 {
                    Text("(\(count))")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(isSelected ? .white.opacity(0.8) : ColorTheme.secondaryText(isDark: themeManager.isDarkMode))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? filterColor : ColorTheme.cardBackground(isDark: themeManager.isDarkMode))
                    .shadow(color: ColorTheme.shadowColor(isDark: themeManager.isDarkMode).opacity(0.1), radius: 4, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? Color.clear : ColorTheme.borderLight(isDark: themeManager.isDarkMode), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var filterColor: Color {
        switch filter {
        case .all:
            return ColorTheme.primaryBlue
        case .expired:
            return ColorTheme.expiredRed
        case .expiringSoon:
            return ColorTheme.criticalOrange
        case .fresh:
            return ColorTheme.freshGreen
        }
    }
}

struct AddButtonView: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(ColorTheme.primaryGradient)
                .frame(width: 36, height: 36)
                .shadow(color: ColorTheme.primaryBlue.opacity(0.4), radius: 6, x: 0, y: 3)
            
            Image(systemName: "plus")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
        }
        .scaleEffect(1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: true)
    }
}

#Preview {
    DashboardView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
