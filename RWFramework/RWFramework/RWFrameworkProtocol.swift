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
    optional func rwPostUsersSuccess(data: NSData?)
    /// Sent when a token and username fails to be returned from the server
    optional func rwPostUsersFailure(error: NSError?)

    /// Sent when a new user session for the project has been created
    optional func rwPostSessionsSuccess(data: NSData?)
    /// Sent when the server fails to create a new user session for the project
    optional func rwPostSessionsFailure(error: NSError?)

    /// Sent when project information has been received from the server
    optional func rwGetProjectsIdSuccess(data: NSData?)
    /// Sent when the server fails to send project information
    optional func rwGetProjectsIdFailure(error: NSError?)

    /// Sent when project tags have been received from the server
    optional func rwGetProjectsIdTagsSuccess(data: NSData?)
    /// Sent when the server fails to send project tags
    optional func rwGetProjectsIdTagsFailure(error: NSError?)

    /// Sent when a stream has been acquired and can be played. Clients should enable their Play buttons.
    optional func rwPostStreamsSuccess(data: NSData?)
    /// Sent when a stream could not be acquired and therefore can not be played. Clients should disable their Play buttons.
    optional func rwPostStreamsFailure(error: NSError?)

    /// Sent after a stream is modified successfully
    optional func rwPatchStreamsIdSuccess(data: NSData?)
    /// Sent when a stream could not be modified successfully
    optional func rwPatchStreamsIdFailure(error: NSError?)

    /// Sent to the server if the GPS has not been updated in gps_idle_interval_in_seconds
    optional func rwPostStreamsIdHeartbeatSuccess(data: NSData?)
    /// Sent in the case that sending the heartbeat failed
    optional func rwPostStreamsIdHeartbeatFailure(error: NSError?)

    /// Sent after the server successfully advances to the next sound in the stream
    optional func rwPostStreamsIdNextSuccess(data: NSData?)
    /// Sent in the case that advancing to the next sound in the stream fails
    optional func rwPostStreamsIdNextFailure(error: NSError?)

    /// Sent after the server successfully gets the current asset ID in the stream
    optional func rwGetStreamsIdCurrentSuccess(data: NSData?)
    /// Sent in the case that getting the current assed ID in the stream fails
    optional func rwGetStreamsIdCurrentFailure(error: NSError?)

    /// Sent after the server successfully returns a new envelope id
    optional func rwPostEnvelopesSuccess(data: NSData?)
    /// Sent in the case that the server can not return a new envelope id
    optional func rwPostEnvelopesFailure(error: NSError?)

    /// Sent after the server successfully accepts an envelope item (media upload)
    optional func rwPatchEnvelopesIdSuccess(data: NSData?)
    /// Sent in the case that the server can not accept an envelope item (media upload)
    optional func rwPatchEnvelopesIdFailure(error: NSError?)

    /// Sent after the server successfully gets asset info
    optional func rwGetAssetsSuccess(data: NSData?)
    /// Sent in the case that the server can not get asset info
    optional func rwGetAssetsFailure(error: NSError?)

    /// Sent after the server successfully gets asset id info
    optional func rwGetAssetsIdSuccess(data: NSData?)
    /// Sent in the case that the server can not get asset id info
    optional func rwGetAssetsIdFailure(error: NSError?)

    /// Sent after the server successfully posts a vote
    optional func rwPostAssetsIdVotesSuccess(data: NSData?)
    /// Sent in the case that the server can not post a vote
    optional func rwPostAssetsIdVotesFailure(error: NSError?)

    /// Sent after the server successfully gets vote info for an asset
    optional func rwGetAssetsIdVotesSuccess(data: NSData?)
    /// Sent in the case that the server can not get vote info for an asset
    optional func rwGetAssetsIdVotesFailure(error: NSError?)

    /// Sent after the server successfully posts an event
    optional func rwPostEventsSuccess(data: NSData?)
    /// Sent in the case that the server can not post an event
    optional func rwPostEventsFailure(error: NSError?)

