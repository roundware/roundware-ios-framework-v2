//
//  ViewController.swift
//  RWExample
//
//  Created by Joe Zobkiw on 1/24/15.
//  Copyright (c) 2015 Roundware. All rights reserved.
//

import UIKit
import RWFramework
import MobileCoreServices

class ViewController: UIViewController {

    // MARK: Actions and Outlets

    @IBOutlet var heartbeatButton: UIButton!
    @IBOutlet var statusTextView: UITextView!

    @IBOutlet var listenPlayButton: UIButton!
    @IBOutlet var listenNextButton: UIButton!
    @IBOutlet var listenCurrentButton: UIButton!

    @IBAction func listenTags(_ sender: UIButton) {
        RWFramework.sharedInstance.editListenTags()
    }

    @IBAction func listenPlay(_ sender: UIButton) {
        let rwf = RWFramework.sharedInstance
        rwf.isPlaying ? rwf.stop() : rwf.play()
        listenPlayButton.setTitle(rwf.isPlaying ? "Stop" : "Play", for: UIControlState())
    }

    @IBAction func listenNext(_ sender: UIButton) {
        RWFramework.sharedInstance.next()
    }

    @IBAction func listenCurrent(_ sender: UIButton) {
        RWFramework.sharedInstance.current()
    }

    @IBOutlet var speakUpload: UIButton!
    @IBOutlet var speakProgress: UIProgressView!
    @IBOutlet var speakRecordButton: UIButton!
    @IBOutlet var speakPlayButton: UIButton!
    @IBOutlet var speakSubmitButton: UIButton!

    @IBAction func speakUpload(_ sender: UIButton) {
        RWFramework.sharedInstance.uploadAllMedia()
    }

    @IBAction func speakTags(_ sender: UIButton) {
        RWFramework.sharedInstance.editSpeakTags()
    }

    @IBAction func speakRecord(_ sender: UIButton) {
        speakProgress.setProgress(0, animated: false)
        let rwf = RWFramework.sharedInstance
        rwf.stop()
        rwf.isRecording() ? rwf.stopRecording() : rwf.startRecording()
        speakRecordButton.setTitle(rwf.isRecording() ? "Stop" : "Record", for: UIControlState())
    }

    @IBAction func speakPlay(_ sender: UIButton) {
        speakProgress.setProgress(0, animated: false)
        let rwf = RWFramework.sharedInstance
        rwf.stop()
        rwf.isPlayingBack() ? rwf.stopPlayback() : rwf.startPlayback()
        speakPlayButton.setTitle(rwf.isPlayingBack() ? "Stop" : "Play", for: UIControlState())
    }

    @IBAction func speakSubmit(_ sender: UIButton) {
        let rwf = RWFramework.sharedInstance
        _ = rwf.addRecording("This is my recording!")
    }

    @IBAction func speakImage(_ sender: UIButton) {
        let rwf = RWFramework.sharedInstance
        rwf.doImage()
    }

    @IBAction func speakPhotoLibrary(_ sender: UIButton) {
        let rwf = RWFramework.sharedInstance
        rwf.doPhotoLibrary([kUTTypeImage as String])
    }

    @IBAction func speakMovie(_ sender: UIButton) {
        let rwf = RWFramework.sharedInstance
        rwf.doMovie()
    }

    @IBAction func speakText(_ sender: UIButton) {
        let rwf = RWFramework.sharedInstance
        _ = rwf.addText("Hello, world!")
    }

    @IBAction func speakDelete(_ sender: UIButton) {
        let rwf = RWFramework.sharedInstance
        rwf.deleteRecording()
    }

    // MARK: View
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        listenPlayButton.isEnabled = false
        listenNextButton.isEnabled = false
        listenCurrentButton.isEnabled = false

        let rwf = RWFramework.sharedInstance
        rwf.addDelegate(self)
        rwf.start(false)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let rwf = RWFramework.sharedInstance
        print(rwf.debugInfo())
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
    }

    override var shouldAutorotate : Bool {
        return false
    }
}

extension ViewController: RWFrameworkProtocol {

    func rwUpdateStatus(_ message: String) {
        self.statusTextView.text = self.statusTextView.text + "\r\n" + message
        self.statusTextView.scrollRangeToVisible(NSMakeRange(self.statusTextView.text.lengthOfBytes(using: String.Encoding.utf8), 0))
    }

    func rwUpdateApplicationIconBadgeNumber(_ count: Int) {
        UIApplication.shared.applicationIconBadgeNumber = count
    }

    func rwGetProjectsIdSuccess(_ data: Data?) {

        let rwf = RWFramework.sharedInstance
        _ = rwf.requestWhenInUseAuthorizationForLocation()

        // You can now access the project data
        if let projectData = RWFrameworkConfig.getConfigDataFromGroup(RWFrameworkConfig.ConfigGroup.project) as? NSDictionary {
//            println(projectData)


            // Get all assets for the project, can filter by adding other keys to dict as documented for GET api/2/assets/
            let project_id = projectData["id"] as! NSNumber
            let dict: [String:String] = ["project_id": project_id.stringValue]
            rwf.apiGetAssets(dict, success: { (data) -> Void in
                if (data != nil) {
//                    let d = JSON(data: data!)
//                    println(d)
                }
            }) { (error) -> Void in
                print(error)
            }

//            // Get specific asset info
//            rwf.apiGetAssetsId("99", success: { (data) -> Void in
//                if (data != nil) {
//                    let d = JSON(data: data!)
////                    println(d)
//                }
//            }) { (error) -> Void in
//                println(error)
//            }
        }
    }

    func rwGetStreamsIdCurrentSuccess(_ data: Data?) {
//        let d = JSON(data: data!)
//        println(d)
    }

    func rwPostStreamsSuccess(_ data: Data?) {
        DispatchQueue.main.async(execute: { () -> Void in
            self.listenPlayButton.isEnabled = true
            self.listenNextButton.isEnabled = true
            self.listenCurrentButton.isEnabled = true
        })
    }

    func rwPostStreamsIdHeartbeatSuccess(_ data: Data?) {
        DispatchQueue.main.async(execute: { () -> Void in
            UIView.animate(withDuration: 0.5, animations: { () -> Void in
                self.heartbeatButton.alpha = 0.0
            }, completion: { (Bool) -> Void in
                self.heartbeatButton.alpha = 1.0
            })
        })
    }

    func rwImagePickerControllerDidFinishPickingMedia(_ info: [AnyHashable: Any], path: String) {
        print(path)
        print(info)
        let rwf = RWFramework.sharedInstance
        rwf.setImageDescription(path, description: "Hello, This is an image!")
    }

    func rwRecordingProgress(_ percentage: Double, maxDuration: TimeInterval, peakPower: Float, averagePower: Float) {
        speakProgress.setProgress(Float(percentage), animated: true)
    }

    func rwPlayingBackProgress(_ percentage: Double, duration: TimeInterval, peakPower: Float, averagePower: Float) {
        speakProgress.setProgress(Float(percentage), animated: true)
    }

    func rwAudioRecorderDidFinishRecording() {
        let rwf = RWFramework.sharedInstance
        speakRecordButton.setTitle(rwf.isRecording() ? "Stop" : "Record", for: UIControlState())
        speakProgress.setProgress(0, animated: false)
    }

    func rwAudioPlayerDidFinishPlaying() {
        let rwf = RWFramework.sharedInstance
        speakPlayButton.setTitle(rwf.isPlayingBack() ? "Stop" : "Play", for: UIControlState())
        speakProgress.setProgress(0, animated: false)
    }
}
