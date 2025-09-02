import SwiftUI
import CoreData

struct StatisticsView: View {
    @StateObject private var viewModel = StatisticsViewModel()
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var selectedPeriod: TimePeriod = .month
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Header avec période
                    HeaderStatsView(selectedPeriod: $selectedPeriod)
                    
                    // Cartes principales
                    MainStatsCardsView(stats: viewModel.statistics)
                    
                    // Graphique d'expiration
                    ExpirationChartView(stats: viewModel.statistics)
                    
                    // Statistiques détaillées
                    DetailedStatsView(stats: viewModel.statistics, consumedProducts: viewModel.consumedProducts)
                    
                    // Produits récemment consommés
                    RecentlyConsumedView(consumedProducts: viewModel.recentConsumedProducts)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .background(ColorTheme.backgroundLight.ignoresSafeArea())
            .navigationTitle("📊 Statistiques")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                viewModel.fetchStatistics()
            }
            .onChange(of: selectedPeriod) { _ in
                viewModel.updatePeriod(selectedPeriod)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

// MARK: - Header avec sélection de période
struct HeaderStatsView: View {
    @Binding var selectedPeriod: TimePeriod
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Période d'analyse")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(ColorTheme.primaryText)
                    
                    Text("Sélectionnez la période pour voir vos statistiques")
                        .font(.subheadline)
                        .foregroundColor(ColorTheme.secondaryText)
                }
                Spacer()
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(TimePeriod.allCases, id: \.self) { period in
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedPeriod = period
                            }
                        }) {
                            VStack(spacing: 8) {
                                Image(systemName: period.iconName)
                                    .font(.title3)
                                    .foregroundColor(selectedPeriod == period ? .white : ColorTheme.primaryGreen)
                                
                                Text(period.displayName)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(selectedPeriod == period ? .white : ColorTheme.primaryText)
                                
                                Text(period.subtitle)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(selectedPeriod == period ? .white.opacity(0.8) : ColorTheme.secondaryText)
                            }
                            .frame(width: 90, height: 80)
                            .background(
                                periodBackgroundView(for: period)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(20)
        .background(ColorTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: ColorTheme.shadowColor.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    private func periodBackgroundView(for period: TimePeriod) -> some View {
        let isSelected = selectedPeriod == period
        let shadowColor = isSelected ? ColorTheme.primaryGreen.opacity(0.3) : Color.clear
        
        return RoundedRectangle(cornerRadius: 25)
            .fill(isSelected ? ColorTheme.primaryGradient : LinearGradient(colors: [ColorTheme.cardBackground], startPoint: .leading, endPoint: .trailing))
            .shadow(color: shadowColor, radius: 8, x: 0, y: 4)
    }
}

// MARK: - Cartes principales des statistiques
struct MainStatsCardsView: View {
    let stats: ProductStatistics
    
    private let gridColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        LazyVGrid(columns: gridColumns, spacing: 16) {
            StatCard(
                title: "Total Produits",
                value: "\(stats.totalProducts)",
                icon: "basket.fill",
                color: ColorTheme.primaryGreen,
                trend: stats.totalProducts > 0 ? .stable : .none
            )
            
            StatCard(
                title: "Consommés",
                value: "\(stats.consumedProducts)",
                icon: "checkmark.circle.fill",
                color: ColorTheme.navyBlue,
                trend: stats.consumedProducts > 0 ? .up : .none
            )
            
            StatCard(
                title: "Expirés",
                value: "\(stats.expiredProducts)",
                icon: "exclamationmark.triangle.fill",
                color: ColorTheme.expiredRed,
                trend: stats.expiredProducts > 0 ? .down : .none
            )
            
            StatCard(
                title: "Expire Bientôt",
                value: "\(stats.expiringProducts)",
                icon: "clock.badge.exclamationmark.fill",
                color: ColorTheme.warningYellow,
                trend: stats.expiringProducts > 0 ? .down : .none
            )
        }
    }
}

// MARK: - Carte de statistique individuelle
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let trend: TrendDirection
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: icon)
                            .font(.title3)
                            .foregroundColor(color)
                        
                        if trend != .none {
                            Image(systemName: trendIcon)
                                .font(.caption)
                                .foregroundColor(trendColor)
                        }
                    }
                    
                    Text(title)
                        .font(.caption)
                        .foregroundColor(ColorTheme.secondaryText)
                        .fontWeight(.medium)
                }
                
                Spacer()
            }
            
            HStack {
                Text(value)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(color)
                
                Spacer()
            }
        }
        .padding(20)
        .background(cardBackground)
        .shadow(color: ColorTheme.shadowColor.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(ColorTheme.cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(color.opacity(0.2), lineWidth: 1)
            )
    }
    
    private var trendIcon: String {
        switch trend {
        case .up: return "arrow.up.circle.fill"
        case .down: return "arrow.down.circle.fill"
        case .stable: return "minus.circle.fill"
        case .none: return ""
        }
    }
    
    private var trendColor: Color {
        switch trend {
        case .up: return .green
        case .down: return .red
        case .stable: return .orange
        case .none: return .clear
        }
    }
}

