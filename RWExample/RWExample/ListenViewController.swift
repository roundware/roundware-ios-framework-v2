//
//  ListenViewController.swift
//  RWExample
//
//  Created by Joe Zobkiw on 9/4/17.
//  Copyright © 2017 Roundware. All rights reserved.
//

import UIKit
import Foundation
import RWFramework

class ListenViewController: UIViewController {
    
    // MARK: -

    @IBOutlet var playButton: UIButton!
    @IBOutlet var replayButton: UIButton!
    @IBOutlet var skipButton: UIButton!
    @IBOutlet var stopButton: UIButton!

    @IBOutlet var filterButton: UIButton!
    @IBOutlet var moreButton: UIButton! // Flag Recording, Block Recording, Block User (apiPostAssetsIdVotes)
    

    // MARK: -

    override func viewDidLoad() {
        super.viewDidLoad()
        
        playButton.isEnabled = true
        filterButton.isEnabled = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        RWFramework.sharedInstance.addDelegate(self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        RWFramework.sharedInstance.removeDelegate(self)
    }

    // MARK: -

    func updateUI() {
        let rwf = RWFramework.sharedInstance

        playButton.isEnabled = !rwf.isPlaying
        stopButton.isEnabled = rwf.isPlaying
        
        replayButton.isEnabled = rwf.isPlaying
        skipButton.isEnabled = rwf.isPlaying
        moreButton.isEnabled = rwf.isPlaying
    }
    
    @IBAction func play(_ sender: UIButton) {
        let rwf = RWFramework.sharedInstance
        rwf.play()
        updateUI()
    }
    
    @IBAction func stop(_ sender: UIButton) {
        let rwf = RWFramework.sharedInstance
        rwf.stop()
        updateUI()
    }
    
    @IBAction func filter(_ sender: UIButton) {
        
    }

    @IBAction func replay(_ sender: UIButton) {
        let rwf = RWFramework.sharedInstance
        rwf.replay()
    }

    @IBAction func skip(_ sender: UIButton) {
        let rwf = RWFramework.sharedInstance
        rwf.skip()
    }

    @IBAction func more(_ sender: UIButton) {

    }

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

}
