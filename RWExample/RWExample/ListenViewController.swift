//
//  ListenViewController.swift
//  RWExample
//
//  Created by Joe Zobkiw on 9/4/17.
//  Copyright © 2017 Roundware. All rights reserved.
//

import UIKit
import Foundation
import AVFoundation
import RWFramework

class ListenViewController: UIViewController {
    
    // MARK: -

    @IBOutlet var playButton: UIButton!
    @IBOutlet var replayButton: UIButton!
    @IBOutlet var skipButton: UIButton!
    @IBOutlet var stopButton: UIButton!

    @IBOutlet var filterButton: UIButton!
    @IBOutlet var moreButton: UIButton! // Flag Recording, Block Recording, Block User (apiPostAssetsIdVotes)
    
    var mostRecentAssetID: String? {
        willSet {
            moreButton.isEnabled = newValue != nil
        }
    }
    
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

        playButton.isEnabled = !rwf.isPlaying
        stopButton.isEnabled = rwf.isPlaying
        
        replayButton.isEnabled = rwf.isPlaying
        skipButton.isEnabled = rwf.isPlaying
        moreButton.isEnabled = rwf.isPlaying && mostRecentAssetID != nil

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
        guard mostRecentAssetID != nil else {
            return
        }
        let assetID = mostRecentAssetID! // Use the one that was playing when we tapped the button, not any subsequent updates
        
        let ac = UIAlertController(title: "More", message: "Report Recordings or Users", preferredStyle: .alert)
        
        ac.addAction(UIAlertAction(title: "Block User", style: .default, handler: {(alert: UIAlertAction!) in
            RWFramework.sharedInstance.apiPostAssetsIdVotes(assetID, vote_type: "block_user", success: { (data) in
                print("block_user success")
            }, failure: { (error) in
                print("block_user failure")
            })
        }))
        
        ac.addAction(UIAlertAction(title: "Block Asset", style: .default, handler: {(alert: UIAlertAction!) in
            RWFramework.sharedInstance.apiPostAssetsIdVotes(assetID, vote_type: "block_asset", success: { (data) in
                print("block_asset success")
            }, failure: { (error) in
                print("block_asset failure")
            })
        }))

        ac.addAction(UIAlertAction(title: "Flag Recording", style: .default, handler: {(alert: UIAlertAction!) in
            RWFramework.sharedInstance.apiPostAssetsIdVotes(assetID, vote_type: "flag", success: { (data) in
                print("flag success")
            }, failure: { (error) in
                print("flag failure")
            })
        }))

        ac.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
        
        self.present(ac, animated: true, completion: nil)
    }

    // MARK: -
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }

    override func canPerformUnwindSegueAction(_ action: Selector, from fromViewController: UIViewController, withSender sender: Any) -> Bool {
        return true
    }
    
    @IBAction func unwindToListenViewController(sender: UIStoryboardSegue) {
        // let sourceViewController = sender.source
        // Pull any data from the view controller which initiated the unwind segue.
    }
    
}

// MARK: -

extension ListenViewController: RWFrameworkProtocol {
    
    /*
     Optional("Roundware - stream_started=True")
     Optional("Roundware - audiotrack=1&tags=3%2C5%2C1&remaining=27&asset=102")
     Optional("Roundware - audiotrack=1&remaining=27&complete=True&asset=102")
     Optional("Roundware - audiotrack=1&tags=3%2C7%2C1&remaining=26&asset=9549")
     Optional("Roundware - audiotrack=1&remaining=26&complete=True&asset=9549")
     Optional("Roundware - audiotrack=1&tags=3%2C5%2C1&remaining=25&asset=9527")
     Optional("Roundware - audiotrack=1&remaining=25&complete=True&asset=9527")
     */
    func rwObserveValueForKeyPath(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if (keyPath == "timedMetadata") {
            if let avPlayerItem = object as! AVPlayerItem?, let timedMetadata = avPlayerItem.timedMetadata {
                for item in timedMetadata {
                    let stringValue = item.stringValue // see comment above for format of what to expect from this field
                    //print("\(String(describing: stringValue))")
                    
                    let components = stringValue?.components(separatedBy: " - ")
                    //print("\(String(describing: components))")
                    
                    if (components?.count == 2 && components?.first == "Roundware") {
                        let fakeurl = "http://example.com?" + (components?.last)!
                        if let parameters = URLComponents(string: fakeurl), let queryItems = parameters.queryItems {
                            let asset = queryItems.filter({$0.name == "asset"}).first?.value
                            print("\(String(describing: asset))")
                            mostRecentAssetID = asset
                        }
                    }
                }
            }
        }
    }
}
