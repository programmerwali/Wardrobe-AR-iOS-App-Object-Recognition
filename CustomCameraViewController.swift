//
//  CustomCameraViewController.swift
//  clothesObjectWithUIKit
//
//  Created by Wali Faisal on 26/12/2024.
//

import UIKit
import AVFoundation

class CustomCameraViewController: UIViewController {
    
    // Capture Session
    var session: AVCaptureSession?
    
    // Photo Output
    let output = AVCapturePhotoOutput()
    
    // Video Preview
    let previewLayer = AVCaptureVideoPreviewLayer()
    
    // Shutter Button
    private let shutterButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        button.layer.cornerRadius = 50
        button.layer.borderWidth = 10
        button.layer.borderColor = UIColor.white.cgColor
        button.accessibilityLabel = "Take Photo"
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black
        view.layer.addSublayer(previewLayer)
        view.addSubview(shutterButton)
        checkCameraPermissions()
        shutterButton.addTarget(self, action: #selector(didTapTakePhoto), for: .touchUpInside)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer.frame = view.bounds
        shutterButton.center = CGPoint(x: view.frame.size.width / 2,
                                       y: view.frame.size.height - 100)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        session?.stopRunning()
    }
    
    private func checkCameraPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            // Request access
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                guard granted else { return }
                DispatchQueue.main.async {
                    self?.setUpCamera()
                }
            }
        case .restricted, .denied:
            // Notify the user
            DispatchQueue.main.async {
                let alert = UIAlertController(title: "Camera Access Denied",
                                              message: "Please enable camera access in settings.",
                                              preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(alert, animated: true)
            }
        case .authorized:
            setUpCamera()
        @unknown default:
            break
        }
    }
    
    private func setUpCamera() {
        let session = AVCaptureSession()
        guard let device = AVCaptureDevice.default(for: .video) else {
            print("Failed to get the camera device.")
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: device)
            if session.canAddInput(input) {
                session.addInput(input)
            }
            
            if session.canAddOutput(output) {
                session.addOutput(output)
            }
            
            previewLayer.videoGravity = .resizeAspectFill
            previewLayer.session = session
            session.startRunning()
            self.session = session
        } catch {
            print("Error setting up camera: \(error)")
        }
    }
    
    @objc private func didTapTakePhoto() {
        output.capturePhoto(with: AVCapturePhotoSettings(), delegate: self)
    }
}

extension CustomCameraViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        guard let data = photo.fileDataRepresentation() else {
            print("Failed to get photo data.")
            return
        }
        
        let image = UIImage(data: data)
        session?.stopRunning()
        
        // Display the captured image
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFill
        imageView.frame = view.bounds
        view.addSubview(imageView)
        
        // Add a dismiss button
        let dismissButton = UIButton(frame: CGRect(x: 20, y: 40, width: 100, height: 40))
        dismissButton.setTitle("Dismiss", for: .normal)
        dismissButton.backgroundColor = .systemBlue
        dismissButton.addTarget(self, action: #selector(didTapDismiss), for: .touchUpInside)
        view.addSubview(dismissButton)
    }
    
    @objc private func didTapDismiss() {
        session?.startRunning()
        view.subviews.last?.removeFromSuperview() // Remove dismiss button
        view.subviews.last?.removeFromSuperview() // Remove image view
    }
}
