import SwiftUI

struct SettingsView: View {
    @StateObject private var notificationManager = NotificationManager.shared
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var notificationSettings = NotificationSettings.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                ColorTheme.backgroundLight
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        NotificationSection()
                        ThemeSection()
                        AboutSection()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle("⚙️ Paramètres")
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            notificationManager.checkPermission()
        }
    }
    
    // MARK: - Notification Section
    @ViewBuilder
    private func NotificationSection() -> some View {
        VStack(spacing: 20) {
            SectionHeader(
                title: "Notifications",
                subtitle: "Gérez vos rappels d'expiration",
                iconName: "bell.fill",
                color: ColorTheme.accentOrange
            )
            
            if !notificationManager.hasPermission {
                NotificationPermissionView()
            } else {
                NotificationSettingsView()
            }
        }
        .padding(20)
        .background(ColorTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: ColorTheme.shadowColor, radius: 8, x: 0, y: 4)
    }
    
    @ViewBuilder
    private func NotificationPermissionView() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(ColorTheme.accentOrange)
                Text("Notifications désactivées")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(ColorTheme.accentOrange)
            }
            
            Text("Activez les notifications pour recevoir des rappels avant l'expiration de vos produits.")
                .font(.subheadline)
                .foregroundColor(ColorTheme.secondaryText)
                .lineSpacing(2)
            
            Button("Activer les notifications") {
                notificationManager.requestPermission()
            }
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.vertical, 12)
            .padding(.horizontal, 24)
            .background(ColorTheme.accentGradient)
            .clipShape(RoundedRectangle(cornerRadius: 25))
            .shadow(color: ColorTheme.accentOrange.opacity(0.3), radius: 8, x: 0, y: 4)
        }
    }
    
    @ViewBuilder
    private func NotificationSettingsView() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recevoir des rappels :")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(ColorTheme.primaryText)
            
            VStack(spacing: 12) {
                NotificationToggleRow(
                    title: "7 jours avant expiration",
                    icon: "calendar",
                    color: ColorTheme.freshGreen,
                    isOn: $notificationSettings.sevenDaysBefore
                )
                
                NotificationToggleRow(
                    title: "3 jours avant expiration",
                    icon: "calendar.badge.exclamationmark",
                    color: ColorTheme.warningYellow,
                    isOn: $notificationSettings.threeDaysBefore
                )
                
                NotificationToggleRow(
                    title: "1 jour avant expiration",
                    icon: "exclamationmark.triangle.fill",
                    color: ColorTheme.criticalOrange,
                    isOn: $notificationSettings.oneDayBefore
                )
                
                NotificationToggleRow(
                    title: "Le jour d'expiration",
                    icon: "alarm.fill",
                    color: ColorTheme.expiredRed,
                    isOn: $notificationSettings.expirationDay
                )
            }
        }
    }
    
    // MARK: - Theme Section
    @ViewBuilder
    private func ThemeSection() -> some View {
        VStack(spacing: 20) {
            SectionHeader(
                title: "Apparence",
                subtitle: "Choisissez votre thème préféré",
                iconName: themeManager.currentTheme.iconName,
                color: ColorTheme.primaryPurple
            )
            
            VStack(spacing: 12) {
                ForEach(ThemeMode.allCases, id: \.self) { theme in
                    ThemeSelectionRow(
                        theme: theme,
                        isSelected: themeManager.currentTheme == theme,
                        onSelect: {
                            themeManager.setTheme(theme)
                        }
                    )
                }
            }
        }
        .padding(20)
        .background(ColorTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: ColorTheme.shadowColor, radius: 8, x: 0, y: 4)
    }
    
    
    // MARK: - About Section
    @ViewBuilder
    private func AboutSection() -> some View {
        VStack(spacing: 20) {
            SectionHeader(
                title: "À propos",
                subtitle: "Informations sur l'application",
                iconName: "info.circle.fill",
                color: ColorTheme.primaryBlue
            )
            
            VStack(spacing: 16) {
                InfoRow(title: "Version", value: "1.0.0", icon: "app.badge")
                InfoRow(title: "Développé par", value: "Mickaël Nomel", icon: "person.circle")
                InfoRow(title: "Objectif", value: "Réduire le gaspillage alimentaire", icon: "leaf.fill")
            }
        }
        .padding(20)
        .background(ColorTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: ColorTheme.shadowColor, radius: 8, x: 0, y: 4)
    }
}

struct NotificationToggleRow: View {
    let title: String
    let icon: String
    let color: Color
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 24, height: 24)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(ColorTheme.primaryText)
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: color))
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.05))
        )
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(ColorTheme.primaryBlue)
                .frame(width: 24, height: 24)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(ColorTheme.primaryText)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(ColorTheme.secondaryText)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(ColorTheme.primaryBlue.opacity(0.05))
        )
    }
}

struct SectionHeader: View {
    let title: String
    let subtitle: String
    let iconName: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 32, height: 32)
                Image(systemName: iconName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(ColorTheme.primaryText)
                Text(subtitle)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(ColorTheme.secondaryText)
            }
            Spacer()
        }
    }
}

struct ThemeSelectionRow: View {
    let theme: ThemeMode
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(isSelected ? ColorTheme.primaryPurple : ColorTheme.borderLight)
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: theme.iconName)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(isSelected ? .white : ColorTheme.tertiaryText)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(theme.displayName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(ColorTheme.primaryText)
                    
                    Text(theme == .light ? "Interface claire et lumineuse" : "Interface sombre et moderne")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(ColorTheme.secondaryText)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(ColorTheme.primaryPurple)
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? ColorTheme.primaryPurple.opacity(0.08) : ColorTheme.sectionBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? ColorTheme.primaryPurple.opacity(0.3) : ColorTheme.borderLight, lineWidth: isSelected ? 2 : 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

#Preview {
    SettingsView()
}
