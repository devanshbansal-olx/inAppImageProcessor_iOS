//
//  EditorViewController.swift
//  codeWithNobody
//
//  Created by Devansh Bansal on 10/02/25.


import UIKit
import Photos
import UIKit

extension UIImage {
    func fixedOrientation() -> UIImage {
        if imageOrientation == .up {
            return self // No need to fix orientation
        }

        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(in: CGRect(origin: .zero, size: size))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return normalizedImage ?? self
    }
}


class EditorViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    var selectedImage: UIImage?
    var filteredImages: [UIImage] = []
    var selectedFilterIndex: Int = 0 // Default is "Original"


    let filterNames = ["Original", "Grayscale", "Blur", "Bilateral", "Edge Detect", "Sharpen"]
    
    let imageView = UIImageView()
    let cropButton = UIButton(type: .system)
    let watermarkButton = UIButton(type: .system)
    let filtersButton = UIButton(type: .system)
    let saveButton = UIButton(type: .system)
    var collectionView: UICollectionView!
    var cropRectView: UIView!
    var isCropping = false
    var initialTouchPoint: CGPoint = .zero
    

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
        setupUI()
        
        if let image = selectedImage {
            imageView.image = image
            generateFilteredPreviews(image)
        }
        
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save",
                                                                style: .plain,
                                                                target: self,
                                                                action: #selector(saveImage))
    }
    
    private func setupUI() {
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        view.addSubview(imageView)
        
        cropButton.setTitle("Crop", for: .normal)
        watermarkButton.setTitle("Watermark", for: .normal)
        filtersButton.setTitle("Filters", for: .normal)
        saveButton.setTitle("Save", for: .normal)
        
        cropButton.addTarget(self, action: #selector(cropButtonTapped), for: .touchUpInside)
        watermarkButton.addTarget(self, action: #selector(watermarkButtonTapped), for: .touchUpInside)
        filtersButton.addTarget(self, action: #selector(filtersButtonTapped), for: .touchUpInside)
        saveButton.addTarget(self, action: #selector(saveImage), for: .touchUpInside)
        
        let stackView = UIStackView(arrangedSubviews: [cropButton, watermarkButton, filtersButton])
        stackView.axis = .horizontal
        stackView.spacing = 20
        stackView.distribution = .fillEqually
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        
        // Create a CollectionView Layout for filters and previews
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 80, height: 80)
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(FilterCell.self, forCellWithReuseIdentifier: "FilterCell")
        collectionView.isHidden = true // Hide until filters are selected
        view.addSubview(collectionView)
        
        // Add the crop rect view (hidden initially)
        cropRectView = UIView()
          cropRectView.layer.borderColor = UIColor.white.cgColor
        cropRectView.layer.borderWidth = 2
        cropRectView.isHidden = true
        view.addSubview(cropRectView)
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            imageView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.6),
            
            stackView.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 20),
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            
            collectionView.topAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 20),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            collectionView.heightAnchor.constraint(equalToConstant: 100),
            
        ])
    }
    
    
  

    
    
    @objc func saveImage() {
        guard let image = imageView.image else {
            showAlert(title: "Error", message: "No image to save.")
            return
        }

        // Check Photo Library authorization status
        let status = PHPhotoLibrary.authorizationStatus()

        if status == .authorized {
            // Permission granted, save the image
            saveToGallery(image)
        } else if status == .notDetermined {
            // Request permission if not determined
            PHPhotoLibrary.requestAuthorization { newStatus in
                DispatchQueue.main.async {
                    if newStatus == .authorized {
                        self.saveToGallery(image)
                    } else {
                        self.showAlert(title: "Permission Denied", message: "Please enable photo access in settings.")
                    }
                }
            }
        } else {
            // Permission denied, show alert
            showAlert(title: "Permission Denied", message: "Go to Settings → Privacy → Photos and allow access.")
        }
    }

    private func saveToGallery(_ image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(imageSaved(_:didFinishSavingWithError:contextInfo:)), nil)
    }

    // Image save completion handler
    @objc private func imageSaved(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        DispatchQueue.main.async {
            if let error = error {
                self.showAlert(title: "Save Failed", message: error.localizedDescription)
            } else {
                self.showAlert(title: "Success", message: "Image saved to gallery!"){
                    self.returnToFirstScreen()  // Call function to go back
                }
            }
        }
    }

    
    private func returnToFirstScreen() {
        if let navigationController = self.navigationController {
            navigationController.popToRootViewController(animated: true)  // Go back to first screen
        } else {
            self.dismiss(animated: true)  // If presented modally, dismiss the editor
        }
    }