// MARK: - Graphique d'expiration
struct ExpirationChartView: View {
    let stats: ProductStatistics
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Répartition par statut")
                    .font(.headline)
                    .foregroundColor(ColorTheme.primaryText)
                Spacer()
            }
            
            if stats.totalProducts > 0 {
                HStack(spacing: 16) {
                    // Graphique en anneau
                    ZStack {
                        Circle()
                            .stroke(ColorTheme.navyBlue.opacity(0.1), lineWidth: 15)
                            .frame(width: 120, height: 120)
                        
                        // Segments colorés
                        ForEach(chartDataWithIndex, id: \.id) { item in
                            Circle()
                                .trim(from: item.segment.startAngle, to: item.segment.endAngle)
                                .stroke(item.segment.color, style: StrokeStyle(lineWidth: 15, lineCap: .round))
                                .frame(width: 120, height: 120)
                                .rotationEffect(.degrees(-90))
                        }
                        
                        VStack(spacing: 4) {
                            Text("\(stats.activeProducts)")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(ColorTheme.primaryText)
                            Text("Actifs")
                                .font(.caption)
                                .foregroundColor(ColorTheme.secondaryText)
                        }
                    }
                    
                    // Légende
                    VStack(alignment: .leading, spacing: 12) {
                        ChartLegendItem(
                            color: ColorTheme.freshGreen,
                            label: "Frais",
                            value: stats.freshProducts,
                            total: stats.totalProducts
                        )
                        
                        ChartLegendItem(
                            color: ColorTheme.warningYellow,
                            label: "À consommer bientôt",
                            value: stats.expiringProducts,
                            total: stats.totalProducts
                        )
                        
                        ChartLegendItem(
                            color: ColorTheme.expiredRed,
                            label: "Expirés",
                            value: stats.expiredProducts,
                            total: stats.totalProducts
                        )
                        
                        ChartLegendItem(
                            color: ColorTheme.navyBlue,
                            label: "Consommés",
                            value: stats.consumedProducts,
                            total: stats.totalProducts
                        )
                    }
                    
                    Spacer()
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "chart.pie.fill")
                        .font(.system(size: 40))
                        .foregroundColor(ColorTheme.secondaryText.opacity(0.5))
                    
                    Text("Aucune donnée disponible")
                        .font(.subheadline)
                        .foregroundColor(ColorTheme.secondaryText)
                }
                .padding(40)
            }
        }
        .padding(20)
        .background(ColorTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: ColorTheme.shadowColor.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    private var chartData: [ChartSegment] {
        let total = stats.totalProducts
        guard total > 0 else { return [] }
        
        var currentAngle: Double = 0
        var segments: [ChartSegment] = []
        
        let values = [
            (stats.freshProducts, ColorTheme.freshGreen),
            (stats.expiringProducts, ColorTheme.warningYellow),
            (stats.expiredProducts, ColorTheme.expiredRed),
            (stats.consumedProducts, ColorTheme.navyBlue)
        ]
        
        for (value, color) in values {
            if value > 0 {
                let percentage = Double(value) / Double(total)
                let endAngle = currentAngle + percentage
                
                segments.append(ChartSegment(
                    startAngle: currentAngle,
                    endAngle: endAngle,
                    color: color
                ))
                
                currentAngle = endAngle
            }
        }
        
        return segments
    }
    
    private var chartDataWithIndex: [ChartSegmentWithID] {
        return chartData.enumerated().map { index, segment in
            ChartSegmentWithID(id: index, segment: segment)
        }
    }
}

struct ChartSegment {
    let startAngle: Double
    let endAngle: Double
    let color: Color
}

struct ChartSegmentWithID {
    let id: Int
    let segment: ChartSegment
}

struct ChartLegendItem: View {
    let color: Color
    let label: String
    let value: Int
    let total: Int
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(ColorTheme.primaryText)
                
                Text("\(value) (\(percentage)%)")
                    .font(.caption2)
                    .foregroundColor(ColorTheme.secondaryText)
            }
            
            Spacer()
        }
    }
    
    private var percentage: Int {
        total > 0 ? Int(Double(value) / Double(total) * 100) : 0
    }
}

