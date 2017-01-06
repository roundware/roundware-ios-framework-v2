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
    public func addImage(string: String, description: String = "") -> String? {
        addMedia(mediaType: MediaType.Image, string: string, description: description)
        return string
    }

    /// Set a description on an already added image, pass the path returned from addImage or rwImagePickerControllerDidFinishPickingMedia as the string parameter
    public func setImageDescription(string: String, description: String) {
        setMediaDescription(mediaType: MediaType.Image, string: string, description: description)
    }

    /// Remove an image path, pass the path returned from addImage or rwImagePickerControllerDidFinishPickingMedia as the string parameter
    public func removeImage(string: String) {
        removeMedia(mediaType: MediaType.Image, string: string)
    }

    /// Add a movie path with optional description, returns a path (key) to the file that will ultimately be uploaded
    public func addMovie(string: String, description: String = "") -> String? {
        addMedia(mediaType: MediaType.Movie, string: string, description: description)
        return string
    }

    /// Set a description on an already added movie, pass the path returned from addMovie or rwImagePickerControllerDidFinishPickingMedia as the string parameter
    public func setMovieDescription(string: String, description: String) {
        setMediaDescription(mediaType: MediaType.Movie, string: string, description: description)
    }

    /// Remove a movie path, pass the path returned from addMovie or rwImagePickerControllerDidFinishPickingMedia as the string parameter
    public func removeMovie(string: String) {
        removeMedia(mediaType: MediaType.Movie, string: string)
    }

// MARK: - Convenience methods

    /// Allow the user to choose a photo from the photo library
    public func doPhotoLibrary(mediaTypes: [String] = UIImagePickerController.availableMediaTypes(for: UIImagePickerControllerSourceType.photoLibrary)!) {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.photoLibrary) == false { return }

        preflightGeoImage()

        let picker = UIImagePickerController()
        picker.sourceType = UIImagePickerControllerSourceType.photoLibrary
        picker.mediaTypes = mediaTypes
        picker.allowsEditing = false
        picker.delegate = self

        showPicker(picker: picker)
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

        showPicker(picker: picker)
    }

    /// Allow the user to take a movie with the camera
    public func doMovie() {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera) == false { return }

        preflightGeoImage()

        let picker = UIImagePickerController()
        picker.sourceType = UIImagePickerControllerSourceType.camera
        picker.mediaTypes = [kUTTypeMovie as String]
        picker.cameraCaptureMode = UIImagePickerControllerCameraCaptureMode.video
        let movie_max_duration_in_seconds = RWFrameworkConfig.getConfigValueAsNumber(key: "movie_max_duration_in_seconds").doubleValue
        picker.videoMaximumDuration = movie_max_duration_in_seconds != 0 ? movie_max_duration_in_seconds : 30
        picker.videoQuality = UIImagePickerControllerQualityType.typeMedium
        picker.allowsEditing = false
        picker.delegate = self

        showPicker(picker: picker)
    }

// MARK: - UIImagePickerControllerDelegate

    public func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        let mediaType = info[UIImagePickerControllerMediaType] as! String
        if mediaType == kUTTypeImage as String {
            handleImageMediaType(info: info as [NSObject : AnyObject])
        } else if mediaType == kUTTypeMovie as String {
            handleMovieMediaType(info: info as [NSObject : AnyObject])
        } else {
            imagePickerControllerDidCancel(picker: picker)
        }
    }

    public func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        _rwImagePickerControllerDidCancel()
    }

