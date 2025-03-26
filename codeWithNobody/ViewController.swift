//
//  ViewController.swift
//  codeWithNobody
//
//  Created by Devansh Bansal on 09/02/25.
//


import UIKit
import PhotosUI

class ViewController: UIViewController, PHPickerViewControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    let takePhotoButton = UIButton(type: .system)
    let pickPhotoButton = UIButton(type: .system)
    let activityIndicator = UIActivityIndicatorView(style: .large)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
        setupUI()
    }
    
    private func setupUI() {
        takePhotoButton.translatesAutoresizingMaskIntoConstraints = false
        pickPhotoButton.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        takePhotoButton.setTitle("Take Photo", for: .normal)
        pickPhotoButton.setTitle("Pick from Gallery", for: .normal)
        
        takePhotoButton.addTarget(self, action: #selector(takePhoto), for: .touchUpInside)
        pickPhotoButton.addTarget(self, action: #selector(pickPhoto), for: .touchUpInside)
        
        view.addSubview(takePhotoButton)
        view.addSubview(pickPhotoButton)
        view.addSubview(activityIndicator)
        
        NSLayoutConstraint.activate([
            takePhotoButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            takePhotoButton.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -30),
            
            pickPhotoButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            pickPhotoButton.topAnchor.constraint(equalTo: takePhotoButton.bottomAnchor, constant: 20),
            
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        activityIndicator.hidesWhenStopped = true // Hide when not animating
    }
    
    @objc func takePhoto() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .camera
        present(imagePicker, animated: true)
    }
    
    @objc func pickPhoto() {
        var config = PHPickerConfiguration()
        config.selectionLimit = 1
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }
    
    // Handle gallery selection
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let selectedItem = results.first else { return }
        
        if selectedItem.itemProvider.canLoadObject(ofClass: UIImage.self) {
            activityIndicator.startAnimating() // Start loading indicator
            selectedItem.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
                if let image = object as? UIImage {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { // Small delay
                        self?.activityIndicator.stopAnimating() // Stop loader
                        self?.navigateToEditor(with: image)
                    }
                }
            }
        }
    }
    
    // Handle camera capture
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true)
        if let image = info[.originalImage] as? UIImage {
            activityIndicator.startAnimating() // Show loader
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { // Small delay
                self.activityIndicator.stopAnimating()
                self.navigateToEditor(with: image)
            }
        }
    }
    
    // Navigate to Editor Screen
    private func navigateToEditor(with image: UIImage) {
        let editorVC = EditorViewController()
        editorVC.selectedImage = image
        navigationController?.pushViewController(editorVC, animated: true)
    }
}

