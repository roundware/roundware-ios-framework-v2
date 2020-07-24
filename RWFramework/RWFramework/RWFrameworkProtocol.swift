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

    /// Sent when the framework CSM components are initialized and ready
    @objc optional func rwStartedSuccessfully()

    // API success/failure delegate methods

    /// Sent when a token and username are returned from the server
    @objc optional func rwPostUsersSuccess(_ data: Data)
    /// Sent when a token and username fails to be returned from the server
    @objc optional func rwPostUsersFailure(_ error: Error)

    /// Sent when a new user session for the project has been created
    @objc optional func rwPostSessionsSuccess(_ data: Data)
    /// Sent when the server fails to create a new user session for the project
    @objc optional func rwPostSessionsFailure(_ error: Error)

    /// Sent when project information has been received from the server
    @objc optional func rwGetProjectsIdSuccess(_ data: Data)
    /// Sent when the server fails to send project information
    @objc optional func rwGetProjectsIdFailure(_ error: Error)

    /// Sent when ui config has been received from the server
    @objc optional func rwGetUIConfigSuccess(_ data: Data)
    /// Sent when the server fails to send ui config
    @objc optional func rwGetUIConfigFailure(_ error: Error)

    /// Sent when project uigroups have been received from the server
    @objc optional func rwGetProjectsIdUIGroupsSuccess(_ data: Data)
    /// Sent when the server fails to send project uigroups
    @objc optional func rwGetProjectsIdUIGroupsFailure(_ error: Error)

    /// Sent when project tags have been received from the server
    @objc optional func rwGetProjectsIdTagsSuccess(_ data: Data)
    /// Sent when the server fails to send project tags
    @objc optional func rwGetProjectsIdTagsFailure(_ error: Error)
    
    /// Sent when tag categories have been received from the server
    @objc optional func rwGetTagCategoriesSuccess(_ data: Data)
    /// Sent when the server fails to send tag categories
    @objc optional func rwGetTagCategoriesFailure(_ error: Error)
    
    /// Sent when a stream has been acquired and can be played. Clients should enable their Play buttons.
    @objc optional func rwPostStreamsSuccess(_ data: Data)
    /// Sent when a stream could not be acquired and therefore can not be played. Clients should disable their Play buttons.
    @objc optional func rwPostStreamsFailure(_ error: Error)

    /// Sent after a stream is modified successfully
    @objc optional func rwPatchStreamsIdSuccess(_ data: Data)
    /// Sent when a stream could not be modified successfully
    @objc optional func rwPatchStreamsIdFailure(_ error: Error)

    /// Sent to the server if the GPS has not been updated in gps_idle_interval_in_seconds
    @objc optional func rwPostStreamsIdHeartbeatSuccess(_ data: Data)
    /// Sent in the case that sending the heartbeat failed
    @objc optional func rwPostStreamsIdHeartbeatFailure(_ error: Error)

    /// Sent after the server successfully replays a sound in the stream
    @objc optional func rwPostStreamsIdReplaySuccess(_ data: Data)
    /// Sent in the case that replaying a sound in the stream fails
    @objc optional func rwPostStreamsIdReplayFailure(_ error: Error)

    /// Sent after the server successfully advances to the next sound in the stream
    @objc optional func rwPostStreamsIdSkipSuccess(_ data: Data)
    /// Sent in the case that advancing to the next sound in the stream fails
    @objc optional func rwPostStreamsIdSkipFailure(_ error: Error)

    /// Sent after the server successfully gets the current asset ID in the stream
    @objc optional func rwGetStreamsIdCurrentSuccess(_ data: Data)
    /// Sent in the case that getting the current assed ID in the stream fails
    @objc optional func rwGetStreamsIdCurrentFailure(_ error: Error)
    
    /// Sent to the server when user pauses stream playback locally
    @objc optional func rwPostStreamsIdPauseSuccess(_ data: Data)
    /// Sent in the case that sending the pause request failed
    @objc optional func rwPostStreamsIdPauseFailure(_ error: Error)
    
    /// Sent to the server when user un-pauses stream playback locally
    @objc optional func rwPostStreamsIdResumeSuccess(_ data: Data)
    /// Sent in the case that sending the resume request failed
    @objc optional func rwPostStreamsIdResumeFailure(_ error: Error)
    
    /// Sent to the server when user checks if stream is active
    @objc optional func rwGetStreamsIdIsActiveSuccess(_ data: Data)
    /// Sent in the case that the isactive request failed
    @objc optional func rwGetStreamsIdIsActiveFailure(_ error: Error)

    /// Sent after the server successfully returns a new envelope id
    @objc optional func rwPostEnvelopesSuccess(_ data: Data)
    /// Sent in the case that the server can not return a new envelope id
    @objc optional func rwPostEnvelopesFailure(_ error: Error)

    /// Sent after the server successfully accepts an envelope item (media upload)
    @objc optional func rwPatchEnvelopesIdSuccess(_ data: Data)
    /// Sent in the case that the server can not accept an envelope item (media upload)
    @objc optional func rwPatchEnvelopesIdFailure(_ error: Error)

    /// Sent after the server successfully gets asset info
    @objc optional func rwGetAssetsSuccess(_ data: Data)
    /// Sent in the case that the server can not get asset info
    @objc optional func rwGetAssetsFailure(_ error: Error)

    /// Sent after the server successfully gets asset id info
    @objc optional func rwGetAssetsIdSuccess(_ data: Data)
    /// Sent in the case that the server can not get asset id info
    @objc optional func rwGetAssetsIdFailure(_ error: Error)

    /// Sent after the server successfully patches asset
    @objc optional func rwPatchAssetsIdSuccess(_ data: Data?)
    /// Sent in the case that the server cannot patch asset
    @objc optional func rwPatchAssetsIdFailure(_ error: Error)
    
    /// Sent after the server successfully posts a vote
    @objc optional func rwPostAssetsIdVotesSuccess(_ data: Data)
    /// Sent in the case that the server can not post a vote
    @objc optional func rwPostAssetsIdVotesFailure(_ error: Error)

    /// Sent after the server successfully gets vote info for an asset
    @objc optional func rwGetAssetsIdVotesSuccess(_ data: Data)
    /// Sent in the case that the server can not get vote info for an asset
    @objc optional func rwGetAssetsIdVotesFailure(_ error: Error)
    
    /// Sent after the server successfully gets speaker info
    @objc optional func rwGetSpeakersSuccess(_ data: Data)
    /// Sent in the case that the server can not get speaker info
    @objc optional func rwGetSpeakersFailure(_ error: Error)

    /// Sent after the server successfully posts an event
    @objc optional func rwPostEventsSuccess(_ data: Data)
    /// Sent in the case that the server can not post an event
    @objc optional func rwPostEventsFailure(_ error: Error)

