import AVFoundation
import SwiftUI
import AudioToolbox

struct BarcodeScannerView: UIViewControllerRepresentable {
    @Binding var scannedCode: String?
    @Binding var alertMessage: String?
    
    func makeUIViewController(context: Context) -> ScannerViewController {
        let viewController = ScannerViewController()
        viewController.delegate = context.coordinator
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, ScannerViewControllerDelegate {
        let parent: BarcodeScannerView
        
        init(_ parent: BarcodeScannerView) {
            self.parent = parent
        }
        
        func didFindCode(code: String) {
            parent.scannedCode = code
        }
        
        func didReceiveError(error: Error) {
            parent.alertMessage = error.localizedDescription
        }
    }
}

// Protocol pour la communication
protocol ScannerViewControllerDelegate: AnyObject {
    func didFindCode(code: String)
    func didReceiveError(error: Error)
}

// ViewController qui gère la capture
class ScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    weak var delegate: ScannerViewControllerDelegate?
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        previewLayer?.frame = view.layer.bounds
    }
    
    func setupCamera() {
        captureSession = AVCaptureSession()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            delegate?.didReceiveError(error: NSError(domain: "Camera not available", code: 1, userInfo: [NSLocalizedDescriptionKey: "Caméra non disponible"]))
            return
        }
        
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            delegate?.didReceiveError(error: error)
            return
        }
        
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        } else {
            delegate?.didReceiveError(error: NSError(domain: "Cannot add input", code: 1, userInfo: [NSLocalizedDescriptionKey: "Impossible d'accéder à la caméra"]))
            return
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.ean8, .ean13, .upce, .code128, .code39, .code93, .qr] // Types de codes-barres
        } else {
            delegate?.didReceiveError(error: NSError(domain: "Cannot add output", code: 2, userInfo: [NSLocalizedDescriptionKey: "Impossible de configurer le scanner"]))
            return
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        // Ajouter un overlay avec une zone de scan
        addScanningOverlay()
        
        DispatchQueue.global(qos: .background).async {
            self.captureSession.startRunning()
        }
    }
    
    private func addScanningOverlay() {
        let overlayView = UIView(frame: view.bounds)
        overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        
        // Zone de scan transparente
        let scanFrame = CGRect(
            x: view.bounds.width * 0.1,
            y: view.bounds.height * 0.3,
            width: view.bounds.width * 0.8,
            height: view.bounds.height * 0.25
        )
        
        let path = UIBezierPath(rect: overlayView.bounds)
        let scanPath = UIBezierPath(roundedRect: scanFrame, cornerRadius: 16)
        path.append(scanPath.reversing())
        
        let maskLayer = CAShapeLayer()
        maskLayer.path = path.cgPath
        overlayView.layer.mask = maskLayer
        
        // Bordure de la zone de scan
        let borderLayer = CAShapeLayer()
        borderLayer.path = scanPath.cgPath
        borderLayer.strokeColor = UIColor.systemBlue.cgColor
        borderLayer.fillColor = UIColor.clear.cgColor
        borderLayer.lineWidth = 3
        borderLayer.cornerRadius = 16
        
        view.addSubview(overlayView)
        view.layer.addSublayer(borderLayer)
        
        // Instructions
        let instructionLabel = UILabel()
        instructionLabel.text = "Positionnez le code-barres dans le cadre"
        instructionLabel.textColor = .white
        instructionLabel.textAlignment = .center
        instructionLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        instructionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(instructionLabel)
        NSLayoutConstraint.activate([
            instructionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            instructionLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: scanFrame.maxY + 30)
        ])
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
                  let code = readableObject.stringValue else { return }
            
            // Vibrer pour donner un feedback
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            
            // Arrêter la session et renvoyer le code
            DispatchQueue.global(qos: .background).async {
                self.captureSession.stopRunning()
            }
            delegate?.didFindCode(code: code)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        DispatchQueue.global(qos: .background).async {
            if self.captureSession?.isRunning == true {
                self.captureSession.stopRunning()
            }
        }
    }
}