// MARK: - Statistiques détaillées
struct DetailedStatsView: View {
    let stats: ProductStatistics
    let consumedProducts: [Product]
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Détails")
                    .font(.headline)
                    .foregroundColor(ColorTheme.primaryText)
                Spacer()
            }
            
            VStack(spacing: 12) {
                DetailRow(
                    icon: "percent",
                    label: "Taux de consommation",
                    value: "\(consumptionRate)%",
                    color: consumptionRateColor
                )
                
                DetailRow(
                    icon: "calendar.badge.clock",
                    label: "Durée moyenne de conservation",
                    value: "\(averageShelfLife) jours",
                    color: ColorTheme.navyBlue
                )
                
                DetailRow(
                    icon: "trash.circle.fill",
                    label: "Produits gaspillés",
                    value: "\(stats.expiredProducts)",
                    color: ColorTheme.expiredRed
                )
            }
        }
        .padding(20)
        .background(ColorTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: ColorTheme.shadowColor.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    private var consumptionRate: Int {
        let total = stats.consumedProducts + stats.expiredProducts
        return total > 0 ? Int(Double(stats.consumedProducts) / Double(total) * 100) : 0
    }
    
    private var consumptionRateColor: Color {
        if consumptionRate > 70 {
            return ColorTheme.freshGreen
        } else if consumptionRate > 40 {
            return ColorTheme.warningYellow
        } else {
            return ColorTheme.expiredRed
        }
    }
    
    private var averageShelfLife: Int {
        let validProducts = consumedProducts.compactMap { product -> Int? in
            guard let created = product.createdAt,
                  let expiration = product.expirationDate else { return nil }
            return Calendar.current.dateComponents([.day], from: created, to: expiration).day
        }
        
        return validProducts.isEmpty ? 0 : validProducts.reduce(0, +) / validProducts.count
    }
}

struct DetailRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                    .frame(width: 24)
                
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(ColorTheme.primaryText)
            }
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }
}

// MARK: - Produits récemment consommés
struct RecentlyConsumedView: View {
    let consumedProducts: [Product]
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Récemment consommés")
                    .font(.headline)
                    .foregroundColor(ColorTheme.primaryText)
                Spacer()
            }
            
            if consumedProducts.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "tray")
                        .font(.system(size: 40))
                        .foregroundColor(ColorTheme.secondaryText.opacity(0.5))
                    
                    Text("Aucun produit consommé récemment")
                        .font(.subheadline)
                        .foregroundColor(ColorTheme.secondaryText)
                }
                .padding(40)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(recentProducts, id: \.id) { product in
                        ConsumedProductRow(product: product)
                    }
                }
            }
        }
        .padding(20)
        .background(ColorTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: ColorTheme.shadowColor.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    private var recentProducts: [Product] {
        return Array(consumedProducts.prefix(5))
    }
}

struct ConsumedProductRow: View {
    let product: Product
    
    var body: some View {
        HStack {
            Circle()
                .fill(ColorTheme.freshGreen)
                .frame(width: 8, height: 8)
            
            Text(product.name ?? "Produit")
                .font(.subheadline)
                .foregroundColor(ColorTheme.primaryText)
            
            Spacer()
            
            if let createdAt = product.createdAt {
                Text(timeAgo(from: createdAt))
                    .font(.caption)
                    .foregroundColor(ColorTheme.secondaryText)
            }
        }
        .padding(.vertical, 8)
    }
    
    private func timeAgo(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        let days = Int(interval / 86400)
        
        if days == 0 {
            return "Aujourd'hui"
        } else if days == 1 {
            return "Hier"
        } else {
            return "Il y a \(days) jours"
        }
    }
}

// MARK: - Énumérations et structures de support
enum TimePeriod: CaseIterable {
    case week, month, quarter, year
    
    var displayName: String {
        switch self {
        case .week: return "Semaine"
        case .month: return "Mois"
        case .quarter: return "Trimestre"
        case .year: return "Année"
        }
    }
    
    var subtitle: String {
        switch self {
        case .week: return "7 derniers jours"
        case .month: return "30 derniers jours"
        case .quarter: return "90 derniers jours"
        case .year: return "365 derniers jours"
        }
    }
    
    var iconName: String {
        switch self {
        case .week: return "calendar.badge.clock"
        case .month: return "calendar"
        case .quarter: return "calendar.badge.plus"
        case .year: return "calendar.circle"
        }
    }
    
    var dateComponent: Calendar.Component {
        switch self {
        case .week: return .weekOfYear
        case .month: return .month
        case .quarter: return .quarter
        case .year: return .year
        }
    }
    
    var value: Int {
        switch self {
        case .week: return -7
        case .month: return -30
        case .quarter: return -90
        case .year: return -365
        }
    }
}

enum TrendDirection {
    case up, down, stable, none
}

// MARK: - Preview
#Preview {
    StatisticsView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}