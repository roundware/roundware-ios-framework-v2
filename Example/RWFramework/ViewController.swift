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
import SwiftyJSON

class ViewController: UIViewController {
    
    // MARK: Actions and Outlets
    
    @IBOutlet var heartbeatButton: UIButton!
    @IBOutlet var statusTextView: UITextView!
    
    @IBOutlet var listenPlayButton: UIButton!
    @IBOutlet var listenNextButton: UIButton!
    @IBOutlet var listenCurrentButton: UIButton!
    
    
    @IBAction func listenPlay(_ sender: UIButton) {
        let rwf = RWFramework.sharedInstance
        rwf.isPlaying ? rwf.stop() : rwf.play()
        listenPlayButton.setTitle(rwf.isPlaying ? "Stop" : "Play", for: UIControlState.normal)
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
        RWFramework.sharedInstance.uploadAllMedia(tagIdsAsString: "")
    }
    
    @IBAction func speakTags(_ sender: UIButton) {
        //TODO show tags available
        //RWFramework.sharedInstance.editSpeakTags()
    }
    
    @IBAction func speakRecord(_ sender: UIButton) {
        speakProgress.setProgress(0, animated: false)
        let rwf = RWFramework.sharedInstance
        rwf.stop()
        rwf.isRecording() ? rwf.stopRecording() : rwf.startRecording()
        speakRecordButton.setTitle(rwf.isRecording() ? "Stop" : "Record", for: UIControlState.normal)
    }
    
    @IBAction func speakPlay(_ sender: UIButton) {
        speakProgress.setProgress(0, animated: false)
        let rwf = RWFramework.sharedInstance
        rwf.stop()
        rwf.isPlayingBack() ? rwf.stopPlayback() : rwf.startPlayback()
        speakPlayButton.setTitle(rwf.isPlayingBack() ? "Stop" : "Play", for: UIControlState.normal)
    }
    
    @IBAction func speakSubmit(_ sender: UIButton) {
        let rwf = RWFramework.sharedInstance
        rwf.addRecording(description: "This is my recording!")
    }
    
    @IBAction func speakImage(_ sender: UIButton) {
        let rwf = RWFramework.sharedInstance
        rwf.doImage()
    }
    
    @IBAction func speakPhotoLibrary(_ sender: UIButton) {
        let rwf = RWFramework.sharedInstance
        rwf.doPhotoLibrary(mediaTypes: [kUTTypeImage as String])
    }
    
    @IBAction func speakMovie(_ sender: UIButton) {
        let rwf = RWFramework.sharedInstance
        rwf.doMovie()
    }
    
    @IBAction func speakText(_ sender: UIButton) {
        let rwf = RWFramework.sharedInstance
        rwf.addText(string: "Hello, world!")
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
        rwf.addDelegate(object: self)
        rwf.start()
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
    
    override var shouldAutorotate: Bool {
        return false
    }
}

extension ViewController: RWFrameworkProtocol {

    //deprecated presently
    func rwUpdateStatus(message: String) {
        self.statusTextView.text = self.statusTextView.text + "\r\n" + message
        self.statusTextView.scrollRangeToVisible(NSMakeRange(self.statusTextView.text.lengthOfBytes(using: String.Encoding.utf8), 0))
    }

    func rwUpdateApplicationIconBadgeNumber(count: Int) {
        UIApplication.shared.applicationIconBadgeNumber = count
    }
    func rwPostSessionsFailure(error: NSError?) {
        print("fail")
        dump(error)
    }

    func rwPostSessionsSuccess(data: NSData?) {
        let rwf = RWFramework.sharedInstance
        if let fileUrl = Bundle.main.url(forResource: "RWFramework", withExtension: "plist"),
            let data = try? Data(contentsOf: fileUrl) {
            if let result = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as! [String: Any] {
                let id : String = "\(result["project_id"]!)"
                rwf.setProjectId(project_id: id )
            }
        }
        if let path = Bundle.main.path(forResource: "RWFramework", ofType: "plist"){
            let info  = NSDictionary(contentsOfFile: path) as! [String:AnyObject?]

        }
    }

