//
//  OpenImageViewController.swift
//  clothesObjectWithUIKit
//
//  Created by Wali Faisal on 26/12/2024.
//

import UIKit

class OpenImageViewController: UIViewController {
    
    
    @IBOutlet weak var resultLabel: UILabel!
    @IBOutlet weak var imageViewer: UIImageView!
    
    
    private lazy var detailsTableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(DetectionTableViewCell.self, forCellReuseIdentifier: "DetectionCell")
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = .systemBackground
        tableView.separatorStyle = .singleLine
        tableView.rowHeight = 60
        tableView.layer.cornerRadius = 10
        tableView.clipsToBounds = true
        return tableView
    }()
    
    var imageToDisplay: UIImage?
    var detectedItem: String = "Unknown"
    var confidenceScore: Double = 0.0
    var modelUsed: String = "Custom CoreML Model"
    var inferenceTime: Int = 0
    var allDetections: [(item: String, confidence: Double)] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        imageViewer.image = imageToDisplay
        resultLabel.attributedText = getStyledDetectionText()
        setupShareButton()
    }
    
    
    private func setupShareButton() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .action,
            target: self,
            action: #selector(shareResults)
        )
    }
    
    @objc private func shareResults() {
        var text = "Clothing Detection Results:\n"
        text += "\nPrimary Detection: \(detectedItem) (\(String(format: "%.1f", confidenceScore))%)"
        text += "\nInference Time: \(inferenceTime)ms"
        
        if !allDetections.isEmpty {
            text += "\n\nAll Detections:"
            for (item, confidence) in allDetections {
                text += "\n- \(item): \(String(format: "%.1f", confidence))%"
            }
        }
        
        let activityVC = UIActivityViewController(
            activityItems: [text, imageToDisplay as Any],
            applicationActivities: nil
        )
        present(activityVC, animated: true)
    }
    
    func getStyledDetectionText() -> NSAttributedString {
        let attributedText = NSMutableAttributedString()
        
        // Primary detection
        let detectionText = NSAttributedString(
            string: "👕 \(detectedItem) Detected\n",
            attributes: [
                .foregroundColor: UIColor.systemCyan,
                .font: UIFont.boldSystemFont(ofSize: 20)
            ]
        )
        attributedText.append(detectionText)
        
        // Confidence score
        let confidenceText = NSAttributedString(
            string: "\n🔍 Confidence: \(String(format: "%.2f", confidenceScore))%\n",
            attributes: [
                .foregroundColor: UIColor.green,
                .font: UIFont.systemFont(ofSize: 16, weight: .medium)
            ]
        )
        attributedText.append(confidenceText)
        
        // Model info
        let modelText = NSAttributedString(
            string: "\n📊 Model: \(modelUsed)\nInference: \(inferenceTime)ms\n",
            attributes: [
                .foregroundColor: UIColor.lightGray,
                .font: UIFont.italicSystemFont(ofSize: 12)
            ]
        )
        attributedText.append(modelText)
        
        return attributedText
    }
    
    private func setupUI() {
        view.addSubview(detailsTableView)
        
        NSLayoutConstraint.activate([
            detailsTableView.topAnchor.constraint(equalTo: resultLabel.bottomAnchor, constant: 20),
            detailsTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            detailsTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            detailsTableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }
}

class DetectionTableViewCell: UITableViewCell {
    private let itemLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 16, weight: .medium)
        return label
    }()
    
    private let confidenceLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textAlignment = .right
        return label
    }()
    
    private let confidenceBar: UIProgressView = {
        let progressView = UIProgressView(progressViewStyle: .bar)
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.layer.cornerRadius = 2
        progressView.clipsToBounds = true
        return progressView
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupCell() {
        contentView.addSubview(itemLabel)
        contentView.addSubview(confidenceLabel)
        contentView.addSubview(confidenceBar)
        
        NSLayoutConstraint.activate([
            itemLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            itemLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            itemLabel.trailingAnchor.constraint(equalTo: confidenceLabel.leadingAnchor, constant: -8),
            
            confidenceLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            confidenceLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            confidenceLabel.widthAnchor.constraint(equalToConstant: 80),
            
            confidenceBar.topAnchor.constraint(equalTo: itemLabel.bottomAnchor, constant: 8),
            confidenceBar.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            confidenceBar.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            confidenceBar.heightAnchor.constraint(equalToConstant: 4)
        ])
    }
    
    func configure(with detection: (item: String, confidence: Double)) {
        itemLabel.text = detection.item
        confidenceLabel.text = String(format: "%.1f%%", detection.confidence)
        
        let progress = Float(detection.confidence / 100)
        confidenceBar.progress = progress
        
        // Color based on confidence
        let color = confidenceColor(progress)
        confidenceBar.progressTintColor = color
        confidenceLabel.textColor = color
    }
    
    private func confidenceColor(_ confidence: Float) -> UIColor {
        switch confidence {
        case 0.8...:
            return .systemGreen
        case 0.6..<0.8:
            return .systemYellow
        default:
            return .systemRed
        }
    }
}

extension OpenImageViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return allDetections.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "DetectionCell", for: indexPath) as? DetectionTableViewCell else {
            return UITableViewCell()
        }
        
        let detection = allDetections[indexPath.row]
        cell.configure(with: detection)
        return cell
    }
}
    
