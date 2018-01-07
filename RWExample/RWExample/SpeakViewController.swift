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

    @IBOutlet var legalAgreementLabel: UILabel!

    // MARK: -

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let projectData = RWFrameworkConfig.getConfigDataFromGroup(RWFrameworkConfig.ConfigGroup.project) as? NSDictionary {
            legalAgreementLabel.text = projectData["legal_agreement"] as! String?
        }
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }

    override func canPerformUnwindSegueAction(_ action: Selector, from fromViewController: UIViewController, withSender sender: Any) -> Bool {
        return true
    }
    
    @IBAction func unwindToSpeakViewController(sender: UIStoryboardSegue) {
        // let sourceViewController = sender.source
        // Pull any data from the view controller which initiated the unwind segue.
    }

}
