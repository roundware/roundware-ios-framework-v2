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
    
    @IBAction func listenTags(sender: UIButton) {
        RWFramework.sharedInstance.editListenTags()
    }
    
    @IBAction func listenPlay(sender: UIButton) {
        let rwf = RWFramework.sharedInstance
        rwf.isPlaying ? rwf.stop() : rwf.play()
        listenPlayButton.setTitle(rwf.isPlaying ? "Stop" : "Play", forState: UIControlState.Normal)
    }
    
    @IBAction func listenNext(sender: UIButton) {
        RWFramework.sharedInstance.next()
    }
    
    @IBAction func listenCurrent(sender: UIButton) {
        RWFramework.sharedInstance.current()
    }
    
    @IBOutlet var speakUpload: UIButton!
    @IBOutlet var speakProgress: UIProgressView!
    @IBOutlet var speakRecordButton: UIButton!
    @IBOutlet var speakPlayButton: UIButton!
    @IBOutlet var speakSubmitButton: UIButton!
    
    @IBAction func speakUpload(sender: UIButton) {
        RWFramework.sharedInstance.uploadAllMedia()
    }
    
    @IBAction func speakTags(sender: UIButton) {
        RWFramework.sharedInstance.editSpeakTags()
    }
    
    @IBAction func speakRecord(sender: UIButton) {
        speakProgress.setProgress(0, animated: false)
        let rwf = RWFramework.sharedInstance
        rwf.stop()
        rwf.isRecording() ? rwf.stopRecording() : rwf.startRecording()
        speakRecordButton.setTitle(rwf.isRecording() ? "Stop" : "Record", forState: UIControlState.Normal)
    }
    
    @IBAction func speakPlay(sender: UIButton) {
        speakProgress.setProgress(0, animated: false)
        let rwf = RWFramework.sharedInstance
        rwf.stop()
        rwf.isPlayingBack() ? rwf.stopPlayback() : rwf.startPlayback()
        speakPlayButton.setTitle(rwf.isPlayingBack() ? "Stop" : "Play", forState: UIControlState.Normal)
    }
    
    @IBAction func speakSubmit(sender: UIButton) {
        let rwf = RWFramework.sharedInstance
        rwf.addRecording("This is my recording!")
    }
    
    @IBAction func speakImage(sender: UIButton) {
        let rwf = RWFramework.sharedInstance
        rwf.doImage()
    }
    
    @IBAction func speakPhotoLibrary(sender: UIButton) {
        let rwf = RWFramework.sharedInstance
        rwf.doPhotoLibrary([kUTTypeImage as String])
    }
    
    @IBAction func speakMovie(sender: UIButton) {
        let rwf = RWFramework.sharedInstance
        rwf.doMovie()
    }
    
    @IBAction func speakText(sender: UIButton) {
        let rwf = RWFramework.sharedInstance
        rwf.addText("Hello, world!")
    }
    
    @IBAction func speakDelete(sender: UIButton) {
        let rwf = RWFramework.sharedInstance
        rwf.deleteRecording()
    }
    
    // MARK: View
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        listenPlayButton.enabled = false
        listenNextButton.enabled = false
        listenCurrentButton.enabled = false
        
        let rwf = RWFramework.sharedInstance
        rwf.addDelegate(self)
        rwf.start(false)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        let rwf = RWFramework.sharedInstance
        print(rwf.debugInfo())
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func shouldAutorotate() -> Bool {
        return false
    }
}

extension ViewController: RWFrameworkProtocol {
    
    func rwUpdateStatus(message: String) {
        self.statusTextView.text = self.statusTextView.text + "\r\n" + message
        self.statusTextView.scrollRangeToVisible(NSMakeRange(self.statusTextView.text.lengthOfBytesUsingEncoding(NSUTF8StringEncoding), 0))
    }
    
    func rwUpdateApplicationIconBadgeNumber(count: Int) {
        UIApplication.sharedApplication().applicationIconBadgeNumber = count
    }
    
    func rwGetProjectsIdSuccess(data: NSData?) {
        
        let rwf = RWFramework.sharedInstance
        rwf.requestWhenInUseAuthorizationForLocation()
        
        // You can now access the project data
        if let projectData = RWFrameworkConfig.getConfigDataFromGroup(RWFrameworkConfig.ConfigGroup.Project) as? NSDictionary {
            //            println(projectData)
            
            
            // Get all assets for the project, can filter by adding other keys to dict as documented for GET api/2/assets/
            let project_id = projectData["project_id"] as! NSNumber
            let dict: [String:String] = ["project_id": project_id.stringValue]
            rwf.apiGetAssets(dict, success: { (data) -> Void in
                if (data != nil) {
                    _ = JSON(data: data!)
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
        _ = JSON(data: data!)
        //        println(d)
    }
    
    func rwPostStreamsSuccess(data: NSData?) {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.listenPlayButton.enabled = true
            self.listenNextButton.enabled = true
            self.listenCurrentButton.enabled = true
        })
    }
    
    func rwPostStreamsIdHeartbeatSuccess(data: NSData?) {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            UIView.animateWithDuration(0.5, animations: { () -> Void in
                self.heartbeatButton.alpha = 0.0
                }, completion: { (Bool) -> Void in
                    self.heartbeatButton.alpha = 1.0
            })
        })
    }
    
    func rwImagePickerControllerDidFinishPickingMedia(info: [NSObject : AnyObject], path: String) {
        print(path)
        print(info)
        let rwf = RWFramework.sharedInstance
        rwf.setImageDescription(path, description: "Hello, This is an image!")
    }
    
    func rwRecordingProgress(percentage: Double, maxDuration: NSTimeInterval, peakPower: Float, averagePower: Float) {
        speakProgress.setProgress(Float(percentage), animated: true)
    }
    
    func rwPlayingBackProgress(percentage: Double, duration: NSTimeInterval, peakPower: Float, averagePower: Float) {
        speakProgress.setProgress(Float(percentage), animated: true)
    }
    
    func rwAudioRecorderDidFinishRecording() {
        let rwf = RWFramework.sharedInstance
        speakRecordButton.setTitle(rwf.isRecording() ? "Stop" : "Record", forState: UIControlState.Normal)
        speakProgress.setProgress(0, animated: false)
    }
    
    func rwAudioPlayerDidFinishPlaying() {
        let rwf = RWFramework.sharedInstance
        speakPlayButton.setTitle(rwf.isPlayingBack() ? "Stop" : "Play", forState: UIControlState.Normal)
        speakProgress.setProgress(0, animated: false)
    }
}