// MARK: metadata

    /// Sent when metadata (and all other observed values) are found, sent synchronously on main thread
    @objc optional func rwObserveValueForKeyPath(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?)

// MARK: Image Picker

    /// Sent when the imagePickerController is dismissed after picking media
    @objc optional func rwImagePickerControllerDidFinishPickingMedia(_ info: [AnyHashable: Any], path: String)
    /// Sent when the imagePickerController is dismissed after cancelling
    @objc optional func rwImagePickerControllerDidCancel()

// MARK: Record

    /// Sent when the framework determines that recording is possible (via config)
    @objc optional func rwReadyToRecord()

    /// Sent to indicate the % complete when recording
    @objc optional func rwRecordingProgress(_ percentage: Double, maxDuration: TimeInterval, peakPower: Float, averagePower: Float)
    /// Sent to indicate the % complete when playing back a recording
    @objc optional func rwPlayingBackProgress(_ percentage: Double, duration: TimeInterval, peakPower: Float, averagePower: Float)

    /// Sent when the audio recorder finishes recording
    @objc optional func rwAudioRecorderDidFinishRecording()
    /// Sent when the audio player finishes playing
    @objc optional func rwAudioPlayerDidFinishPlaying()

// MARK: UI/Status

    /// A user-readable message that can be passed on as status information. This will always be called on the main thread
    @objc optional func rwUpdateStatus(_ message: String)

    /// The number of items in the queue waiting to be uploaded
    @objc optional func rwUpdateApplicationIconBadgeNumber(_ count: Int)

    /// Called when the framework needs the current view controller in order to display the tag editor.
	/// If this method is not implemented then it is assumed that the delegate is a view controller.
    @objc optional func rwGetCurrentViewController() -> UIViewController

