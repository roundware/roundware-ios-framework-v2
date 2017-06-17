//
//  RWFrameworkCamera.swift
//  RWFramework
//
//  Created by Joe Zobkiw on 2/6/15.
//  Copyright (c) 2015 Roundware. All rights reserved.
//

import Foundation
import MobileCoreServices

extension RWFramework: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

// MARK: Media queue

    /// Add an image path with optional description, returns a path (key) to the file that will ultimately be uploaded
    public func addImage(_ string: String, description: String = "") -> String? {
        addMedia(MediaType.Image, string: string, description: description)
        return string
    }

    /// Set a description on an already added image, pass the path returned from addImage or rwImagePickerControllerDidFinishPickingMedia as the string parameter
    public func setImageDescription(_ string: String, description: String) {
        setMediaDescription(MediaType.Image, string: string, description: description)
    }

    /// Remove an image path, pass the path returned from addImage or rwImagePickerControllerDidFinishPickingMedia as the string parameter
    public func removeImage(_ string: String) {
        removeMedia(MediaType.Image, string: string)
    }

    /// Add a movie path with optional description, returns a path (key) to the file that will ultimately be uploaded
    public func addMovie(_ string: String, description: String = "") -> String? {
        addMedia(MediaType.Movie, string: string, description: description)
        return string
    }

    /// Set a description on an already added movie, pass the path returned from addMovie or rwImagePickerControllerDidFinishPickingMedia as the string parameter
    public func setMovieDescription(_ string: String, description: String) {
        setMediaDescription(MediaType.Movie, string: string, description: description)
    }

    /// Remove a movie path, pass the path returned from addMovie or rwImagePickerControllerDidFinishPickingMedia as the string parameter
    public func removeMovie(_ string: String) {
        removeMedia(MediaType.Movie, string: string)
    }

// MARK: - Convenience methods

    /// Allow the user to choose a photo from the photo library
    public func doPhotoLibrary(_ mediaTypes: [String] = UIImagePickerController.availableMediaTypes(for: UIImagePickerControllerSourceType.photoLibrary)!) {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.photoLibrary) == false { return }

        preflightGeoImage()

        let picker = UIImagePickerController()
        picker.sourceType = UIImagePickerControllerSourceType.photoLibrary
        picker.mediaTypes = mediaTypes
        picker.allowsEditing = false
        picker.delegate = self

        showPicker(picker)
    }

    /// Allow the user to take a still image with the camera
    public func doImage() {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera) == false { return }

        preflightGeoImage()

        let picker = UIImagePickerController()
        picker.sourceType = UIImagePickerControllerSourceType.camera
        picker.mediaTypes = [kUTTypeImage as String]
        picker.cameraCaptureMode = UIImagePickerControllerCameraCaptureMode.photo
        picker.allowsEditing = false
        picker.delegate = self

        showPicker(picker)
    }

    /// Allow the user to take a movie with the camera
    public func doMovie() {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera) == false { return }

        preflightGeoImage()

        let picker = UIImagePickerController()
        picker.sourceType = UIImagePickerControllerSourceType.camera
        picker.mediaTypes = [kUTTypeMovie as String]
        picker.cameraCaptureMode = UIImagePickerControllerCameraCaptureMode.video
        let movie_max_duration_in_seconds = RWFrameworkConfig.getConfigValueAsNumber("movie_max_duration_in_seconds").doubleValue
        picker.videoMaximumDuration = movie_max_duration_in_seconds != 0 ? movie_max_duration_in_seconds : 30
        picker.videoQuality = UIImagePickerControllerQualityType.typeMedium
        picker.allowsEditing = false
        picker.delegate = self

        showPicker(picker)
    }

// MARK: - UIImagePickerControllerDelegate

    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let mediaType = info[UIImagePickerControllerMediaType] as! String
        if mediaType == kUTTypeImage as String {
            handleImageMediaType(info)
        } else if mediaType == kUTTypeMovie as String {
            handleMovieMediaType(info)
        } else {
            imagePickerControllerDidCancel(picker)
        }
    }

    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        _rwImagePickerControllerDidCancel()
    }

// MARK: - delegate stubs

    func _rwImagePickerControllerDidFinishPickingMedia(_ info: [AnyHashable: Any], path: String) {
        finishPreflightGeoImage()
        if let keyWindow = UIApplication.shared.keyWindow,
            let rootViewController = keyWindow.rootViewController {
            rootViewController.dismiss(animated: true, completion: { () -> Void in
                self.rwImagePickerControllerDidFinishPickingMedia(info, path: path)
            })
        }
    }

    func _rwImagePickerControllerDidCancel() {
        finishPreflightGeoImage()
        if let keyWindow = UIApplication.shared.keyWindow,
            let rootViewController = keyWindow.rootViewController {
            rootViewController.dismiss(animated: true, completion: { () -> Void in
                self.rwImagePickerControllerDidCancel()
            })
        }
    }

