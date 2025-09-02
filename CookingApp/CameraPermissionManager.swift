import AVFoundation
import UIKit

class CameraPermissionManager {
    static let shared = CameraPermissionManager()
    
    private init() {}
    
    func requestCameraPermission(completion: @escaping (Bool) -> Void) {
        let cameraAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch cameraAuthorizationStatus {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
        case .authorized:
            completion(true)
        case .restricted, .denied:
            completion(false)
        @unknown default:
            completion(false)
        }
    }
    
    func showPermissionAlert(from viewController: UIViewController) {
        let alert = UIAlertController(
            title: "Accès à l'appareil photo",
            message: "Cette application a besoin d'accéder à votre appareil photo pour prendre des photos de vos produits alimentaires. Vous pouvez activer cette permission dans les Réglages.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Réglages", style: .default) { _ in
            if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsUrl)
            }
        })
        
        alert.addAction(UIAlertAction(title: "Annuler", style: .cancel))
        
        viewController.present(alert, animated: true)
    }
}