    func rwGetProjectsIdSuccess(data: NSData?) {
        
        let rwf = RWFramework.sharedInstance
        rwf.requestWhenInUseAuthorizationForLocation()
        
        // You can now access the project data
        if let projectData = RWFrameworkConfig.getConfigDataFromGroup(group: RWFrameworkConfig.ConfigGroup.Project) as? NSDictionary {
            //            println(projectData)
            
            
            // Get all assets for the project, can filter by adding other keys to dict as documented for GET api/2/assets/
            let project_id = projectData["project_id"] as! NSNumber
            let dict: [String:String] = ["project_id": project_id.stringValue]
            rwf.apiGetAssets(dict: dict, success: { (data) -> Void in
                if (data != nil) {
                    _ = JSON(data: data! as Data)
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
    
    func rwGetStreamsIdCurrentSuccess(data: NSData?) {
        _ = JSON(data: data! as Data)
        //        println(d)
    }
    
    func rwPostStreamsSuccess(data: NSData?) {
        DispatchQueue.main.async(execute: { () -> Void in
            self.listenPlayButton.isEnabled = true
            self.listenNextButton.isEnabled = true
            self.listenCurrentButton.isEnabled = true
        })
    }
    
    func rwPostStreamsIdHeartbeatSuccess(data: NSData?) {
        DispatchQueue.main.async(execute: { () -> Void in
            UIView.animate(withDuration: 0.5, animations: { () -> Void in
                self.heartbeatButton.alpha = 0.0
                }, completion: { (Bool) -> Void in
                    self.heartbeatButton.alpha = 1.0
            })
        })
    }
    
    func rwImagePickerControllerDidFinishPickingMedia(info: [String : AnyObject], path: String) {
        print(path)
        print(info)
        let rwf = RWFramework.sharedInstance
        rwf.setImageDescription(string: path, description: "Hello, This is an image!")
    }
    
    func rwRecordingProgress(percentage: Double, maxDuration: TimeInterval, peakPower: Float, averagePower: Float) {
        print("Recording progress")
        speakProgress.setProgress(Float(percentage), animated: true)
    }
    
    func rwPlayingBackProgress(percentage: Double, duration: TimeInterval, peakPower: Float, averagePower: Float) {
        print("Playback progress")
        speakProgress.setProgress(Float(percentage), animated: true)
    }
    
    func rwAudioRecorderDidFinishRecording() {
        let rwf = RWFramework.sharedInstance
        print("Finished recording")
        speakRecordButton.setTitle(rwf.isRecording() ? "Stop" : "Record", for: UIControlState.normal)
        speakProgress.setProgress(0, animated: false)
    }
    
    func rwAudioPlayerDidFinishPlaying() {
        let rwf = RWFramework.sharedInstance
        print("Finished playing")
        speakPlayButton.setTitle(rwf.isPlayingBack() ? "Stop" : "Play", for: UIControlState.normal)
        speakProgress.setProgress(0, animated: false)
    }
    
    func rwGetProjectsIdTagsSuccess(data: NSData?) {
        print("Tags received")
        let dict = JSON(data: data! as Data)
        let tagsArray = dict["tags"]
        for (_, dict): (String, JSON) in tagsArray {
            let value = dict["value"]
            print("\(value)")
        }
    }
    func rwGetProjectsIdUIGroupsSuccess(data: NSData?) {
        print("UI Groups received")
        let dict = JSON(data: data! as Data)
        let uiGroupsArray = dict["ui_groups"]
        for (_, dict): (String, JSON) in uiGroupsArray {
            let header_text_loc = dict["header_text_loc"]
            print("\(header_text_loc)")
        }
    }
}
