//
//  SpeakViewController.swift
//  RWExample
//
//  Created by Joe Zobkiw on 9/4/17.
//  Copyright © 2017 Roundware. All rights reserved.
//

import UIKit
import Foundation
import RWFramework

class SpeakViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        RWFramework.sharedInstance.addDelegate(self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        RWFramework.sharedInstance.removeDelegate(self)
    }
    
}

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
