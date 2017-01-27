//
//  RWFrameworkProtocol.swift
//  RWFramework
//
//  Created by Joe Zobkiw on 1/27/15.
//  Copyright (c) 2015 Roundware. All rights reserved.
//

import Foundation
import CoreLocation

// TODO: Consider making this multiple protocols instead of using @objc in order to get optional capabilities
// see http://ashfurrow.com/blog/protocols-and-swift/

// NOTE: These methods are called on the main queue unless otherwise noted

// MARK: RWFrameworkProtocol
@objc public protocol RWFrameworkProtocol: class {

    // API success/failure delegate methods

    /// Sent when a token and username are returned from the server
    @objc optional func rwPostUsersSuccess(data: NSData?)
    /// Sent when a token and username fails to be returned from the server
    @objc optional func rwPostUsersFailure(error: NSError?)

    /// Sent when a new user session for the project has been created
    @objc optional func rwPostSessionsSuccess(data: NSData?)
    /// Sent when the server fails to create a new user session for the project
    @objc optional func rwPostSessionsFailure(error: NSError?)

    /// Sent when project information has been received from the server
    @objc optional func rwGetProjectsIdSuccess(data: NSData?)
    /// Sent when the server fails to send project information
    @objc optional func rwGetProjectsIdFailure(error: NSError?)

    /// Sent when project tags have been received from the server
    @objc optional func rwGetProjectsIdTagsSuccess(data: NSData?)
    /// Sent when the server fails to send project tags
    @objc optional func rwGetProjectsIdTagsFailure(error: NSError?)
    /// Sent when project uigroups have been received from the server
    @objc optional func rwGetProjectsIdUIGroupsSuccess(data: NSData?)
    /// Sent when project uigroups have been received from the server
    @objc optional func rwGetProjectsIdUIGroupsFailure(error: NSError?)
    
    /// Sent when a stream has been acquired and can be played. Clients should enable their Play buttons.
    @objc optional func rwPostStreamsSuccess(data: NSData?)
    /// Sent when a stream could not be acquired and therefore can not be played. Clients should disable their Play buttons.
    @objc optional func rwPostStreamsFailure(error: NSError?)

    /// Sent after a stream is modified successfully
    @objc optional func rwPatchStreamsIdSuccess(data: NSData?)
    /// Sent when a stream could not be modified successfully
    @objc optional func rwPatchStreamsIdFailure(error: NSError?)

    /// Sent to the server if the GPS has not been updated in gps_idle_interval_in_seconds
    @objc optional func rwPostStreamsIdHeartbeatSuccess(data: NSData?)
    /// Sent in the case that sending the heartbeat failed
    @objc optional func rwPostStreamsIdHeartbeatFailure(error: NSError?)

    /// Sent after the server successfully advances to the next sound in the stream
    @objc optional func rwPostStreamsIdNextSuccess(data: NSData?)
    /// Sent in the case that advancing to the next sound in the stream fails
    @objc optional func rwPostStreamsIdNextFailure(error: NSError?)

    /// Sent after the server successfully gets the current asset ID in the stream
    @objc optional func rwGetStreamsIdCurrentSuccess(data: NSData?)
    /// Sent in the case that getting the current assed ID in the stream fails
    @objc optional func rwGetStreamsIdCurrentFailure(error: NSError?)

    /// Sent after the server successfully returns a new envelope id
    @objc optional func rwPostEnvelopesSuccess(data: NSData?)
    /// Sent in the case that the server can not return a new envelope id
    @objc optional func rwPostEnvelopesFailure(error: NSError?)

    /// Sent after the server successfully accepts an envelope item (media upload)
    @objc optional func rwPatchEnvelopesIdSuccess(data: NSData?)
    /// Sent in the case that the server can not accept an envelope item (media upload)
    @objc optional func rwPatchEnvelopesIdFailure(error: NSError?)