// MARK: Location

    /// Called when location updates
    @objc optional func rwLocationManager(_ manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!)

    /// Called when location authorization changes
    @objc optional func rwLocationManager(_ manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus)

}

/// The framework calls these methods to call thru to the delegate protocol in order to keep the calling code clean of respondsToSelector checks
extension RWFramework {

// MARK: public delegate management

    /// Add a delegate to the list of delegates
    public func addDelegate(_ object: AnyObject) {
        delegates.remove(object) // To ensure we only have this object in the table once, try to remove it first
        delegates.add(object)
        println("addDelegate: \(delegates)")
    }

    /// Remove a delegate from the list of delegates (if it is a delegate)
    public func removeDelegate(_ object: AnyObject) {
        delegates.remove(object)
        println("removeDelegate: \(delegates)")
    }

    /// Remove all delegates from the list of delegates
    public func removeAllDelegates() {
        delegates.removeAllObjects()
        println("removeAllDelegates: \(delegates)")
    }

    /// Return true if the object is currently a delegate, false otherwise
    public func isDelegate(_ object: AnyObject) -> Bool {
        return delegates.contains(object)
    }

// MARK: dam

    /// dam = dispatch_async on the main queue
    func dam(_ f: @escaping () -> Void) {
        DispatchQueue.main.async(execute: { () -> Void in
            f()
        })
    }

// MARK: protocaller

    /// Utility function to call method with AnyObject param on valid delegates
    func protocaller(_ param: AnyObject? = nil, completion:(_ rwfp: RWFrameworkProtocol, _ param: AnyObject?) -> Void) {
        let enumerator = delegates.objectEnumerator()
        while let d = enumerator.nextObject() {
            if let dd = d as? RWFrameworkProtocol {
                completion(dd, param)
            }
        }
    }

// MARK: callers

    func rwStartedSuccessfully() {
        protocaller { (rwfp, _) -> Void in
            self.dam { rwfp.rwStartedSuccessfully?() }
        }
    }

    func rwPostUsersSuccess(_ data: Data) {
        protocaller { (rwfp, _) -> Void in
            self.dam { rwfp.rwPostUsersSuccess?(data) }
        }
    }

    func rwPostUsersFailure(_ error: Error) {
        protocaller { (rwfp, _) -> Void in
            if (rwfp.rwPostUsersFailure != nil) {
                self.dam { rwfp.rwPostUsersFailure?(error) }
            } else {
                self.alertOK(self.LS("RWFramework - rwPostUsersFailure"), message: error.localizedDescription)
            }
        }
    }

    func rwPostSessionsSuccess(_ data: Data) {
        protocaller { (rwfp, _) -> Void in
            self.dam { rwfp.rwPostSessionsSuccess?(data) }
        }
    }

    func rwPostSessionsFailure(_ error: Error) {
        protocaller { (rwfp, _) -> Void in
            if (rwfp.rwPostSessionsFailure != nil) {
                self.dam { rwfp.rwPostSessionsFailure?(error) }
            } else {
                self.alertOK(self.LS("RWFramework - rwPostSessionsFailure"), message: error.localizedDescription)
            }
        }
    }

    func rwGetProjectsIdSuccess(_ data: Data) {
        protocaller { (rwfp, _) -> Void in
            self.dam { rwfp.rwGetProjectsIdSuccess?(data) }
        }
    }
    
