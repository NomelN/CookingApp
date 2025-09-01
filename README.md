# 🍎 CookingApp

Une application iOS moderne pour gérer vos produits alimentaires et réduire le gaspillage en suivant les dates d'expiration.

## 📱 Fonctionnalités

### Gestion des Produits
- ✅ Ajout de produits avec photo, nom, description et date d'expiration
- ✅ Reconnaissance OCR automatique pour extraire les informations des étiquettes
- ✅ Modification et suppression des produits
- ✅ Marquage des produits comme consommés
- ✅ Recherche dans la liste des produits

### Suivi d'Expiration
- 🟢 **Frais** : Plus de 7 jours restants
- 🟡 **À consommer bientôt** : 4-7 jours restants  
- 🟠 **À consommer rapidement** : 1-3 jours restants
- 🔴 **Expiré** : Date dépassée

### Notifications Intelligentes
- 📅 Rappels à 7, 3, 1 jour(s) avant expiration
- 📅 Notification le jour d'expiration
- ⚙️ Paramètres de notification personnalisables

### Statistiques Avancées
- 📊 Vue d'ensemble avec graphiques colorés
- 📈 Taux de consommation vs gaspillage
- 📋 Historique des produits consommés
- 🗓️ Filtres par période (semaine, mois, trimestre, année)

### Interface Utilisateur
- 🎨 Design moderne avec thème de couleurs cohérent
- 📱 Navigation par onglets (Produits, Statistiques, Paramètres)
- 🔍 Recherche instantanée
- 📸 Interface photo intégrée

## 🛠️ Technologies

- **Framework** : SwiftUI
- **Base de données** : Core Data
- **Reconnaissance de texte** : Vision Framework (OCR)
- **Notifications** : User Notifications Framework
- **Architecture** : MVVM (Model-View-ViewModel)

## 📋 Prérequis

- iOS 15.0+
- Xcode 14.0+
- Swift 5.7+

## 🚀 Installation

1. Clonez le repository :
```bash
git clone https://github.com/votre-username/CookingApp.git
cd CookingApp
```

2. Ouvrez le projet dans Xcode :
```bash
open CookingApp.xcodeproj
```

3. Compilez et lancez l'application sur un simulateur ou appareil iOS.

## 📁 Structure du Projet

```
CookingApp/
├── CookingApp/
│   ├── CookingAppApp.swift          # Point d'entrée principal
│   ├── ContentView.swift            # Vue racine
│   ├── Models/
│   │   └── Product+Extensions.swift  # Extensions du modèle Product
│   ├── Views/
│   │   ├── DashboardView.swift      # Vue principale avec navigation
│   │   ├── AddProductView.swift     # Formulaire d'ajout
│   │   ├── EditProductView.swift    # Formulaire d'édition
│   │   ├── StatisticsView.swift     # Page de statistiques
│   │   └── SettingsView.swift       # Paramètres
│   ├── ViewModels/
│   │   ├── ProductsViewModel.swift   # Gestion des produits
│   │   └── StatisticsViewModel.swift # Gestion des statistiques
│   ├── Services/
│   │   ├── PersistenceController.swift # Core Data
│   │   ├── NotificationManager.swift   # Notifications locales
│   │   └── OCRService.swift           # Reconnaissance de texte
│   └── Utils/
│       └── ColorTheme.swift         # Thème de couleurs
├── CookingApp.xcdatamodeld/         # Modèle Core Data
└── Tests/                           # Tests unitaires et UI
```

## 🎯 Utilisation

### Ajouter un Produit
1. Appuyez sur le bouton "+" en haut à droite
2. Prenez une photo ou sélectionnez depuis la galerie
3. Les informations sont extraites automatiquement par OCR
4. Ajustez si nécessaire et validez

### Marquer comme Consommé
1. Appuyez sur le bouton ✓ vert sur la carte produit
2. Confirmez dans la popup

### Voir les Statistiques
1. Naviguez vers l'onglet "Statistiques"
2. Sélectionnez la période d'analyse
3. Consultez les graphiques et métriques

## 🔧 Configuration

### Notifications
- Autorisez les notifications lors du premier lancement
- Personnalisez les rappels dans l'onglet Paramètres

### Permissions
- **Appareil Photo** : Pour photographier les produits
- **Galerie Photo** : Pour sélectionner des images existantes
- **Notifications** : Pour les rappels d'expiration

## 🤝 Contribution

1. Forkez le projet
2. Créez une branche feature (`git checkout -b feature/AmazingFeature`)
3. Committez vos changements (`git commit -m 'Add some AmazingFeature'`)
4. Poussez vers la branche (`git push origin feature/AmazingFeature`)
5. Ouvrez une Pull Request

## 📝 Licence

Ce projet est sous licence MIT. Voir le fichier [LICENSE](LICENSE) pour plus de détails.

## 👨‍💻 Auteur

**Mickaël Nomel**