    /// Sent after the server successfully gets asset info
    @objc optional func rwGetAssetsSuccess(data: NSData?)
    /// Sent in the case that the server can not get asset info
    @objc optional func rwGetAssetsFailure(error: NSError?)

    /// Sent after the server successfully gets asset id info
    @objc optional func rwGetAssetsIdSuccess(data: NSData?)
    /// Sent in the case that the server can not get asset id info
    @objc optional func rwGetAssetsIdFailure(error: NSError?)

    /// Sent after the server successfully posts a vote
    @objc optional func rwPostAssetsIdVotesSuccess(data: NSData?)
    /// Sent in the case that the server can not post a vote
    @objc optional func rwPostAssetsIdVotesFailure(error: NSError?)

    /// Sent after the server successfully gets vote info for an asset
    @objc optional func rwGetAssetsIdVotesSuccess(data: NSData?)
    /// Sent in the case that the server can not get vote info for an asset
    @objc optional func rwGetAssetsIdVotesFailure(error: NSError?)

    /// Sent after the server successfully posts an event
    @objc optional func rwPostEventsSuccess(data: NSData?)
    /// Sent in the case that the server can not post an event
    @objc optional func rwPostEventsFailure(error: NSError?)

// MARK: metadata

    /// Sent when metadata (and all other observed values) are found, sent synchronously on main thread
    @objc optional func rwObserveValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject : AnyObject], context: UnsafeMutableRawPointer)

// MARK: Image Picker

    /// Sent when the imagePickerController is dismissed after picking media
    @objc optional func rwImagePickerControllerDidFinishPickingMedia(info: [String : AnyObject], path: String)
    /// Sent when the imagePickerController is dismissed after cancelling
    @objc optional func rwImagePickerControllerDidCancel()

// MARK: Record

    /// Sent when the framework determines that recording is possible (via config)
    @objc optional func rwReadyToRecord()

    /// Sent to indicate the % complete when recording
    @objc optional func rwRecordingProgress(percentage: Double, maxDuration: TimeInterval, peakPower: Float, averagePower: Float)
    /// Sent to indicate the % complete when playing back a recording
    @objc optional func rwPlayingBackProgress(percentage: Double, duration: TimeInterval, peakPower: Float, averagePower: Float)

    /// Sent when the audio recorder finishes recording
    @objc optional func rwAudioRecorderDidFinishRecording()
    /// Sent when the audio player finishes playing
    @objc optional func rwAudioPlayerDidFinishPlaying()

// MARK: UI/Status

    /// A user-readable message that can be passed on as status information. This will always be called on the main thread
    @objc optional func rwUpdateStatus(message: String)

    /// The number of items in the queue waiting to be uploaded
    @objc optional func rwUpdateApplicationIconBadgeNumber(count: Int)

    /// Called when the framework needs the current view controller in order to display the tag editor.
	/// If this method is not implemented then it is assumed that the delegate is a view controller.
    @objc optional func rwGetCurrentViewController() -> UIViewController

// MARK: Location

    /// Called when location updates
    @objc optional func rwLocationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!)

    /// Called when location authorization changes
    @objc optional func rwLocationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus)

}

/// The framework calls these methods to call thru to the delegate protocol in order to keep the calling code clean of respondsToSelector checks
extension RWFramework {

// MARK: public delegate management

    /// Add a delegate to the list of delegates
    public func addDelegate(object: AnyObject) {
        delegates.add(object)
        println(object: "addDelegate: \(delegates)")
    }

    /// Remove a delegate from the list of delegates (if it is a delegate)
    public func removeDelegate(object: AnyObject) {
        delegates.remove(object)
        println(object: "removeDelegate: \(delegates)")
    }

    /// Remove all delegates from the list of delegates
    public func removeAllDelegates() {
        delegates.removeAllObjects()
        println(object: "removeAllDelegates: \(delegates)")
    }

    /// Return true if the object is currently a delegate, false otherwise
    public func isDelegate(object: AnyObject) -> Bool {
        return delegates.contains(object)
    }

// MARK: dam

