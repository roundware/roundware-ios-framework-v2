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
        
        updateUI()
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

        filterButton.isEnabled = true
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
    
    @IBAction func replay(_ sender: UIButton) {
        let rwf = RWFramework.sharedInstance
        rwf.replay()
    }

    @IBAction func skip(_ sender: UIButton) {
        let rwf = RWFramework.sharedInstance
        rwf.skip()
    }

    @IBAction func filter(_ sender: UIButton) {
        
    }
    
    @IBAction func more(_ sender: UIButton) {

    }

    // MARK: -
    
    override func canPerformUnwindSegueAction(_ action: Selector, from fromViewController: UIViewController, withSender sender: Any) -> Bool {
        return true
    }
    
    @IBAction func unwindToListenViewController(sender: UIStoryboardSegue) {
        // let sourceViewController = sender.source
        // Pull any data from the view controller which initiated the unwind segue.
    }
}
