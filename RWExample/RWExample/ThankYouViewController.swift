//
//  ThankYouViewController.swift
//  RWExample
//
//  Created by Joe Zobkiw on 12/26/17.
//  Copyright © 2017 Roundware. All rights reserved.
//

import UIKit
import Foundation
import RWFramework
import MapKit

class ThankYouViewController: UIViewController, MKMapViewDelegate {
    
    @IBOutlet var map: MKMapView!

    // MARK: -
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.map.delegate = self
        zoomMap() // We force the map to zoom here since we use it in a previous view and the location is cached so the delegate method may not get called if the user hasn't moved.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationItem.setHidesBackButton(true, animated: true)
        self.navigationItem.setRightBarButton(UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done)), animated: true)
        RWFramework.sharedInstance.addDelegate(self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationItem.setHidesBackButton(false, animated: true)
        self.navigationItem.setRightBarButton(nil, animated: true)
        RWFramework.sharedInstance.removeDelegate(self)
    }
    
    // MARK: -

    @IBAction func done(_ sender: UIButton) {
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        zoomMap()
    }
    
    func zoomMap() {
        let span = MKCoordinateSpanMake(0.01, 0.01)
        let region = MKCoordinateRegionMake(map.userLocation.coordinate, span)
        map.setRegion(region, animated: true)
    }

    // MARK: -
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }

    override func canPerformUnwindSegueAction(_ action: Selector, from fromViewController: UIViewController, withSender sender: Any) -> Bool {
        return true
    }
    
    @IBAction func unwindToThankYouViewController(sender: UIStoryboardSegue) {
        // let sourceViewController = sender.source
        // Pull any data from the view controller which initiated the unwind segue.
    }
    
}