    /// dam = dispatch_async on the main queue
    func dam(f: @escaping () -> Void) {
        DispatchQueue.main.async(execute: { () -> Void in
            f()
        })
    }

// MARK: protocaller

    /// Utility function to call method with AnyObject param on valid delegates
    func protocaller(param: AnyObject? = nil, completion:(_ rwfp: RWFrameworkProtocol, _ param: AnyObject?) -> Void) {
        let enumerator = delegates.objectEnumerator()
        while let d: AnyObject = enumerator.nextObject() as AnyObject? {
            if let dd = d as? RWFrameworkProtocol {
                completion(dd, param)
            }
        }
    }

// MARK: callers

    func rwPostUsersSuccess(data: NSData?) {
        protocaller { (rwfp, _) -> Void in
            self.dam { rwfp.rwPostUsersSuccess?(data: data) }
        }
    }

    func rwPostUsersFailure(error: NSError?) {
        protocaller { (rwfp, _) -> Void in
            if (rwfp.rwPostUsersFailure != nil) {
                self.dam { rwfp.rwPostUsersFailure?(error: error) }
            } else {
                self.alertOK(title: self.LS(key: "RWFramework - rwPostUsersFailure"), message: error!.localizedDescription)
            }
        }
    }

    func rwPostSessionsSuccess(data: NSData?) {
        protocaller { (rwfp, _) -> Void in
            self.dam { rwfp.rwPostSessionsSuccess?(data: data) }
        }
    }

    func rwPostSessionsFailure(error: NSError?) {
        protocaller { (rwfp, _) -> Void in
            if (rwfp.rwPostSessionsFailure != nil) {
                self.dam { rwfp.rwPostSessionsFailure?(error: error) }
            } else {
                self.alertOK(title: self.LS(key: "RWFramework - rwPostSessionsFailure"), message: error!.localizedDescription)
            }
        }
    }

    func rwGetProjectsIdSuccess(data: NSData?) {
        protocaller { (rwfp, _) -> Void in
            self.dam { rwfp.rwGetProjectsIdSuccess?(data: data) }
        }
    }

    func rwGetProjectsIdFailure(error: NSError?) {
        protocaller { (rwfp, _) -> Void in
            if (rwfp.rwGetProjectsIdFailure != nil) {
                self.dam { rwfp.rwGetProjectsIdFailure?(error: error) }
            } else {
                self.alertOK(title: self.LS(key: "RWFramework - rwGetProjectsIdFailure"), message: error!.localizedDescription)
            }
        }
    }

    func rwGetProjectsIdTagsSuccess(data: NSData?) {
        protocaller { (rwfp, _) -> Void in
            self.dam { rwfp.rwGetProjectsIdTagsSuccess?(data: data) }
        }
    }

    func rwGetProjectsIdTagsFailure(error: NSError?) {
        protocaller { (rwfp, _) -> Void in
            if (rwfp.rwGetProjectsIdTagsFailure != nil) {
                self.dam { rwfp.rwGetProjectsIdTagsFailure?(error: error) }
            } else {
                self.alertOK(title: self.LS(key: "RWFramework - rwGetProjectsIdTagsFailure"), message: error!.localizedDescription)
            }
        }
    }
    
    func rwGetProjectsIdUIGroupsSuccess(data: NSData?) {
        protocaller { (rwfp, _) -> Void in
            self.dam { rwfp.rwGetProjectsIdUIGroupsSuccess?(data: data) }
        }
    }
    
    func rwGetProjectsIdUIGroupsFailure(error: NSError?) {
        protocaller { (rwfp, _) -> Void in
            if (rwfp.rwGetProjectsIdTagsFailure != nil) {
                self.dam { rwfp.rwGetProjectsIdUIGroupsFailure?(error: error) }
            } else {
                self.alertOK(title: self.LS(key: "RWFramework - rwGetProjectsIdUIGroupsFailure"), message: error!.localizedDescription)
            }
        }
    }

