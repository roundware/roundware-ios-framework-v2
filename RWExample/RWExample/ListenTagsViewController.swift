//
//  ListenTagsViewController.swift
//  RWExample
//
//  Created by Joe Zobkiw on 9/23/17.
//  Copyright © 2017 Roundware. All rights reserved.
//

import UIKit
import Foundation
import RWFramework

class ListenTagsViewController: UIViewController {

    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    var uigroupids = RWFramework.sharedInstance.getUIGroupIDs("listen")
    var tagcategories: [[Int:String]]?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        segmentedControl.removeAllSegments()
        tagcategories = RWFramework.sharedInstance.getFilteredTagCategoryNamesAndIDs(uigroupids!)
        if tagcategories?.count == 0 {
            print("tagcategories.count = 0")
        }
        for tagcategory in tagcategories! {
            segmentedControl.insertSegment(withTitle: tagcategory[tagcategory.keys.first!], at: segmentedControl.numberOfSegments, animated: false)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.performSegue(withIdentifier: "unwindToListenViewController", sender: self)
    }
    
    @IBAction func valueChanged(_ sender: UISegmentedControl) {
        print(sender.selectedSegmentIndex)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }

}