// MARK: metadata

    /// Sent when metadata (and all other observed values) are found, sent synchronously on main thread
    optional func rwObserveValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject : AnyObject], context: UnsafeMutablePointer<Void>)

// MARK: Image Picker

    /// Sent when the imagePickerController is dismissed after picking media
    optional func rwImagePickerControllerDidFinishPickingMedia(info: [NSObject : AnyObject], path: String)
    /// Sent when the imagePickerController is dismissed after cancelling
    optional func rwImagePickerControllerDidCancel()

// MARK: Record

    /// Sent when the framework determines that recording is possible (via config)
    optional func rwReadyToRecord()

    /// Sent to indicate the % complete when recording
    optional func rwRecordingProgress(percentage: Double, maxDuration: NSTimeInterval, peakPower: Float, averagePower: Float)
    /// Sent to indicate the % complete when playing back a recording
    optional func rwPlayingBackProgress(percentage: Double, duration: NSTimeInterval, peakPower: Float, averagePower: Float)

    /// Sent when the audio recorder finishes recording
    optional func rwAudioRecorderDidFinishRecording()
    /// Sent when the audio player finishes playing
    optional func rwAudioPlayerDidFinishPlaying()

// MARK: UI/Status

    /// A user-readable message that can be passed on as status information. This will always be called on the main thread
    optional func rwUpdateStatus(message: String)

    /// The number of items in the queue waiting to be uploaded
    optional func rwUpdateApplicationIconBadgeNumber(count: Int)

    /// Called when the framework needs the current view controller in order to display the tag editor.
	/// If this method is not implemented then it is assumed that the delegate is a view controller.
    optional func rwGetCurrentViewController() -> UIViewController

// MARK: Location

    /// Called when location updates
    optional func rwLocationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!)

    /// Called when location authorization changes
    optional func rwLocationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus)

}

/// The framework calls these methods to call thru to the delegate protocol in order to keep the calling code clean of respondsToSelector checks
extension RWFramework {

// MARK: public delegate management

    /// Add a delegate to the list of delegates
    public func addDelegate(object: AnyObject) {
        delegates.addObject(object)
        println("addDelegate: \(delegates)")
    }

    /// Remove a delegate from the list of delegates (if it is a delegate)
    public func removeDelegate(object: AnyObject) {
        delegates.removeObject(object)
        println("removeDelegate: \(delegates)")
    }

    /// Remove all delegates from the list of delegates
    public func removeAllDelegates() {
        delegates.removeAllObjects()
        println("removeAllDelegates: \(delegates)")
    }

    /// Return true if the object is currently a delegate, false otherwise
    public func isDelegate(object: AnyObject) -> Bool {
        return delegates.containsObject(object)
    }

// MARK: dam

    /// dam = dispatch_async on the main queue
    func dam(f: () -> Void) {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            f()
        })
    }

// MARK: protocaller

    /// Utility function to call method with AnyObject param on valid delegates
    func protocaller(param: AnyObject? = nil, completion:(rwfp: RWFrameworkProtocol, param: AnyObject?) -> Void) {
        let enumerator = delegates.objectEnumerator()
        while let d: AnyObject = enumerator.nextObject() {
            if let dd = d as? RWFrameworkProtocol {
                completion(rwfp: dd, param: param)
            }
        }
    }