//    private func showAlert(title: String, message: String) {
//        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
//        alert.addAction(UIAlertAction(title: "OK", style: .default))
//        present(alert, animated: true)
//    }
    private func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completion?()  // ✅ Call completion handler if provided
        })
        present(alert, animated: true)
    }


  
    
    private func regenerateFilters() {
            guard let image = imageView.image else { return }
    
            filteredImages.removeAll() // Clear previous filters
            generateFilteredPreviews(image) // Generate new filters
            collectionView.reloadData() // Refresh the UI
        }
    
    // Enum to differentiate between move and resize interactions
    enum CropInteractionMode {
        case none, move, resize
    }

    var cropInteractionMode: CropInteractionMode = .none
    var resizeHandle: UIView!
    
    @objc func cropButtonTapped() {
        guard let image = imageView.image else { return }

        if !isCropping {
            isCropping = true
            cropRectView.isHidden = false
//            cancelButton.isHidden = false  // Show cancel button

            updateBackgroundOverlay()

            if cropRectView.frame == .zero {
                let imageFrame = imageViewFrameForImage()
                let cropWidth = imageFrame.width * 0.5
                let cropHeight = imageFrame.height * 0.5

                // Ensure cropRectView does not go outside imageView
                cropRectView.frame = CGRect(
                    x: max(imageFrame.origin.x, imageFrame.origin.x + (imageFrame.width - cropWidth) / 2),
                    y: max(imageFrame.origin.y, imageFrame.origin.y + (imageFrame.height - cropHeight) / 2),
                    width: min(cropWidth, imageFrame.width),
                    height: min(cropHeight, imageFrame.height)
                )

                setupResizeHandle()
            }

        } else {
            let correctedImage = image.fixedOrientation()
            let imageFrame = imageViewFrameForImage()
            let scaleX = correctedImage.size.width / imageFrame.width
            let scaleY = correctedImage.size.height / imageFrame.height

            let cropRect = CGRect(
                x: (cropRectView.frame.origin.x - imageFrame.origin.x) * scaleX,
                y: (cropRectView.frame.origin.y - imageFrame.origin.y) * scaleY,
                width: cropRectView.frame.width * scaleX,
                height: cropRectView.frame.height * scaleY
            )

            let validCropRect = CGRect(
                x: max(0, cropRect.origin.x),
                y: max(0, cropRect.origin.y),
                width: min(correctedImage.size.width - cropRect.origin.x, cropRect.width),
                height: min(correctedImage.size.height - cropRect.origin.y, cropRect.height)
            )

            if validCropRect.width < 1 || validCropRect.height < 1 {
                print("Invalid crop area")
                return
            }

            if let croppedImage = OpenCVWrapper.cropImage(correctedImage, with: validCropRect) {
                imageView.image = croppedImage
                regenerateFilters()
            }

            cropRectView.isHidden = true
            resizeHandle.isHidden = true
            removeBackgroundOverlay()
            isCropping = false
        }
    }

    // MARK: - Setup Drag Handle for Resizing

    private func setupResizeHandle() {
        if resizeHandle == nil {
            resizeHandle = UIView(frame: CGRect(x: cropRectView.frame.maxX - 20,
                                                y: cropRectView.frame.maxY - 20,
                                                width: 40, height: 40))
            resizeHandle.backgroundColor = UIColor.white
            resizeHandle.layer.cornerRadius = 20
            resizeHandle.layer.borderColor = UIColor.black.cgColor
            resizeHandle.layer.borderWidth = 2
            resizeHandle.isUserInteractionEnabled = true
            view.addSubview(resizeHandle)
        }
        updateResizeHandlePosition()
    }

    // Keep the resize handle at the bottom-right corner of the crop rect
    private func updateResizeHandlePosition() {
        resizeHandle.frame = CGRect(x: cropRectView.frame.maxX - 20,
                                    y: cropRectView.frame.maxY - 20,
                                    width: 40, height: 40)
    }

    // MARK: - Touch Handling for Moving & Resizing

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isCropping, let touch = touches.first else { return }

        let touchPoint = touch.location(in: view)

        if resizeHandle.frame.contains(touchPoint) {
            cropInteractionMode = .resize
        } else if cropRectView.frame.contains(touchPoint) {
            cropInteractionMode = .move
            initialTouchPoint = touchPoint
        } else {
            cropInteractionMode = .none
        }
    }
    
    
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isCropping, let touch = touches.first else { return }

        let touchPoint = touch.location(in: view)
        let imageFrame = imageViewFrameForImage()

        switch cropInteractionMode {
        case .move:
            let deltaX = touchPoint.x - initialTouchPoint.x
            let deltaY = touchPoint.y - initialTouchPoint.y

            var newFrame = cropRectView.frame.offsetBy(dx: deltaX, dy: deltaY)

            // Ensure the crop rectangle stays within the image bounds
            let minX = imageFrame.origin.x
            let maxX = imageFrame.maxX - cropRectView.frame.width
            let minY = imageFrame.origin.y
            let maxY = imageFrame.maxY - cropRectView.frame.height

            newFrame.origin.x = max(minX, min(newFrame.origin.x, maxX))
            newFrame.origin.y = max(minY, min(newFrame.origin.y, maxY))

            cropRectView.frame = newFrame
            updateResizeHandlePosition()
            initialTouchPoint = touchPoint

        case .resize:
            // **RESIZING - Prevent cropRect from going outside image bounds**
            var newWidth = touchPoint.x - cropRectView.frame.origin.x
            var newHeight = touchPoint.y - cropRectView.frame.origin.y

            let minWidth: CGFloat = 50
            let minHeight: CGFloat = 50

            // **Limit width & height to stay within image bounds**
            let maxWidth = imageFrame.maxX - cropRectView.frame.origin.x
            let maxHeight = imageFrame.maxY - cropRectView.frame.origin.y

            newWidth = min(max(minWidth, newWidth), maxWidth)
            newHeight = min(max(minHeight, newHeight), maxHeight)

            cropRectView.frame.size = CGSize(width: newWidth, height: newHeight)

            updateResizeHandlePosition()

        case .none:
            break
        }
    }