// MARK: - delegate stubs

    func _rwImagePickerControllerDidFinishPickingMedia(info: [NSObject : AnyObject], path: String) {
        finishPreflightGeoImage()
        if let keyWindow = UIApplication.shared.keyWindow,
            let rootViewController = keyWindow.rootViewController {
            rootViewController.dismiss(animated: true, completion: { () -> Void in
                self.rwImagePickerControllerDidFinishPickingMedia(info: info, path: path)
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

    func handleImageMediaType(info: [NSObject : AnyObject]) {

        func imageWithImage(image: UIImage, newSize: CGSize) -> UIImage {
            UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
            let rect = CGRectMake(0, 0, newSize.width, newSize.height)
            image.draw(in: rect)
            let newImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return newImage!
        }

        if let image: UIImage? = info[UIImagePickerControllerOriginalImage] as? UIImage {
            let q = DispatchQueue("com.roundware.image_resize_queue", nil)
            q.asynchronously(execute: { () -> Void in
                var imageToDisplay: UIImage?

                // Size
                let image_minimum_side = CGFloat(RWFrameworkConfig.getConfigValueAsNumber(key: "image_minimum_side").floatValue)
                var size = image!.size

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
                    imageToDisplay = imageWithImage(image: image!, newSize: size)
                } else {
                    imageToDisplay = image;
                }

                // Compression
                let image_jpeg_compression = CGFloat(RWFrameworkConfig.getConfigValueAsNumber(key: "image_jpeg_compression").floatValue)
                if let imageData = UIImageJPEGRepresentation(image!, image_jpeg_compression) {

                    // Write
                    let r = arc4random()
                    let image_file_name = RWFrameworkConfig.getConfigValueAsString(key: "image_file_name")
                    let imageFileName = "\(r)_\(image_file_name)"
                    let imageFilePath = (NSTemporaryDirectory() as NSString).stringByAppendingPathComponent(imageFileName)

                    let success = imageData.writeToFile(imageFilePath, atomically: false)
                    if success == false {
                        self.println(object: "RWFramework - Couldn't write the image to disk")
                        self._rwImagePickerControllerDidCancel()
                    } else {
                        // Success
                        let keyPath = self.addImage(imageFilePath)
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

    func handleMovieMediaType(info: [NSObject : AnyObject]) {
        if let originalMovieURL: NSURL? = info[UIImagePickerControllerMediaURL] as? NSURL {
            let originalMoviePath = originalMovieURL!.path

            let r = arc4random()
            let movie_file_name = RWFrameworkConfig.getConfigValueAsString(key: "movie_file_name")
            let movieFileName = "\(r)_\(movie_file_name)"
            let movieFilePath = (NSTemporaryDirectory() as NSString).appendingPathComponent(movieFileName)

            //TODO needs error handling
            var error: NSError?
            let success: Bool
            do {
                try FileManager.default.moveItem(atPath: originalMoviePath!, toPath: movieFilePath)
                success = true
            } catch let error1 as NSError {
                error = error1
                success = false
            }
            if let _ = error {
                println(object: "RWFramework - Couldn't move movie file \(error)")
                _rwImagePickerControllerDidCancel()
            } else if success == false {
                println(object: "RWFramework - Couldn't move movie file for an unknown reason")
                _rwImagePickerControllerDidCancel()
            } else {
                let keyPath = addMovie(string: movieFilePath)
                _rwImagePickerControllerDidFinishPickingMedia(info: info, path: keyPath!)
            }
        } else {
            _rwImagePickerControllerDidCancel()
        }
    }

    func showPicker(picker: UIImagePickerController) {
        if let keyWindow = UIApplication.shared.keyWindow,
            let rootViewController = keyWindow.rootViewController {
            rootViewController.present(picker, animated: true, completion: { () -> Void in
                UIApplication.shared.setStatusBarHidden(true, with: UIStatusBarAnimation.none)
            })
        }
    }

    func preflightGeoImage() {
        let geo_image_enabled = RWFrameworkConfig.getConfigValueAsBool(key: "geo_image_enabled")
        if (geo_image_enabled) {
            locationManager.startUpdatingLocation()
        }
    }

    func finishPreflightGeoImage() {
        let geo_listen_enabled = RWFrameworkConfig.getConfigValueAsBool(key: "geo_listen_enabled")
        let geo_image_enabled = RWFrameworkConfig.getConfigValueAsBool(key: "geo_image_enabled")
        if (geo_image_enabled) {
            captureLastRecordedLocation()
            if (geo_listen_enabled == false) {
                locationManager.stopUpdatingLocation()
            }
        }
    }
}