// MARK: callers

    func rwPostUsersSuccess(data: NSData?) {
        protocaller { (rwfp, _) -> Void in
            self.dam { rwfp.rwPostUsersSuccess?(data) }
        }
    }

    func rwPostUsersFailure(error: NSError?) {
        protocaller { (rwfp, _) -> Void in
            if (rwfp.rwPostUsersFailure != nil) {
                self.dam { rwfp.rwPostUsersFailure?(error) }
            } else {
                self.alertOK(self.LS("RWFramework - rwPostUsersFailure"), message: error!.localizedDescription)
            }
        }
    }

    func rwPostSessionsSuccess(data: NSData?) {
        protocaller { (rwfp, _) -> Void in
            self.dam { rwfp.rwPostSessionsSuccess?(data) }
        }
    }

    func rwPostSessionsFailure(error: NSError?) {
        protocaller { (rwfp, _) -> Void in
            if (rwfp.rwPostSessionsFailure != nil) {
                self.dam { rwfp.rwPostSessionsFailure?(error) }
            } else {
                self.alertOK(self.LS("RWFramework - rwPostSessionsFailure"), message: error!.localizedDescription)
            }
        }
    }

    func rwGetProjectsIdSuccess(data: NSData?) {
        protocaller { (rwfp, _) -> Void in
            self.dam { rwfp.rwGetProjectsIdSuccess?(data) }
        }
    }

    func rwGetProjectsIdFailure(error: NSError?) {
        protocaller { (rwfp, _) -> Void in
            if (rwfp.rwGetProjectsIdFailure != nil) {
                self.dam { rwfp.rwGetProjectsIdFailure?(error) }
            } else {
                self.alertOK(self.LS("RWFramework - rwGetProjectsIdFailure"), message: error!.localizedDescription)
            }
        }
    }

    func rwGetProjectsIdTagsSuccess(data: NSData?) {
        protocaller { (rwfp, _) -> Void in
            self.dam { rwfp.rwGetProjectsIdTagsSuccess?(data) }
        }
    }

    func rwGetProjectsIdTagsFailure(error: NSError?) {
        protocaller { (rwfp, _) -> Void in
            if (rwfp.rwGetProjectsIdTagsFailure != nil) {
                self.dam { rwfp.rwGetProjectsIdTagsFailure?(error) }
            } else {
                self.alertOK(self.LS("RWFramework - rwGetProjectsIdTagsFailure"), message: error!.localizedDescription)
            }
        }
    }

    func rwPostStreamsSuccess(data: NSData?) {
        protocaller { (rwfp, _) -> Void in
            self.dam { rwfp.rwPostStreamsSuccess?(data) }
        }
    }

    func rwPostStreamsFailure(error: NSError?) {
        protocaller { (rwfp, _) -> Void in
            if (rwfp.rwPostStreamsFailure != nil) {
                self.dam { rwfp.rwPostStreamsFailure?(error) }
            } else {
                self.alertOK(self.LS("RWFramework - rwPostStreamsFailure"), message: error!.localizedDescription)
            }
        }
    }

    func rwPatchStreamsIdSuccess(data: NSData?) {
        protocaller { (rwfp, _) -> Void in
            self.dam { rwfp.rwPatchStreamsIdSuccess?(data) }
        }
    }

    func rwPatchStreamsIdFailure(error: NSError?) {
        protocaller { (rwfp, _) -> Void in
            if (rwfp.rwPatchStreamsIdFailure != nil) {
                self.dam { rwfp.rwPatchStreamsIdFailure?(error) }
            } else {
                self.alertOK(self.LS("RWFramework - rwPatchStreamsIdFailure"), message: error!.localizedDescription)
            }
        }
    }

    func rwPostStreamsIdHeartbeatSuccess(data: NSData?) {
        protocaller { (rwfp, _) -> Void in
            self.dam { rwfp.rwPostStreamsIdHeartbeatSuccess?(data) }
        }
    }

    func rwPostStreamsIdHeartbeatFailure(error: NSError?) {
        protocaller { (rwfp, _) -> Void in
            if (rwfp.rwPostStreamsIdHeartbeatFailure != nil) {
                self.dam { rwfp.rwPostStreamsIdHeartbeatFailure?(error) }
            } else {
                self.alertOK(self.LS("RWFramework - rwPostStreamsIdHeartbeatFailure"), message: error!.localizedDescription)
            }
        }
    }

    func rwPostStreamsIdNextSuccess(data: NSData?) {
        protocaller { (rwfp, _) -> Void in
            self.dam { rwfp.rwPostStreamsIdNextSuccess?(data) }
        }
    }

    func rwPostStreamsIdNextFailure(error: NSError?) {
        protocaller { (rwfp, _) -> Void in
            if (rwfp.rwPostStreamsIdNextFailure != nil) {
                self.dam { rwfp.rwPostStreamsIdNextFailure?(error) }
            } else {
                self.alertOK(self.LS("RWFramework - rwPostStreamsIdNextFailure"), message: error!.localizedDescription)
            }
        }
    }

    func rwGetStreamsIdCurrentSuccess(data: NSData?) {
        protocaller { (rwfp, _) -> Void in
            self.dam { rwfp.rwGetStreamsIdCurrentSuccess?(data) }
        }
    }

    func rwGetStreamsIdCurrentFailure(error: NSError?) {
        protocaller { (rwfp, _) -> Void in
            if (rwfp.rwGetStreamsIdCurrentFailure != nil) {
                self.dam { rwfp.rwGetStreamsIdCurrentFailure?(error) }
            } else {
                self.alertOK(self.LS("RWFramework - rwGetStreamsIdCurrentFailure"), message: error!.localizedDescription)
            }
        }
    }

    func rwPostEnvelopesSuccess(data: NSData?) {
        protocaller { (rwfp, _) -> Void in
            self.dam { rwfp.rwPostEnvelopesSuccess?(data) }
        }
    }

    func rwPostEnvelopesFailure(error: NSError?) {
        protocaller { (rwfp, _) -> Void in
            if (rwfp.rwPostEnvelopesFailure != nil) {
                self.dam { rwfp.rwPostEnvelopesFailure?(error) }
            } else {
                self.alertOK(self.LS("RWFramework - rwPostEnvelopesFailure"), message: error!.localizedDescription)
            }
        }
    }

    func rwPatchEnvelopesIdSuccess(data: NSData?) {
        protocaller { (rwfp, _) -> Void in
            self.dam { rwfp.rwPatchEnvelopesIdSuccess?(data) }
        }
    }

    func rwPatchEnvelopesIdFailure(error: NSError?) {
        protocaller { (rwfp, _) -> Void in
            if (rwfp.rwPatchEnvelopesIdFailure != nil) {
                self.dam { rwfp.rwPatchEnvelopesIdFailure?(error) }
            } else {
                self.alertOK(self.LS("RWFramework - rwPatchEnvelopesIdFailure"), message: error!.localizedDescription)
            }
        }
    }

    func rwGetAssetsSuccess(data: NSData?) {
        protocaller { (rwfp, _) -> Void in
            self.dam { rwfp.rwGetAssetsSuccess?(data) }
        }
    }

    func rwGetAssetsFailure(error: NSError?) {
        protocaller { (rwfp, _) -> Void in
            if (rwfp.rwGetAssetsFailure != nil) {
                self.dam { rwfp.rwGetAssetsFailure?(error) }
            } else {
                self.alertOK(self.LS("RWFramework - rwGetAssetsFailure"), message: error!.localizedDescription)
            }
        }
    }

    func rwGetAssetsIdSuccess(data: NSData?) {
        protocaller { (rwfp, _) -> Void in
            self.dam { rwfp.rwGetAssetsIdSuccess?(data) }
        }
    }

    func rwGetAssetsIdFailure(error: NSError?) {
        protocaller { (rwfp, _) -> Void in
            if (rwfp.rwGetAssetsIdFailure != nil) {
                self.dam { rwfp.rwGetAssetsIdFailure?(error) }
            } else {
                self.alertOK(self.LS("RWFramework - rwGetAssetsIdFailure"), message: error!.localizedDescription)
            }
        }
    }

    func rwPostAssetsIdVotesSuccess(data: NSData?) {
        protocaller { (rwfp, _) -> Void in
            self.dam { rwfp.rwPostAssetsIdVotesSuccess?(data) }
        }
    }

    func rwPostAssetsIdVotesFailure(error: NSError?) {
        protocaller { (rwfp, _) -> Void in
            if (rwfp.rwPostAssetsIdVotesFailure != nil) {
                self.dam { rwfp.rwPostAssetsIdVotesFailure?(error) }
            } else {
                self.alertOK(self.LS("RWFramework - rwPostAssetsIdVotesFailure"), message: error!.localizedDescription)
            }
        }
    }

    func rwGetAssetsIdVotesSuccess(data: NSData?) {
        protocaller { (rwfp, _) -> Void in
            self.dam { rwfp.rwGetAssetsIdVotesSuccess?(data) }
        }
    }

    func rwGetAssetsIdVotesFailure(error: NSError?) {
        protocaller { (rwfp, _) -> Void in
            if (rwfp.rwGetAssetsIdVotesFailure != nil) {
                self.dam { rwfp.rwGetAssetsIdVotesFailure?(error) }
            } else {
                self.alertOK(self.LS("RWFramework - rwGetAssetsIdVotesFailure"), message: error!.localizedDescription)
            }
        }
    }

    func rwPostEventsSuccess(data: NSData?) {
        protocaller { (rwfp, _) -> Void in
            self.dam { rwfp.rwPostEventsSuccess?(data) }
        }
    }

    func rwPostEventsFailure(error: NSError?) {
        protocaller { (rwfp, _) -> Void in
            if (rwfp.rwPostEventsFailure != nil) {
                self.dam { rwfp.rwPostEventsFailure?(error) }
            } else {
                self.alertOK(self.LS("RWFramework - rwPostEventsFailure"), message: error!.localizedDescription)
            }
        }
    }