    func rwPostStreamsSuccess(data: NSData?) {
        protocaller { (rwfp, _) -> Void in
            self.dam { rwfp.rwPostStreamsSuccess?(data: data) }
        }
    }

    func rwPostStreamsFailure(error: NSError?) {
        protocaller { (rwfp, _) -> Void in
            if (rwfp.rwPostStreamsFailure != nil) {
                self.dam { rwfp.rwPostStreamsFailure?(error: error) }
            } else {
                self.alertOK(title: self.LS(key: "RWFramework - rwPostStreamsFailure"), message: error!.localizedDescription)
            }
        }
    }

    func rwPatchStreamsIdSuccess(data: NSData?) {
        protocaller { (rwfp, _) -> Void in
            self.dam { rwfp.rwPatchStreamsIdSuccess?(data: data) }
        }
    }

    func rwPatchStreamsIdFailure(error: NSError?) {
        protocaller { (rwfp, _) -> Void in
            if (rwfp.rwPatchStreamsIdFailure != nil) {
                self.dam { rwfp.rwPatchStreamsIdFailure?(error: error) }
            } else {
                self.alertOK(title: self.LS(key: "RWFramework - rwPatchStreamsIdFailure"), message: error!.localizedDescription)
            }
        }
    }

    func rwPostStreamsIdHeartbeatSuccess(data: NSData?) {
        protocaller { (rwfp, _) -> Void in
            self.dam { rwfp.rwPostStreamsIdHeartbeatSuccess?(data: data) }
        }
    }

    func rwPostStreamsIdHeartbeatFailure(error: NSError?) {
        protocaller { (rwfp, _) -> Void in
            if (rwfp.rwPostStreamsIdHeartbeatFailure != nil) {
                self.dam { rwfp.rwPostStreamsIdHeartbeatFailure?(error: error) }
            } else {
                self.alertOK(title: self.LS(key: "RWFramework - rwPostStreamsIdHeartbeatFailure"), message: error!.localizedDescription)
            }
        }
    }

    func rwPostStreamsIdNextSuccess(data: NSData?) {
        protocaller { (rwfp, _) -> Void in
            self.dam { rwfp.rwPostStreamsIdNextSuccess?(data: data) }
        }
    }

    func rwPostStreamsIdNextFailure(error: NSError?) {
        protocaller { (rwfp, _) -> Void in
            if (rwfp.rwPostStreamsIdNextFailure != nil) {
                self.dam { rwfp.rwPostStreamsIdNextFailure?(error: error) }
            } else {
                self.alertOK(title: self.LS(key: "RWFramework - rwPostStreamsIdNextFailure"), message: error!.localizedDescription)
            }
        }
    }

    func rwGetStreamsIdCurrentSuccess(data: NSData?) {
        protocaller { (rwfp, _) -> Void in
            self.dam { rwfp.rwGetStreamsIdCurrentSuccess?(data: data) }
        }
    }

    func rwGetStreamsIdCurrentFailure(error: NSError?) {
        protocaller { (rwfp, _) -> Void in
            if (rwfp.rwGetStreamsIdCurrentFailure != nil) {
                self.dam { rwfp.rwGetStreamsIdCurrentFailure?(error: error) }
            } else {
                self.alertOK(title: self.LS(key: "RWFramework - rwGetStreamsIdCurrentFailure"), message: error!.localizedDescription)
            }
        }
    }

    func rwPostEnvelopesSuccess(data: NSData?) {
        protocaller { (rwfp, _) -> Void in
            self.dam { rwfp.rwPostEnvelopesSuccess?(data: data) }
        }
    }

    func rwPostEnvelopesFailure(error: NSError?) {
        protocaller { (rwfp, _) -> Void in
            if (rwfp.rwPostEnvelopesFailure != nil) {
                self.dam { rwfp.rwPostEnvelopesFailure?(error: error) }
            } else {
                self.alertOK(title: self.LS(key: "RWFramework - rwPostEnvelopesFailure"), message: error!.localizedDescription)
            }
        }
    }