    func rwGetProjectsIdFailure(_ error: Error) {
        protocaller { (rwfp, _) -> Void in
            if (rwfp.rwGetProjectsIdFailure != nil) {
                self.dam { rwfp.rwGetProjectsIdFailure?(error) }
            } else {
                self.alertOK(self.LS("RWFramework - rwGetProjectsIdFailure"), message: error.localizedDescription)
            }
        }
    }
    
    func rwGetUIConfigSuccess(_ data: Data) {
        protocaller { (rwfp, _) -> Void in
            self.dam { rwfp.rwGetUIConfigSuccess?(data) }
        }
    }
    
    func rwGetUIConfigFailure(_ error: Error) {
        protocaller { (rwfp, _) -> Void in
            if (rwfp.rwGetUIConfigFailure != nil) {
                self.dam { rwfp.rwGetUIConfigFailure?(error) }
            } else {
                self.alertOK(self.LS("RWFramework - rwGetUIConfigFailure"), message: error.localizedDescription)
            }
        }
    }
    
    func rwGetProjectsIdUIGroupsSuccess(_ data: Data) {
        protocaller { (rwfp, _) -> Void in
            self.dam { rwfp.rwGetProjectsIdUIGroupsSuccess?(data) }
        }
    }
    
    func rwGetProjectsIdUIGroupsFailure(_ error: Error) {
        protocaller { (rwfp, _) -> Void in
            if (rwfp.rwGetProjectsIdUIGroupsFailure != nil) {
                self.dam { rwfp.rwGetProjectsIdUIGroupsFailure?(error) }
            } else {
                self.alertOK(self.LS("RWFramework - rwGetProjectsIdUIGroupsFailure"), message: error.localizedDescription)
            }
        }
    }

    func rwGetProjectsIdTagsSuccess(_ data: Data) {
        protocaller { (rwfp, _) -> Void in
            self.dam { rwfp.rwGetProjectsIdTagsSuccess?(data) }
        }
    }

    func rwGetProjectsIdTagsFailure(_ error: Error) {
        protocaller { (rwfp, _) -> Void in
            if (rwfp.rwGetProjectsIdTagsFailure != nil) {
                self.dam { rwfp.rwGetProjectsIdTagsFailure?(error) }
            } else {
                self.alertOK(self.LS("RWFramework - rwGetProjectsIdTagsFailure"), message: error.localizedDescription)
            }
        }
    }

    func rwGetTagCategoriesSuccess(_ data: Data) {
        protocaller { (rwfp, _) -> Void in
            self.dam { rwfp.rwGetTagCategoriesSuccess?(data) }
        }
    }
    
    func rwGetTagCategoriesFailure(_ error: Error) {
        protocaller { (rwfp, _) -> Void in
            if (rwfp.rwGetTagCategoriesFailure != nil) {
                self.dam { rwfp.rwGetTagCategoriesFailure?(error) }
            } else {
                self.alertOK(self.LS("RWFramework - rwGetTagCategoriesFailure"), message: error.localizedDescription)
            }
        }
    }

    func rwPostStreamsSuccess(_ data: Data) {
        protocaller { (rwfp, _) -> Void in
            self.dam { rwfp.rwPostStreamsSuccess?(data) }
        }
    }

    func rwPostStreamsFailure(_ error: Error) {
        protocaller { (rwfp, _) -> Void in
            if (rwfp.rwPostStreamsFailure != nil) {
                self.dam { rwfp.rwPostStreamsFailure?(error) }
            } else {
                self.alertOK(self.LS("RWFramework - rwPostStreamsFailure"), message: error.localizedDescription)
            }
        }
    }

    func rwPatchStreamsIdSuccess(_ data: Data) {
        protocaller { (rwfp, _) -> Void in
            self.dam { rwfp.rwPatchStreamsIdSuccess?(data) }
        }
    }

    func rwPatchStreamsIdFailure(_ error: Error) {
        protocaller { (rwfp, _) -> Void in
            if (rwfp.rwPatchStreamsIdFailure != nil) {
                self.dam { rwfp.rwPatchStreamsIdFailure?(error) }
            } else {
                self.alertOK(self.LS("RWFramework - rwPatchStreamsIdFailure"), message: error.localizedDescription)
            }
        }
    }

