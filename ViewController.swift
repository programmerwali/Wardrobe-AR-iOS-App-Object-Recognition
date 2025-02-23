//
//  ViewController.swift
//  clothesObjectWithUIKit
//
//  Created by Wali Faisal on 13/12/2024.
//


import UIKit
import CoreML
import Vision
import ImageIO

class ViewController: UIViewController, UINavigationControllerDelegate {
    private var selectedImage: UIImage?
    private var processedImage: UIImage?
    
    lazy var detectionRequest: VNCoreMLRequest = {
        do {
            let model = try VNCoreMLModel(for: clothesFinder_Model().model)
            let request = VNCoreMLRequest(model: model) { [weak self] request, error in
                self?.processDetections(for: request, error: error)
            }
            request.imageCropAndScaleOption = .scaleFill
            return request
        } catch {
            fatalError("Failed to load ML model: \(error)")
        }
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func selectPhoto(_ sender: UIButton) {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        present(imagePicker, animated: true)
    }
    
    @IBAction func capturePhoto(_ sender: UIButton) {
        let cameraVC = CustomCameraViewController()
        cameraVC.modalPresentationStyle = .fullScreen
        present(cameraVC, animated: true)
    }
    
    private func updateDetections(for image: UIImage) {
        guard let ciImage = CIImage(image: image) else {
            print("Failed to convert UIImage to CIImage")
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
            do {
                try handler.perform([self.detectionRequest])
            } catch {
                print("Failed to perform detection: \(error.localizedDescription)")
            }
        }
    }
    
    private func processDetections(for request: VNRequest, error: Error?) {
        DispatchQueue.main.async {
            guard let results = request.results as? [VNRecognizedObjectObservation], !results.isEmpty else {
                print("No objects detected.")
                return
            }
            
            self.processedImage = self.drawDetectionsOnPreview(detections: results)
            self.performSegue(withIdentifier: "showOpenImage", sender: nil)
        }
    }
    
    private func drawDetectionsOnPreview(detections: [VNRecognizedObjectObservation]) -> UIImage? {
        guard let image = self.selectedImage else { return nil }
        
        let imageSize = image.size
        UIGraphicsBeginImageContextWithOptions(imageSize, false, 0)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        image.draw(at: .zero)
        
        for detection in detections {
            let boundingBox = detection.boundingBox
            let rectangle = CGRect(
                x: boundingBox.minX * imageSize.width,
                y: (1 - boundingBox.minY - boundingBox.height) * imageSize.height,
                width: boundingBox.width * imageSize.width,
                height: boundingBox.height * imageSize.height
            )
            
            let detectionColor = UIColor.cyan.withAlphaComponent(0.5)
            context.setStrokeColor(detectionColor.cgColor)
            context.setLineWidth(3)
            context.addRect(rectangle)
            context.strokePath()
            
            let labelText = detection.labels.first?.identifier ?? "Unknown"
            let textAttributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: UIColor.white,
                .font: UIFont.boldSystemFont(ofSize: 14),
                .backgroundColor: UIColor.black.withAlphaComponent(0.7)
            ]
            let attributedString = NSAttributedString(string: labelText, attributes: textAttributes)
            attributedString.draw(at: CGPoint(x: rectangle.minX + 5, y: rectangle.minY + 5))
        }
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showOpenImage",
           let destinationVC = segue.destination as? OpenImageViewController {
            destinationVC.imageToDisplay = processedImage
        }
    }
}

extension ViewController: UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true)
        
        if let image = info[.originalImage] as? UIImage {
            self.selectedImage = image
            updateDetections(for: image)
        }
    }
}
