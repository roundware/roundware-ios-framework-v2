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
        recorder.addMedia(Media(mediaType: .Image, string: string, description: description))
        return string
    }

    /// Set a description on an already added image, pass the path returned from addImage or rwImagePickerControllerDidFinishPickingMedia as the string parameter
    public func setImageDescription(_ string: String, description: String) {
        recorder.setMediaDescription(MediaType.Image, string, description)
    }

    /// Remove an image path, pass the path returned from addImage or rwImagePickerControllerDidFinishPickingMedia as the string parameter
    public func removeImage(_ string: String) {
        recorder.removeMedia(MediaType.Image, string: string)
    }

    /// Add a movie path with optional description, returns a path (key) to the file that will ultimately be uploaded
    public func addMovie(_ string: String, description: String = "") -> String? {
        recorder.addMedia(Media(mediaType: .Movie, string: string, description: description))
        return string
    }

    /// Set a description on an already added movie, pass the path returned from addMovie or rwImagePickerControllerDidFinishPickingMedia as the string parameter
    public func setMovieDescription(_ string: String, description: String) {
        recorder.setMediaDescription(MediaType.Movie, string, description)
    }

    /// Remove a movie path, pass the path returned from addMovie or rwImagePickerControllerDidFinishPickingMedia as the string parameter
    public func removeMovie(_ string: String) {
        recorder.removeMedia(MediaType.Movie, string: string)
    }

// MARK: - Convenience methods

    /// Allow the user to choose a photo from the photo library
    public func doPhotoLibrary(_ mediaTypes: [String] = UIImagePickerController.availableMediaTypes(for: UIImagePickerController.SourceType.photoLibrary)!) {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.photoLibrary) == false { return }

        preflightGeoImage()

        let picker = UIImagePickerController()
        picker.sourceType = UIImagePickerController.SourceType.photoLibrary
        picker.mediaTypes = mediaTypes
        picker.allowsEditing = false
        picker.delegate = self

        showPicker(picker)
    }

    /// Allow the user to take a still image with the camera
    public func doImage() {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.camera) == false { return }

        preflightGeoImage()

        let picker = UIImagePickerController()
        picker.sourceType = UIImagePickerController.SourceType.camera
        picker.mediaTypes = [kUTTypeImage as String]
        picker.cameraCaptureMode = UIImagePickerController.CameraCaptureMode.photo
        picker.allowsEditing = false
        picker.delegate = self

        showPicker(picker)
    }

    /// Allow the user to take a movie with the camera
    public func doMovie() {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.camera) == false { return }

        preflightGeoImage()

        let picker = UIImagePickerController()
        picker.sourceType = UIImagePickerController.SourceType.camera
        picker.mediaTypes = [kUTTypeMovie as String]
        picker.cameraCaptureMode = UIImagePickerController.CameraCaptureMode.video
        let movie_max_duration_in_seconds = RWFrameworkConfig.getConfigValueAsNumber("movie_max_duration_in_seconds").doubleValue
        picker.videoMaximumDuration = movie_max_duration_in_seconds != 0 ? movie_max_duration_in_seconds : 30
        picker.videoQuality = UIImagePickerController.QualityType.typeMedium
        picker.allowsEditing = false
        picker.delegate = self

        showPicker(picker)
    }

// MARK: - UIImagePickerControllerDelegate
  
    public func imagePickerController(_ picker: UIImagePickerController,
                                      didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
      let mediaType = info[.mediaType] as? String
      if (mediaType == "public.image") {
          handleImageMediaType(info)
      } else if mediaType == "public.video" {
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
        DispatchQueue.main.async {
            if let keyWindow = UIApplication.shared.keyWindow,
                let rootViewController = keyWindow.rootViewController {
                rootViewController.dismiss(animated: true, completion: { () -> Void in
                    self.rwImagePickerControllerDidFinishPickingMedia(info, path: path)
                })
            }
        }
    }

    func _rwImagePickerControllerDidCancel() {
        finishPreflightGeoImage()
        DispatchQueue.main.async {
            if let keyWindow = UIApplication.shared.keyWindow,
                let rootViewController = keyWindow.rootViewController {
                rootViewController.dismiss(animated: true, completion: { () -> Void in
                    self.rwImagePickerControllerDidCancel()
                })
            }
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

        if let image: UIImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
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
                if let imageData = image.jpegData(compressionQuality: image_jpeg_compression) {

                    // Write
                    let r = arc4random()
                    let image_file_name = RWFrameworkConfig.getConfigValueAsString("image_file_name")
                    let imageFileName = "\(r)_\(image_file_name)"
                    do {
                        try imageData.write(to: self.recorder.recordingPath(for: imageFileName))
                        let keyPath = self.addImage(imageFileName)
                        self._rwImagePickerControllerDidFinishPickingMedia(info, path: keyPath!)
                    } catch {
                        print(error)
                        self._rwImagePickerControllerDidCancel()
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
        if let originalMovieURL: URL = info[UIImagePickerController.InfoKey.mediaURL] as? URL {
            let originalMoviePath = originalMovieURL.path

            let r = arc4random()
            let movie_file_name = RWFrameworkConfig.getConfigValueAsString("movie_file_name")
            let movieFileName = "\(r)_\(movie_file_name)"

            do {
                try FileManager.default.moveItem(at: originalMovieURL, to: recorder.recordingPath(for: movieFileName))
                let keyPath = addMovie(movieFileName)
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