    func rwPatchEnvelopesIdSuccess(data: NSData?) {
        protocaller { (rwfp, _) -> Void in
            self.dam { rwfp.rwPatchEnvelopesIdSuccess?(data: data) }
        }
    }

    func rwPatchEnvelopesIdFailure(error: NSError?) {
        protocaller { (rwfp, _) -> Void in
            if (rwfp.rwPatchEnvelopesIdFailure != nil) {
                self.dam { rwfp.rwPatchEnvelopesIdFailure?(error: error) }
            } else {
                self.alertOK(title: self.LS(key: "RWFramework - rwPatchEnvelopesIdFailure"), message: error!.localizedDescription)
            }
        }
    }

    func rwGetAssetsSuccess(data: NSData?) {
        protocaller { (rwfp, _) -> Void in
            self.dam { rwfp.rwGetAssetsSuccess?(data: data) }
        }
    }

    func rwGetAssetsFailure(error: NSError?) {
        protocaller { (rwfp, _) -> Void in
            if (rwfp.rwGetAssetsFailure != nil) {
                self.dam { rwfp.rwGetAssetsFailure?(error: error) }
            } else {
                self.alertOK(title: self.LS(key: "RWFramework - rwGetAssetsFailure"), message: error!.localizedDescription)
            }
        }
    }

    func rwGetAssetsIdSuccess(data: NSData?) {
        protocaller { (rwfp, _) -> Void in
            self.dam { rwfp.rwGetAssetsIdSuccess?(data: data) }
        }
    }

    func rwGetAssetsIdFailure(error: NSError?) {
        protocaller { (rwfp, _) -> Void in
            if (rwfp.rwGetAssetsIdFailure != nil) {
                self.dam { rwfp.rwGetAssetsIdFailure?(error: error) }
            } else {
                self.alertOK(title: self.LS(key: "RWFramework - rwGetAssetsIdFailure"), message: error!.localizedDescription)
            }
        }
    }

    func rwPostAssetsIdVotesSuccess(data: NSData?) {
        protocaller { (rwfp, _) -> Void in
            self.dam { rwfp.rwPostAssetsIdVotesSuccess?(data: data) }
        }
    }

    func rwPostAssetsIdVotesFailure(error: NSError?) {
        protocaller { (rwfp, _) -> Void in
            if (rwfp.rwPostAssetsIdVotesFailure != nil) {
                self.dam { rwfp.rwPostAssetsIdVotesFailure?(error: error) }
            } else {
                self.alertOK(title: self.LS(key: "RWFramework - rwPostAssetsIdVotesFailure"), message: error!.localizedDescription)
            }
        }
    }

    func rwGetAssetsIdVotesSuccess(data: NSData?) {
        protocaller { (rwfp, _) -> Void in
            self.dam { rwfp.rwGetAssetsIdVotesSuccess?(data: data) }
        }
    }

    func rwGetAssetsIdVotesFailure(error: NSError?) {
        protocaller { (rwfp, _) -> Void in
            if (rwfp.rwGetAssetsIdVotesFailure != nil) {
                self.dam { rwfp.rwGetAssetsIdVotesFailure?(error: error) }
            } else {
                self.alertOK(title: self.LS(key: "RWFramework - rwGetAssetsIdVotesFailure"), message: error!.localizedDescription)
            }
        }
    }

    func rwPostEventsSuccess(data: NSData?) {
        protocaller { (rwfp, _) -> Void in
            self.dam { rwfp.rwPostEventsSuccess?(data: data) }
        }
    }

    func rwPostEventsFailure(error: NSError?) {
        protocaller { (rwfp, _) -> Void in
            if (rwfp.rwPostEventsFailure != nil) {
                self.dam { rwfp.rwPostEventsFailure?(error: error) }
            } else {
                self.alertOK(title: self.LS(key: "RWFramework - rwPostEventsFailure"), message: error!.localizedDescription)
            }
        }
    }


// MARK: metadata

