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

    @IBOutlet var tagsButton: UIButton!
    @IBOutlet var playButton: UIButton!
    @IBOutlet var skipButton: UIButton!
    @IBOutlet var stopButton: UIButton!

    // MARK: -

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
