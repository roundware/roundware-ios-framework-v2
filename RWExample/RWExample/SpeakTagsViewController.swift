//
//  SpeakTagsViewController.swift
//  RWExample
//
//  Created by Joe Zobkiw on 11/22/17.
//  Copyright © 2017 Roundware. All rights reserved.
//

import UIKit
import Foundation
import RWFramework

class SpeakTagsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    // getUIConfig provides a simplified UIConfig struct that allows the UI to get to what it needs without complex parsing
    var uiconfig = RWFramework.sharedInstance.getUIConfig()
    // getSpeakIDsSet provides a Set of the currently selected IDs within the UIConfig struct
    var selectedIDs:Set? = Set<Int>() // Start with an empty set each time // RWFramework.sharedInstance.getSpeakTagsSet()
    
    var nextButton:UIBarButtonItem?
    
    required init?(coder aDecoder: NSCoder) {
        // Make sure to set the current speak IDs to our default (empty) set
        RWFramework.sharedInstance.setSpeakIDsSet(selectedIDs!)
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.nextButton = UIBarButtonItem(title: "Next".localizedCapitalized, style: UIBarButtonItemStyle.plain, target: self, action: #selector(tapNextButton))
        self.navigationItem.rightBarButtonItem = nextButton
        self.nextButton?.isEnabled = false
        
        // Update the UI by adding the proper number of segments named appropriately, select the first one and update the header label.
        segmentedControl.removeAllSegments()
        if let uiconfig = self.uiconfig {
            for speak in uiconfig.speak {
                segmentedControl.insertSegment(withTitle: speak.group_short_name, at: segmentedControl.numberOfSegments, animated: false)
            }
            segmentedControl.selectedSegmentIndex = 0
            updateHeaderLabel()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        RWFramework.sharedInstance.addDelegate(self)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        RWFramework.sharedInstance.removeDelegate(self)
//        self.performSegue(withIdentifier: "unwindToSpeakViewController", sender: self)
    }
    
    // When the segment is tapped, update the table and header label for that item
    @IBAction func valueChanged(_ sender: UISegmentedControl) {
        tableView.reloadData()
        updateHeaderLabel()
        self.nextButton?.isEnabled = true
   }
    
    // MARK: -
    
    @objc func tapNextButton() {
        if segmentedControl.selectedSegmentIndex < segmentedControl.numberOfSegments-1 {
            segmentedControl.selectedSegmentIndex = segmentedControl.selectedSegmentIndex+1
            valueChanged(segmentedControl)
            self.nextButton?.isEnabled = false
        } else {
            performSegue(withIdentifier: "RecordViewController", sender: self)
        }
    }
    
    // MARK: -
    
    func updateHeaderLabel() {
        guard uiconfig != nil else {
            return
        }
        headerLabel.text = uiconfig!.speak[segmentedControl.selectedSegmentIndex].header_display_text
    }
    
    func numTableViewSelections() -> Int {
        if let indexPathsForSelectedRows = tableView.indexPathsForSelectedRows {
            return indexPathsForSelectedRows.count
        }
        return 0
    }
    
    // MARK: - UITableView
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard uiconfig != nil, selectedIDs != nil, segmentedControl.selectedSegmentIndex != UISegmentedControlNoSegment else {
            return 0
        }
        
        let display_items = RWFramework.sharedInstance.getValidDisplayItems(uiconfig!.speak, index: segmentedControl.selectedSegmentIndex, tags: selectedIDs!)

        var numberOfRowsInSection = 0
        for display_item in display_items {
            if display_item.parent_id == nil {
                numberOfRowsInSection += 1
            } else {
                if let id = RWFramework.sharedInstance.getIDOfDisplayItemParent(display_item, group: uiconfig!.speak) {
                    if (selectedIDs!.contains(id)) {
                        numberOfRowsInSection += 1
                    }
                }
            }
        }
        
        return numberOfRowsInSection
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as UITableViewCell
        guard uiconfig != nil, selectedIDs != nil, segmentedControl.selectedSegmentIndex != UISegmentedControlNoSegment else {
            return cell
        }
        
        // Populate the cell with tag_display_text and checkmark if needed
        let display_items = RWFramework.sharedInstance.getValidDisplayItems(uiconfig!.speak, index: segmentedControl.selectedSegmentIndex, tags: selectedIDs!)
        let display_item = display_items[indexPath.row]
        
        cell.textLabel?.text = display_item.tag_display_text
        let selected = selectedIDs!.contains(display_item.id)
        cell.accessoryType = selected == true ? .checkmark : .none
        
        // Tell the table the cell is selected or not so didDeselectRowAt is called on first tap
        if selected {
            tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        }
        
        return cell
    }
    
    // When selecting and deselecting, the table already has allowsMultipleSelection set properly for the current segment
    // but we still have to manually take into account single/min_one/multi for some cases
    //
    // single = 1 selection only (required)
    // min_one = must have at least one selected
    // multi = like min_one but can have zero selections (aka min_zero)
    
    func tableView(_ tableView: UITableView, willDeselectRowAt indexPath: IndexPath) -> IndexPath? {
        guard uiconfig != nil else {
            return indexPath
        }
        
        let group = uiconfig!.speak[segmentedControl.selectedSegmentIndex]
        let numTableViewSelections = self.numTableViewSelections()
        
        if group.select == "single" && numTableViewSelections == 1 {
            return nil // must have at least one
        }
        if group.select == "min_one" && numTableViewSelections == 1 {
            return nil // must have at least one
        }
        
        return indexPath
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        guard uiconfig != nil, selectedIDs != nil else {
            return
        }
        
        let display_items = RWFramework.sharedInstance.getValidDisplayItems(uiconfig!.speak, index: segmentedControl.selectedSegmentIndex, tags: selectedIDs!)

        if let cell = tableView.cellForRow(at: indexPath) {
            cell.accessoryType = .none
            
            // Remove the newly deselected tag from the set
            selectedIDs!.remove(display_items[indexPath.row].id)
            RWFramework.sharedInstance.setSpeakIDsSet(selectedIDs!)
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard uiconfig != nil, selectedIDs != nil else {
            return
        }
        
        self.nextButton?.isEnabled = true
        
        let group = uiconfig!.speak[segmentedControl.selectedSegmentIndex]
        let display_items = RWFramework.sharedInstance.getValidDisplayItems(uiconfig!.speak, index: segmentedControl.selectedSegmentIndex, tags: selectedIDs!)
        let numTableViewSelections = self.numTableViewSelections()
        
        if group.select == "single" && numTableViewSelections > 0, let indexPathsForSelectedRows = tableView.indexPathsForSelectedRows {
            for ip in indexPathsForSelectedRows {
                if self.tableView(tableView, willDeselectRowAt: ip) != nil {
                    tableView.deselectRow(at: ip, animated: false)
                    self.tableView(tableView, didDeselectRowAt: ip)
                }
            }
        }
        
        // Because the speak side is a serial approach and each segment depends on the previous, if any changes are made
        // in a segment, all segments beyond it have their choices cleared. This would occur when the user goes back a step
        // and makes a change to their selection. For example, changing step 1 after selected step 2 would clear the items in
        // step 2, causing the requirement for reselection of step 2. The listen side does not have this stipulation and therefore
        // does not perform this extra step at this point.
        for (index, group) in uiconfig!.speak.enumerated() {
            if index > segmentedControl.selectedSegmentIndex {
                for display_item in group.display_items {
                    selectedIDs!.remove(display_item.id)
                }
            }
        }
        RWFramework.sharedInstance.setSpeakIDsSet(selectedIDs!)

        if let cell = tableView.cellForRow(at: indexPath) {
            cell.accessoryType = .checkmark
            
            // Add the newly selected tag to the set
            selectedIDs!.insert(display_items[indexPath.row].id)
            RWFramework.sharedInstance.setSpeakIDsSet(selectedIDs!)
        }
    }
    
    // MARK: - 
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    
    override func canPerformUnwindSegueAction(_ action: Selector, from fromViewController: UIViewController, withSender sender: Any) -> Bool {
        return true
    }
    
    @IBAction func unwindToSpeakTagsViewController(sender: UIStoryboardSegue) {
        // let sourceViewController = sender.source
        // Pull any data from the view controller which initiated the unwind segue.
    }

}