    func rwPostStreamsIdHeartbeatSuccess(_ data: Data) {
        protocaller { (rwfp, _) -> Void in
            self.dam { rwfp.rwPostStreamsIdHeartbeatSuccess?(data) }
        }
    }

    func rwPostStreamsIdHeartbeatFailure(_ error: Error) {
        protocaller { (rwfp, _) -> Void in
            if (rwfp.rwPostStreamsIdHeartbeatFailure != nil) {
                self.dam { rwfp.rwPostStreamsIdHeartbeatFailure?(error) }
            } else {
                self.alertOK(self.LS("RWFramework - rwPostStreamsIdHeartbeatFailure"), message: error.localizedDescription)
            }
        }
    }

    func rwPostStreamsIdReplaySuccess(_ data: Data) {
        protocaller { (rwfp, _) -> Void in
            self.dam { rwfp.rwPostStreamsIdReplaySuccess?(data) }
        }
    }
    
    func rwPostStreamsIdReplayFailure(_ error: Error) {
        protocaller { (rwfp, _) -> Void in
            if (rwfp.rwPostStreamsIdReplayFailure != nil) {
                self.dam { rwfp.rwPostStreamsIdReplayFailure?(error) }
            } else {
                self.alertOK(self.LS("RWFramework - rwPostStreamsIdReplayFailure"), message: error.localizedDescription)
            }
        }
    }

    func rwPostStreamsIdSkipSuccess(_ data: Data) {
        protocaller { (rwfp, _) -> Void in
            self.dam { rwfp.rwPostStreamsIdSkipSuccess?(data) }
        }
    }

    func rwPostStreamsIdSkipFailure(_ error: Error) {
        protocaller { (rwfp, _) -> Void in
            if (rwfp.rwPostStreamsIdSkipFailure != nil) {
                self.dam { rwfp.rwPostStreamsIdSkipFailure?(error) }
            } else {
                self.alertOK(self.LS("RWFramework - rwPostStreamsIdSkipFailure"), message: error.localizedDescription)
            }
        }
    }
    
    func rwPostStreamsIdPauseSuccess(_ data: Data) {
        protocaller { (rwfp, _) -> Void in
            self.dam { rwfp.rwPostStreamsIdPauseSuccess?(data) }
        }
    }
    
    func rwPostStreamsIdPauseFailure(_ error: Error) {
        protocaller { (rwfp, _) -> Void in
            if (rwfp.rwPostStreamsIdPauseFailure != nil) {
                self.dam { rwfp.rwPostStreamsIdPauseFailure?(error) }
            } else {
                self.alertOK(self.LS("RWFramework - rwPostStreamsIdPauseFailure"), message: error.localizedDescription)
            }
        }
    }
    
    func rwGetStreamsIdIsActiveSuccess(_ data: Data) {
        protocaller { (rwfp, _) -> Void in
            self.dam { rwfp.rwGetStreamsIdIsActiveSuccess?(data) }
        }
    }
    
    func rwGetStreamsIdIsActiveFailure(_ error: Error) {
        protocaller { (rwfp, _) -> Void in
            if (rwfp.rwGetStreamsIdIsActiveFailure != nil) {
                self.dam { rwfp.rwGetStreamsIdIsActiveFailure?(error) }
            } else {
                self.alertOK(self.LS("RWFramework - rwGetStreamsIdIsActiveFailure"), message: error.localizedDescription)
            }
        }
    }
    
    func rwPostStreamsIdResumeSuccess(_ data: Data) {
        protocaller { (rwfp, _) -> Void in
            self.dam { rwfp.rwPostStreamsIdResumeSuccess?(data) }
        }
    }
    
    func rwPostStreamsIdResumeFailure(_ error: Error) {
        protocaller { (rwfp, _) -> Void in
            if (rwfp.rwPostStreamsIdResumeFailure != nil) {
                self.dam { rwfp.rwPostStreamsIdResumeFailure?(error) }
            } else {
                self.alertOK(self.LS("RWFramework - rwPostStreamsIdResumeFailure"), message: error.localizedDescription)
            }
        }
    }

