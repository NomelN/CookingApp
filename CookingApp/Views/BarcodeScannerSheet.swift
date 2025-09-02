import SwiftUI

struct BarcodeScannerSheet: View {
    @Binding var scannedCode: String?
    @Binding var alertMessage: String?
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        NavigationView {
            ZStack {
                // Scanner en arrière-plan
                BarcodeScannerView(
                    scannedCode: $scannedCode,
                    alertMessage: $alertMessage
                )
                .ignoresSafeArea()
                
                // Overlay avec instructions et boutons
                VStack {
                    Spacer()
                    
                    // Instructions en bas
                    VStack(spacing: 16) {
                        HStack {
                            Image(systemName: "barcode.viewfinder")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(ColorTheme.primaryBlue)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Scanner un code-barres")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(ColorTheme.primaryText(isDark: themeManager.isDarkMode))
                                
                                Text("Positionnez le code dans le cadre ci-dessus")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(ColorTheme.secondaryText(isDark: themeManager.isDarkMode))
                            }
                            
                            Spacer()
                        }
                        
                        Text("🔍 Recherche automatique dans Open Food Facts")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(ColorTheme.tertiaryText)
                            .multilineTextAlignment(.center)
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(ColorTheme.cardBackground(isDark: themeManager.isDarkMode))
                            .shadow(color: ColorTheme.shadowColor(isDark: themeManager.isDarkMode), radius: 10, x: 0, y: -5)
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Scanner")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(ColorTheme.cardBackground(isDark: themeManager.isDarkMode), for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Fermer") {
                        dismiss()
                    }
                    .foregroundColor(ColorTheme.secondaryText(isDark: themeManager.isDarkMode))
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Manuel") {
                        dismiss()
                    }
                    .foregroundColor(ColorTheme.primaryBlue)
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            // Redémarrer la session quand l'app revient au premier plan
        }
    }
}