    func rwObserveValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject : AnyObject], context: UnsafeMutableRawPointer) {
        protocaller { (rwfp, _) -> Void in
            self.dam { rwfp.rwObserveValueForKeyPath?(keyPath: keyPath, ofObject: object, change: change, context: context) }
        }
    }

// MARK: Image Picker

    func rwImagePickerControllerDidFinishPickingMedia(info: [String : AnyObject], path: String) {
        protocaller { (rwfp, _) -> Void in
            self.dam { rwfp.rwImagePickerControllerDidFinishPickingMedia?(info: info, path: path) }
        }
    }

    func rwImagePickerControllerDidCancel() {
        protocaller { (rwfp, _) -> Void in
            self.dam { rwfp.rwImagePickerControllerDidCancel?() }
        }
    }

// MARK: Record

    func rwReadyToRecord() {
        protocaller { (rwfp, _) -> Void in
            self.dam { rwfp.rwReadyToRecord?() }
        }
    }

    func rwRecordingProgress(percentage: Double, maxDuration: TimeInterval, peakPower: Float, averagePower: Float) {
        protocaller { (rwfp, _) -> Void in
            self.dam { rwfp.rwRecordingProgress?(percentage: percentage, maxDuration: maxDuration, peakPower: peakPower, averagePower: averagePower) }
        }
    }

    func rwPlayingBackProgress(percentage: Double, duration: TimeInterval, peakPower: Float, averagePower: Float) {
        protocaller { (rwfp, _) -> Void in
            self.dam { rwfp.rwPlayingBackProgress?(percentage: percentage, duration: duration, peakPower: peakPower, averagePower: averagePower) }
        }
    }

    func rwAudioRecorderDidFinishRecording() {
        protocaller { (rwfp, _) -> Void in
            self.dam { rwfp.rwAudioRecorderDidFinishRecording?() }
        }
    }

    func rwAudioPlayerDidFinishPlaying() {
        protocaller { (rwfp, _) -> Void in
            self.dam { rwfp.rwAudioPlayerDidFinishPlaying?() }
        }
    }

// MARK: UI/Status

    func rwUpdateStatus(message: String) {
        var showedAlert = false
        protocaller { (rwfp, _) -> Void in
            if (rwfp.rwUpdateStatus != nil) {
                self.dam { rwfp.rwUpdateStatus?(message: message) }
            } else if (showedAlert == false) {
                showedAlert = true // Only show the alert once per call
                self.dam {
                    let alert = UIAlertController(title: self.LS(key: "RWFramework"), message: message, preferredStyle: UIAlertControllerStyle.alert)
                    let OKAction = UIAlertAction(title: self.LS(key: "OK"), style: .default) { (action) in }
                    alert.addAction(OKAction)
                    if let currentViewController = rwfp.rwGetCurrentViewController?() {
                        currentViewController.present(alert, animated: true, completion: { () -> Void in
                        })
                    } else {
                        let assumedViewController = rwfp as! UIViewController
                        assumedViewController.present(alert, animated: true, completion: { () -> Void in
                        })
                    }
                }
            }
        }
    }

    func rwUpdateApplicationIconBadgeNumber(count: Int) {
        protocaller { (rwfp, _) -> Void in
            self.dam { rwfp.rwUpdateApplicationIconBadgeNumber?(count: count) }
        }
    }

// MARK: Location

    func rwLocationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        protocaller { (rwfp, _) -> Void in
            self.dam { rwfp.rwLocationManager?(manager: manager, didUpdateLocations: locations) }
        }
    }

    func rwLocationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        protocaller { (rwfp, _) -> Void in
            self.dam { rwfp.rwLocationManager?(manager: manager, didChangeAuthorizationStatus: status) }
        }
    }

}