    func rwPostEnvelopesSuccess(_ data: Data) {
        protocaller { (rwfp, _) -> Void in
            self.dam { rwfp.rwPostEnvelopesSuccess?(data) }
        }
    }

    func rwPostEnvelopesFailure(_ error: Error) {
        protocaller { (rwfp, _) -> Void in
            if (rwfp.rwPostEnvelopesFailure != nil) {
                self.dam { rwfp.rwPostEnvelopesFailure?(error) }
            } else {
                self.alertOK(self.LS("RWFramework - rwPostEnvelopesFailure"), message: error.localizedDescription)
            }
        }
    }

    func rwPatchEnvelopesIdSuccess(_ data: Data) {
        protocaller { (rwfp, _) -> Void in
            self.dam { rwfp.rwPatchEnvelopesIdSuccess?(data) }
        }
    }

    func rwPatchEnvelopesIdFailure(_ error: Error) {
        protocaller { (rwfp, _) -> Void in
            if (rwfp.rwPatchEnvelopesIdFailure != nil) {
                self.dam { rwfp.rwPatchEnvelopesIdFailure?(error) }
            } else {
                self.alertOK(self.LS("RWFramework - rwPatchEnvelopesIdFailure"), message: error.localizedDescription)
            }
        }
    }

    func rwGetAssetsSuccess(_ data: Data) {
        protocaller { (rwfp, _) -> Void in
            self.dam { rwfp.rwGetAssetsSuccess?(data) }
        }
    }

    func rwGetAssetsFailure(_ error: Error) {
        protocaller { (rwfp, _) -> Void in
            if (rwfp.rwGetAssetsFailure != nil) {
                self.dam { rwfp.rwGetAssetsFailure?(error) }
            } else {
                self.alertOK(self.LS("RWFramework - rwGetAssetsFailure"), message: error.localizedDescription)
            }
        }
    }

    func rwGetAssetsIdSuccess(_ data: Data) {
        protocaller { (rwfp, _) -> Void in
            self.dam { rwfp.rwGetAssetsIdSuccess?(data) }
        }
    }

    func rwGetAssetsIdFailure(_ error: Error) {
        protocaller { (rwfp, _) -> Void in
            if (rwfp.rwGetAssetsIdFailure != nil) {
                self.dam { rwfp.rwGetAssetsIdFailure?(error) }
            } else {
                self.alertOK(self.LS("RWFramework - rwGetAssetsIdFailure"), message: error.localizedDescription)
            }
        }
    }
    
    func rwPatchAssetsIdSuccess(_ data: Data?) {
        protocaller { (rwfp, _) -> Void in
            self.dam { rwfp.rwPatchAssetsIdSuccess?(data) }
        }
    }
    
    func rwPatchAssetsIdFailure(_ error: Error) {
        protocaller { (rwfp, _) -> Void in
            if (rwfp.rwPatchAssetsIdFailure != nil) {
                self.dam { rwfp.rwPatchAssetsIdFailure?(error) }
            } else {
                self.alertOK(self.LS("RWFramework - rwPatchAssetsIdFailure"), message: error.localizedDescription)
            }
        }
    }

    func rwPostAssetsIdVotesSuccess(_ data: Data) {
        protocaller { (rwfp, _) -> Void in
            self.dam { rwfp.rwPostAssetsIdVotesSuccess?(data) }
        }
    }

    func rwPostAssetsIdVotesFailure(_ error: Error) {
        protocaller { (rwfp, _) -> Void in
            if (rwfp.rwPostAssetsIdVotesFailure != nil) {
                self.dam { rwfp.rwPostAssetsIdVotesFailure?(error) }
            } else {
                self.alertOK(self.LS("RWFramework - rwPostAssetsIdVotesFailure"), message: error.localizedDescription)
            }
        }
    }

