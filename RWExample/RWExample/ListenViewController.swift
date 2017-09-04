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