// MARK: - Utilities

    func handleImageMediaType(_ info: [AnyHashable: Any]) {

        func imageWithImage(_ image: UIImage, newSize: CGSize) -> UIImage {
            UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
            let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
            image.draw(in: rect)
            let newImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return newImage!
        }

        if let image: UIImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            let q = DispatchQueue(label: "com.roundware.image_resize_queue", attributes: [])
            q.async(execute: { () -> Void in
//                var imageToDisplay: UIImage?

                // Size
                let image_minimum_side = CGFloat(RWFrameworkConfig.getConfigValueAsNumber("image_minimum_side").floatValue)
                var size = image.size

                if (size.height > image_minimum_side || size.width > image_minimum_side) {
                    if (size.height > image_minimum_side && size.height < size.width) {
                        let factor = image_minimum_side / size.height;
                        size.height = image_minimum_side;
                        size.width = size.width * factor;
                    }
                    if (size.width > image_minimum_side && size.width < size.height) {
                        let factor = image_minimum_side / size.width;
                        size.width = image_minimum_side;
                        size.height = size.height * factor;
                    }
//                    imageToDisplay = imageWithImage(image!, newSize: size)
//                } else {
//                    imageToDisplay = image;
                }

                // Compression
                let image_jpeg_compression = CGFloat(RWFrameworkConfig.getConfigValueAsNumber("image_jpeg_compression").floatValue)
                if let imageData = UIImageJPEGRepresentation(image, image_jpeg_compression) {

                    // Write
                    let r = arc4random()
                    let image_file_name = RWFrameworkConfig.getConfigValueAsString("image_file_name")
                    let imageFileName = "\(r)_\(image_file_name)"
                    let imageFilePath = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(imageFileName)

                    let success = (try? imageData.write(to: URL(fileURLWithPath: (imageFilePath.absoluteString)), options: [])) != nil
                    if success == false {
                        self.println("RWFramework - Couldn't write the image to disk")
                        self._rwImagePickerControllerDidCancel()
                    } else {
                        // Success
                        let keyPath = self.addImage((imageFilePath.absoluteString))
                        self._rwImagePickerControllerDidFinishPickingMedia(info, path: keyPath!)
                    }
                } else {
                    self._rwImagePickerControllerDidCancel()
                }
            })
        } else {
            _rwImagePickerControllerDidCancel()
        }
    }

    func handleMovieMediaType(_ info: [AnyHashable: Any]) {
        if let originalMovieURL: URL = info[UIImagePickerControllerMediaURL] as? URL {
            let originalMoviePath = originalMovieURL.path

            let r = arc4random()
            let movie_file_name = RWFrameworkConfig.getConfigValueAsString("movie_file_name")
            let movieFileName = "\(r)_\(movie_file_name)"
            let movieFilePath = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(movieFileName).absoluteString

            do {
                try FileManager.default.moveItem(atPath: originalMoviePath, toPath: movieFilePath)
                let keyPath = addMovie(movieFilePath)
                _rwImagePickerControllerDidFinishPickingMedia(info, path: keyPath!)
            }
            catch {
                println("RWFramework - Couldn't move movie file \(error)")
                _rwImagePickerControllerDidCancel()
            }
        } else {
            _rwImagePickerControllerDidCancel()
        }
    }

    func showPicker(_ picker: UIImagePickerController) {
        if let keyWindow = UIApplication.shared.keyWindow,
            let rootViewController = keyWindow.rootViewController {
            rootViewController.present(picker, animated: true, completion: { () -> Void in
                UIApplication.shared.setStatusBarHidden(true, with: UIStatusBarAnimation.none)
            })
        }
    }

    func preflightGeoImage() {
        let geo_image_enabled = RWFrameworkConfig.getConfigValueAsBool("geo_image_enabled")
        if (geo_image_enabled) {
            locationManager.startUpdatingLocation()
        }
    }

    func finishPreflightGeoImage() {
        let geo_listen_enabled = RWFrameworkConfig.getConfigValueAsBool("geo_listen_enabled")
        let geo_image_enabled = RWFrameworkConfig.getConfigValueAsBool("geo_image_enabled")
        if (geo_image_enabled) {
            captureLastRecordedLocation()
            if (geo_listen_enabled == false) {
                locationManager.stopUpdatingLocation()
            }
        }
    }
}
