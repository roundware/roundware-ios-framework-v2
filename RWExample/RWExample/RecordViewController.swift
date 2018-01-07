//
//  RecordViewController.swift
//  RWExample
//
//  Created by Joe Zobkiw on 12/26/17.
//  Copyright © 2017 Roundware. All rights reserved.
//

import UIKit
import Foundation
import RWFramework

class RecordViewController: UIViewController, RWFrameworkProtocol {
    
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var recordStopPlayButton: UIButton!
    @IBOutlet weak var uploadButton: UIButton!
    @IBOutlet weak var rerecordButton: UIButton!

    // MARK: -
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        RWFramework.sharedInstance.addDelegate(self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        RWFramework.sharedInstance.removeDelegate(self)
    }
    
    // MARK: -
    
    func updateUI() {
        let rwf = RWFramework.sharedInstance
        
        if rwf.hasRecording() && !rwf.isRecording() { // playback
            recordStopPlayButton.setTitle(rwf.isPlayingBack() ? "Stop" : "Play", for: .normal)
            recordStopPlayButton.isEnabled = true
            uploadButton.isEnabled = !rwf.isPlayingBack()
            rerecordButton.isEnabled = !rwf.isPlayingBack()
        } else {                // record
            recordStopPlayButton.setTitle(rwf.isRecording() ? "Stop" : "Record", for: .normal)
            recordStopPlayButton.isEnabled = true
            uploadButton.isEnabled = false
            rerecordButton.isEnabled = false
        }
    }

    @IBAction func recordStopPlay(_ sender: UIButton) {
        let rwf = RWFramework.sharedInstance
        
        if rwf.hasRecording() && !rwf.isRecording() { // playback
            if rwf.isPlayingBack() {
                rwf.stopPlayback()
            } else {
                rwf.startPlayback()
            }
        } else {                // record
            if rwf.isRecording() {
                rwf.stopRecording()
            } else {
                rwf.startRecording()
            }
        }
        
        updateUI()
    }
    
    @IBAction func upload(_ sender: UIButton) {
        let rwf = RWFramework.sharedInstance
        _ = rwf.addRecording()
        rwf.uploadAllMedia()
        performSegue(withIdentifier: "ThankYouViewController", sender: self)
    }

    @IBAction func rerecord(_ sender: UIButton) {
        let rwf = RWFramework.sharedInstance
        rwf.deleteRecording()
        updateUI()
    }
    
    func rwRecordingProgress(_ percentage: Double, maxDuration: TimeInterval, peakPower: Float, averagePower: Float) {
        var timeLeft = maxDuration - (maxDuration * percentage)
        timeLeft = timeLeft >= 0 ? timeLeft : 0
        timerLabel.text = String(format: "%.0f", timeLeft.rounded(.up))
    }

    func rwPlayingBackProgress(_ percentage: Double, duration: TimeInterval, peakPower: Float, averagePower: Float) {
        timerLabel.text = "..."
    }

    func rwAudioRecorderDidFinishRecording() {
        print("rwAudioRecorderDidFinishRecording")
        updateUI()
    }

    func rwAudioPlayerDidFinishPlaying() {
        print("rwAudioPlayerDidFinishPlaying")
        updateUI()
    }

    // MARK: -
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }

    override func canPerformUnwindSegueAction(_ action: Selector, from fromViewController: UIViewController, withSender sender: Any) -> Bool {
        return true
    }
    
    @IBAction func unwindToRecordViewController(sender: UIStoryboardSegue) {
        // let sourceViewController = sender.source
        // Pull any data from the view controller which initiated the unwind segue.
    }
    
}