//    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
//        guard isCropping, let touch = touches.first else { return }
//
//        let touchPoint = touch.location(in: view)
//        let imageFrame = imageViewFrameForImage()
//
//        switch cropInteractionMode {
//        case .move:
//            // Move the crop rectangle freely inside the image bounds
//            let deltaX = touchPoint.x - initialTouchPoint.x
//            let deltaY = touchPoint.y - initialTouchPoint.y
//
//            var newFrame = cropRectView.frame.offsetBy(dx: deltaX, dy: deltaY)
//
//            //  Correct the movement boundary dynamically
//            let minX = imageFrame.origin.x
//            let maxX = imageFrame.maxX - cropRectView.frame.width
//            let minY = imageFrame.origin.y
//            let maxY = imageFrame.maxY - cropRectView.frame.height
//
//            //  Ensure the crop rectangle moves freely within the entire image bounds
//            newFrame.origin.x = max(minX, min(newFrame.origin.x, maxX))
//            newFrame.origin.y = max(minY, min(newFrame.origin.y, maxY))
//
//            cropRectView.frame = newFrame
//            updateResizeHandlePosition()
//            initialTouchPoint = touchPoint
//
//            //  Debug Log: Check new movement values
//            print("Move X: \(newFrame.origin.x), Y: \(newFrame.origin.y), MinX: \(minX), MaxX: \(maxX), MinY: \(minY), MaxY: \(maxY)")
//
//        case .resize:
//            // Resize logic: Remove the constraints and allow free resizing
//                   var newWidth = touchPoint.x - cropRectView.frame.origin.x
//                   var newHeight = touchPoint.y - cropRectView.frame.origin.y
//
//                   // No constraints, allow the cropRect to grow freely
//                   // Just make sure it's not too small
//                   let minWidth: CGFloat = 50
//                   let minHeight: CGFloat = 50
//
//                   newWidth = max(minWidth, newWidth)
//                   newHeight = max(minHeight, newHeight)
//
//                   // Set the new width and height for the crop rectangle
//                   cropRectView.frame.size.width = newWidth
//                   cropRectView.frame.size.height = newHeight
//
//                   // Update resize handle position dynamically
//                   updateResizeHandlePosition()
//
//        case .none:
//            break
//        }
//    }


    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        cropInteractionMode = .none
    }

    // MARK: - Get Image Frame Inside UIImageView

    
    func imageViewFrameForImage() -> CGRect {
        guard let image = imageView.image else { return CGRect.zero }

        let imageSize = image.size
        let imageViewSize = imageView.bounds.size

        let scaleX = imageViewSize.width / imageSize.width
        let scaleY = imageViewSize.height / imageSize.height
        let scale = min(scaleX, scaleY) // Preserve aspect ratio

        let scaledWidth = imageSize.width * scale
        let scaledHeight = imageSize.height * scale

        let imageX = imageView.frame.origin.x + (imageViewSize.width - scaledWidth) / 2
        let imageY = imageView.frame.origin.y + (imageViewSize.height - scaledHeight) / 2

        return CGRect(x: imageX, y: imageY, width: scaledWidth, height: scaledHeight)
    }



    // MARK: - Show the Uncropped Image in the Background

    private func updateBackgroundOverlay() {
        view.subviews.filter { $0.tag == 999 }.forEach { $0.removeFromSuperview() }

        let overlayView = UIView()
        overlayView.frame = imageView.frame
        overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        overlayView.tag = 999
        view.addSubview(overlayView)

        cropRectView.layer.borderWidth = 2
        cropRectView.layer.borderColor = UIColor.white.cgColor
        cropRectView.isHidden = false
    }

    // MARK: - Remove Background Overlay After Cropping

    private func removeBackgroundOverlay() {
        view.subviews.filter { $0.tag == 999 }.forEach { $0.removeFromSuperview() }
    }

    // Watermark button tapped
    @objc func watermarkButtonTapped() {
        if let image = imageView.image,
           let watermark = UIImage(named: "watermark.png") {
            let watermarkedImage = OpenCVWrapper.addWatermark(to: image, watermark: watermark)
            imageView.image = watermarkedImage
            regenerateFilters()
        }
    }

    @objc func filtersButtonTapped() {
        collectionView.isHidden.toggle() // Show/hide filters
    }

    // **Generate Filter Previews**
    private func generateFilteredPreviews(_ image: UIImage) {
        filteredImages.append(image) // Original
        filteredImages.append(OpenCVWrapper.convert(toGrayscale: image))
        filteredImages.append(OpenCVWrapper.applyBlur(to: image))
        filteredImages.append(OpenCVWrapper.applyBilateralFilter(to: image))
        filteredImages.append(OpenCVWrapper.applyEdgeDetection(to: image))
        filteredImages.append(OpenCVWrapper.applySharpen(to: image))
    }
    
    // **UICollectionView Data Source**
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filterNames.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FilterCell", for: indexPath) as! FilterCell
        cell.imageView.image = filteredImages[indexPath.item]
        cell.label.text = filterNames[indexPath.item]
        
        // Highlight the selected filter
                if indexPath.item == selectedFilterIndex {
                    cell.layer.borderColor = UIColor.black.cgColor // filter border color
                    cell.layer.borderWidth = 3
                } else {
                    cell.layer.borderColor = UIColor.clear.cgColor
                    cell.layer.borderWidth = 0
                }
        
        return cell
    }
    
    // **UICollectionView Delegate**
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//        imageView.image = filteredImages[indexPath.item]
        selectedFilterIndex = indexPath.item
                imageView.image = filteredImages[indexPath.item]
                collectionView.reloadData()
    }
}

// **Custom CollectionView Cell**
class FilterCell: UICollectionViewCell {
    let imageView = UIImageView()
    let label = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        addSubview(imageView)
        
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .black
        addSubview(label)
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 70),
            imageView.heightAnchor.constraint(equalToConstant: 70),
            
            label.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 4),
            label.centerXAnchor.constraint(equalTo: centerXAnchor)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