    func rwGetAssetsIdVotesSuccess(_ data: Data) {
        protocaller { (rwfp, _) -> Void in
            self.dam { rwfp.rwGetAssetsIdVotesSuccess?(data) }
        }
    }

    func rwGetAssetsIdVotesFailure(_ error: Error) {
        protocaller { (rwfp, _) -> Void in
            if (rwfp.rwGetAssetsIdVotesFailure != nil) {
                self.dam { rwfp.rwGetAssetsIdVotesFailure?(error) }
            } else {
                self.alertOK(self.LS("RWFramework - rwGetAssetsIdVotesFailure"), message: error.localizedDescription)
            }
        }
    }
    
    
    func rwGetSpeakersSuccess(_ data: Data) {
        protocaller { (rwfp, _) -> Void in
            self.dam { rwfp.rwGetSpeakersSuccess?(data) }
        }
    }
    
    func rwGetSpeakersFailure(_ error: Error) {
        protocaller { (rwfp, _) -> Void in
            if (rwfp.rwGetSpeakersFailure != nil) {
                self.dam { rwfp.rwGetSpeakersFailure?(error) }
            } else {
                self.alertOK(self.LS("RWFramework - rwGetAssetsFailure"), message: error.localizedDescription)
            }
        }
    }
    
    

    func rwPostEventsSuccess(_ data: Data) {
        protocaller { (rwfp, _) -> Void in
            self.dam { rwfp.rwPostEventsSuccess?(data) }
        }
    }

    func rwPostEventsFailure(_ error: Error) {
        protocaller { (rwfp, _) -> Void in
            if (rwfp.rwPostEventsFailure != nil) {
                self.dam { rwfp.rwPostEventsFailure?(error) }
            } else {
                self.alertOK(self.LS("RWFramework - rwPostEventsFailure"), message: error.localizedDescription)
            }
        }
    }


// MARK: metadata

    func rwObserveValueForKeyPath(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        protocaller { (rwfp, _) -> Void in
            self.dam { rwfp.rwObserveValueForKeyPath?(forKeyPath: keyPath, of: object, change: change, context: context) }
        }
    }

// MARK: Image Picker

    func rwImagePickerControllerDidFinishPickingMedia(_ info: [AnyHashable: Any], path: String) {
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

    func rwRecordingProgress(_ percentage: Double, maxDuration: TimeInterval, peakPower: Float, averagePower: Float) {
        protocaller { (rwfp, _) -> Void in
            self.dam { rwfp.rwRecordingProgress?(percentage, maxDuration: maxDuration, peakPower: peakPower, averagePower: averagePower) }
        }
    }

    func rwPlayingBackProgress(_ percentage: Double, duration: TimeInterval, peakPower: Float, averagePower: Float) {
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

    func rwUpdateStatus(_ message: String, title: String? = "Roundware Notification") {
        var showedAlert = false
        protocaller { (rwfp, _) -> Void in
            if (rwfp.rwUpdateStatus != nil) {
                self.dam { rwfp.rwUpdateStatus?(message) }
            } else if (showedAlert == false) {
                showedAlert = true // Only show the alert once per call
                self.dam {
                    let alert = UIAlertController(title: self.LS(title!), message: message, preferredStyle: UIAlertController.Style.alert)
                    let OKAction = UIAlertAction(title: self.LS("OK"), style: .default) { (action) in }
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

    func rwUpdateApplicationIconBadgeNumber(_ count: Int) {
        protocaller { (rwfp, _) -> Void in
            self.dam { rwfp.rwUpdateApplicationIconBadgeNumber?(count) }
        }
    }

// MARK: Location

    func rwLocationManager(_ manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        protocaller { (rwfp, _) -> Void in
            self.dam { rwfp.rwLocationManager?(manager, didUpdateLocations: locations) }
        }
    }

    func rwLocationManager(_ manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        protocaller { (rwfp, _) -> Void in
            self.dam { rwfp.rwLocationManager?(manager, didChangeAuthorizationStatus: status) }
        }
    }

}
