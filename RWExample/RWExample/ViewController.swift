//
//  ViewController.swift
//  RWExample
//
//  Created by Joe Zobkiw on 1/24/15.
//  Copyright (c) 2015 Roundware. All rights reserved.
//

import UIKit
import Foundation
import RWFramework
import MapKit

class ViewController: UIViewController, MKMapViewDelegate {

    // MARK: Actions and Outlets

    @IBOutlet var listenButton: UIButton!
    @IBOutlet var speakButton: UIButton!
    @IBOutlet var heartbeatButton: UIButton!
    @IBOutlet var map: MKMapView!

//    @IBAction func listenTags(_ sender: UIButton) {
//        RWFramework.sharedInstance.editListenTags()
//    }
//
//    @IBAction func listenPlay(_ sender: UIButton) {
//        let rwf = RWFramework.sharedInstance
//        rwf.isPlaying ? rwf.stop() : rwf.play()
//        listenPlayButton.setTitle(rwf.isPlaying ? "Stop" : "Play", for: UIControlState())
//    }
//
//    @IBAction func listenSkip(_ sender: UIButton) {
//        RWFramework.sharedInstance.skip()
//    }


//    @IBAction func speakUpload(_ sender: UIButton) {
//        RWFramework.sharedInstance.uploadAllMedia()
//    }
//
//    @IBAction func speakTags(_ sender: UIButton) {
//        RWFramework.sharedInstance.editSpeakTags()
//    }
//
//    @IBAction func speakRecord(_ sender: UIButton) {
//        speakProgress.setProgress(0, animated: false)
//        let rwf = RWFramework.sharedInstance
//        rwf.stop()
//        rwf.isRecording() ? rwf.stopRecording() : rwf.startRecording()
//        speakRecordButton.setTitle(rwf.isRecording() ? "Stop" : "Record", for: UIControlState())
//    }
//
//    @IBAction func speakPlay(_ sender: UIButton) {
//        speakProgress.setProgress(0, animated: false)
//        let rwf = RWFramework.sharedInstance
//        rwf.stop()
//        rwf.isPlayingBack() ? rwf.stopPlayback() : rwf.startPlayback()
//        speakPlayButton.setTitle(rwf.isPlayingBack() ? "Stop" : "Play", for: UIControlState())
//    }
//
//    @IBAction func speakSubmit(_ sender: UIButton) {
//        let rwf = RWFramework.sharedInstance
//        _ = rwf.addRecording("This is my recording!")
//    }
//
//    @IBAction func speakImage(_ sender: UIButton) {
//        let rwf = RWFramework.sharedInstance
//        rwf.doImage()
//    }
//
//    @IBAction func speakPhotoLibrary(_ sender: UIButton) {
//        let rwf = RWFramework.sharedInstance
//        rwf.doPhotoLibrary([kUTTypeImage as String])
//    }
//
//    @IBAction func speakMovie(_ sender: UIButton) {
//        let rwf = RWFramework.sharedInstance
//        rwf.doMovie()
//    }
//
//    @IBAction func speakText(_ sender: UIButton) {
//        let rwf = RWFramework.sharedInstance
//        _ = rwf.addText("Hello, world!")
//    }
//
//    @IBAction func speakDelete(_ sender: UIButton) {
//        let rwf = RWFramework.sharedInstance
//        rwf.deleteRecording()
//    }

    // MARK: View
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.map.delegate = self
        
        RWFramework.sharedInstance.start(false) // You may choose to call this in the AppDelegate
    }

    override func viewWillAppear(_ animated: Bool) {
        RWFramework.sharedInstance.addDelegate(self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        RWFramework.sharedInstance.removeDelegate(self)
    }

    // MARK: -
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        let span = MKCoordinateSpanMake(0.01, 0.01)
        let region = MKCoordinateRegionMake(mapView.userLocation.coordinate, span)
        mapView.setRegion(region, animated: true)
    }
    
    // MARK: -
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        print(segue)
    }
    

}

extension ViewController: RWFrameworkProtocol {

    func rwGetProjectsIdSuccess(_ data: Data?) {

        // You can now access the project information
        if let projectData = RWFrameworkConfig.getConfigDataFromGroup(RWFrameworkConfig.ConfigGroup.project) as? NSDictionary {
            let listen_enabled = projectData["listen_enabled"] as! Bool
            if (listen_enabled) {
                self.listenButton.isEnabled = true
            }
            
            let speak_enabled = projectData["speak_enabled"] as! Bool
            if (speak_enabled) {
                self.speakButton.isEnabled = true
            }
        }
    }

    func rwPostStreamsIdHeartbeatSuccess(_ data: Data?) {
        UIView.animate(withDuration: 0.5, animations: { () -> Void in
            self.heartbeatButton.alpha = 0.0
        }, completion: { (Bool) -> Void in
            self.heartbeatButton.alpha = 1.0
        })
    }

//    func rwImagePickerControllerDidFinishPickingMedia(_ info: [AnyHashable: Any], path: String) {
//        print(path)
//        print(info)
//        let rwf = RWFramework.sharedInstance
//        rwf.setImageDescription(path, description: "Hello, This is an image!")
//    }
//
//    func rwRecordingProgress(_ percentage: Double, maxDuration: TimeInterval, peakPower: Float, averagePower: Float) {
//        speakProgress.setProgress(Float(percentage), animated: true)
//    }
//
//    func rwPlayingBackProgress(_ percentage: Double, duration: TimeInterval, peakPower: Float, averagePower: Float) {
//        speakProgress.setProgress(Float(percentage), animated: true)
//    }
//
//    func rwAudioRecorderDidFinishRecording() {
//        let rwf = RWFramework.sharedInstance
//        speakRecordButton.setTitle(rwf.isRecording() ? "Stop" : "Record", for: UIControlState())
//        speakProgress.setProgress(0, animated: false)
//    }
//
//    func rwAudioPlayerDidFinishPlaying() {
//        let rwf = RWFramework.sharedInstance
//        speakPlayButton.setTitle(rwf.isPlayingBack() ? "Stop" : "Play", for: UIControlState())
//        speakProgress.setProgress(0, animated: false)
//    }
}