// MARK: metadata

    func rwObserveValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject : AnyObject], context: UnsafeMutablePointer<Void>) {
        protocaller { (rwfp, _) -> Void in
            self.dam { rwfp.rwObserveValueForKeyPath?(keyPath, ofObject: object, change: change, context: context) }
        }
    }

// MARK: Image Picker

    func rwImagePickerControllerDidFinishPickingMedia(info: [NSObject : AnyObject], path: String) {
        protocaller { (rwfp, _) -> Void in
            self.dam { rwfp.rwImagePickerControllerDidFinishPickingMedia?(info, path: path) }
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

    func rwRecordingProgress(percentage: Double, maxDuration: NSTimeInterval, peakPower: Float, averagePower: Float) {
        protocaller { (rwfp, _) -> Void in
            self.dam { rwfp.rwRecordingProgress?(percentage, maxDuration: maxDuration, peakPower: peakPower, averagePower: averagePower) }
        }
    }

    func rwPlayingBackProgress(percentage: Double, duration: NSTimeInterval, peakPower: Float, averagePower: Float) {
        protocaller { (rwfp, _) -> Void in
            self.dam { rwfp.rwPlayingBackProgress?(percentage, duration: duration, peakPower: peakPower, averagePower: averagePower) }
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
                self.dam { rwfp.rwUpdateStatus?(message) }
            } else if (showedAlert == false) {
                showedAlert = true // Only show the alert once per call
                self.dam {
                    var alert = UIAlertController(title: self.LS("RWFramework"), message: message, preferredStyle: UIAlertControllerStyle.Alert)
                    let OKAction = UIAlertAction(title: self.LS("OK"), style: .Default) { (action) in }
                    alert.addAction(OKAction)
                    if let currentViewController = rwfp.rwGetCurrentViewController?() {
                        currentViewController.presentViewController(alert, animated: true, completion: { () -> Void in
                        })
                    } else {
                        var assumedViewController = rwfp as! UIViewController
                        assumedViewController.presentViewController(alert, animated: true, completion: { () -> Void in
                        })
                    }
                }
            }
        }
    }

    func rwUpdateApplicationIconBadgeNumber(count: Int) {
        protocaller { (rwfp, _) -> Void in
            self.dam { rwfp.rwUpdateApplicationIconBadgeNumber?(count) }
        }
    }

// MARK: Location

    func rwLocationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        protocaller { (rwfp, _) -> Void in
            self.dam { rwfp.rwLocationManager?(manager, didUpdateLocations: locations) }
        }
    }

    func rwLocationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        protocaller { (rwfp, _) -> Void in
            self.dam { rwfp.rwLocationManager?(manager, didChangeAuthorizationStatus: status) }
        }
    }

}
