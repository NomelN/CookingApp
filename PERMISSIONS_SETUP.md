# Configuration des Permissions - Scanner de Code-barres

## Permissions requises à ajouter dans Xcode

Pour que le scanner de code-barres fonctionne correctement, vous devez ajouter les permissions suivantes dans votre projet Xcode :

### 1. Ouvrir les paramètres du projet
1. Sélectionnez le projet `CookingApp` dans le navigateur de projet
2. Sélectionnez la target `CookingApp`
3. Allez dans l'onglet `Info`

### 2. Ajouter les permissions dans "Custom iOS Target Properties"

Ajoutez les clés suivantes :

#### NSCameraUsageDescription
- **Clé**: `Privacy - Camera Usage Description`
- **Type**: String
- **Valeur**: `Cette application utilise la caméra pour scanner les codes-barres des produits et prendre des photos pour l'analyse automatique des informations.`

#### NSPhotoLibraryUsageDescription  
- **Clé**: `Privacy - Photo Library Usage Description`
- **Type**: String
- **Valeur**: `Cette application accède à votre galerie photo pour sélectionner des images de produits à analyser.`

### 3. Permissions optionnelles (si nécessaire)

#### NSPhotoLibraryAddUsageDescription
- **Clé**: `Privacy - Photo Library Additions Usage Description`  
- **Type**: String
- **Valeur**: `Cette application peut sauvegarder des photos de produits dans votre galerie.`

## Fonctionnalités implémentées

✅ **Scanner de code-barres** avec AVFoundation
✅ **API Open Food Facts** pour l'identification automatique
✅ **Interface utilisateur** moderne et intuitive
✅ **Gestion d'erreurs** complète
✅ **Support thème clair/sombre**
✅ **Préremplissage automatique** des champs produit

## Utilisation

1. Ouvrir "Nouveau produit"
2. Cliquer sur "Scanner un code-barres" 
3. Pointer la caméra vers le code-barres
4. Les informations se remplissent automatiquement
5. Saisir la date d'expiration (obligatoire)
6. Enregistrer le produit

## Notes techniques

- Les permissions sont gérées par `CameraPermissionManager.swift`
- Les demandes d'autorisation sont faites au runtime
- L'utilisateur est redirigé vers les Réglages si les permissions sont refusées
- Support de multiples formats de codes-barres : EAN8, EAN13, UPC-E, Code128, Code39, Code93, QR