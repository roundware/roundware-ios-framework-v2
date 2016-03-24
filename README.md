# RWFramework
Roundware framework, updated for API v2 and re-built in Swift and made open source. See <http://roundware.org> for more information on configuring the server and other components.

What is Roundware?

> Roundware is a flexible, distributed framework which collects, stores, organizes and re-presents audio content. Basically, it lets you collect audio from anyone with a smartphone or web access, upload it to a central repository along with its metadata and then filter it and play it back collectively in continuous audio streams.


## Introduction

This project consists of the Roundware framework (RWFramework) and an example app that implements the framework. Open the `Example/RWFramework.xcworkspace` Xcode workspace to examine and run the project. The file structure follows from <https://github.com/CocoaPods/pod-template>.

The code is written in Swift 2.0 and currently requires Xcode 7.2 or later and iOS 9 or later.

You can look throughout the code for all methods marked `public` to see what is available to your application. This document outlines some of the more common use cases. Be sure to read the comments on the methods you plan to use.


## Setup

RWFramework is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your `Podfile`:

```ruby
pod "RWFramework"
```

Then install.

```bash
pod install
```


A `RWFramework.plist` is required with minimum parameters defined. See the server setup documentation for more information.

## RWFramework_Example

You can try the example out like so:

```bash
pod try RWFramework
```

In order to demo any functionality in the simulator, you will need to set the location to `Debug` > `Location` > `Apple`.

We use fastlane to load onto our device. Edit the fastlane configuration, add a `devices.txt` and install [ios-deploy](https://github.com/phonegap/ios-deploy). Plug in your device and then run this command to load the example onto your device the first time.

    fastlane load first:true


## Usage

Your application is responsible for configuring the `AVAudioSession` for itself. You can see an example of this in the example app in `AppDelegate.swift`.

Note, however, that `RWFrameworkAudioRecorder.m` was provided and added to the project to facilitate a more advanced way of recording audio that would allow VoiceOver audio to be filtered out of the recorded audio. The `useComplexRecordingMechanism` global flag is used to set whether this mechanism is used. If `useComplexRecordingMechanism` is set to true note that certain aspects of the `AVAudioSession` will be set internally in the framework. See `setupAudioSession` in `RWFrameworkAudioRecorder.m` for details.


### Initialization

In order to start using the framework, sometime after you've setup the `AVAudioSession` you should start the framework running by setting yourself as the `delegate` of the `sharedInstance` and then calling the `start()` method.

    var rwf = RWFramework.sharedInstance
    rwf.addDelegate(self)
    rwf.start(letFrameworkRequestWhenInUseAuthorizationForLocation: false)

Note that setting a delegate is not required but your app will be next to useless without it. You can set multiple delegates and all will be called with whatever protocol methods they implement. This allows you to have a view controller only handle the methods it cares about. Be sure to call `removeDelegate(object: AnyObject)` when an object no longer wants to be the delegate (or is deleted).

When you are completely done with the framework you should call `rwf.end()` to give the framework a chance to cleanup anything it needs to cleanup.

If you want to change the `project_id` after initialization, you can use `setProjectId`.

### Listening

##### Playing or stopping a stream

Anytime after receiving the `rwPostStreamsSuccess()` delegate method callback you can instruct the framework to play or pause the audio stream.

    var rwf = RWFramework.sharedInstance
    rwf.isPlaying ? rwf.stop() : rwf.play()

Other methods regarding audio playback include:

- `canPlay() -> Bool`
- `play()`
- `pause()`
- `stop()`
- `next()`

See `RWFrameworkAudioPlayer.swift`




### Speak Assets

The framework has a number of ways to automatically handle adding assets of various types to its internal queue to be uploaded. However, if your app needs more control you can always add them manually as well.



##### Attaching an audio asset

The key methods for recording, playing back and submitting an audio recording are as follows

Recording

- `canRecord() -> Bool`
- `startRecording()`
- `stopRecording()`
- `isRecording() -> Bool`

Resetting a recording (recording again)

- `hasRecording() -> Bool`
- `deleteRecording()`

Adding or removing a recording from the queue to upload

- `addRecording(description: String = "") -> String?`
- `setRecordingDescription(string: String, description: String)`
- `removeRecording(string: String)`

Playing back a recording

- `startPlayback()`
- `stopPlayback()`
- `isPlayingBack() -> Bool`

Note that the standard `AVAudioRecorderDelegate` and `AVAudioPlayerDelegate` callbacks are also passed thru to the delegate via `rwAudioRecorderDidFinishRecording()` and `rwAudioPlayerDidFinishPlaying()` for your convenience.

See `RWFrameworkAudioRecorder.swift`




##### Attaching a photo asset from the camera

Simply call `doImage()`

You can add an image manually by calling `addImage(string: String, description: String = "") -> String?` passing the path to the image as the string. The return value is a key to be used when referencing this asset.

Also see the `rwImagePickerControllerDidFinishPickingMedia` delegate protocol method

See `RWFrameworkCamera.swift`




##### Attaching a movie asset from the camera

Simply call `doMovie()`

You can add a movie manually by calling `addMovie(string: String, description: String = "") -> String?` passing the path to the movie. The return value is a key to be used when referencing this asset.

Also see the `rwImagePickerControllerDidFinishPickingMedia` delegate protocol method

See `RWFrameworkCamera.swift`




##### Attaching an image or movie asset from the photo library

Simply call `doPhotoLibrary()`

You can add an image or movie manually by calling `addImage(string: String)` or `addMovie(string: String)` passing the path to the asset

See `RWFrameworkCamera.swift`




##### Attaching a text asset

Simply call `addText(string: String, description: String = "") -> String?`

The return value is a key to be used when referencing this asset.

See `RWFrameworkText.swift`




##### Removing an asset from the queue

To remove an asset, you must use the key returned from the `add*` method or the `rwImagePickerControllerDidFinishPickingMedia` delegate protocol method.

To remove an audio recording simply call `removeRecording(string: String)`.

To remove a text asset simply call `removeText(string: String)` passing the string returned from `addText(string: String, description: String = "") -> String?`.

If you added an image or movie asset you can call the associated `remove` method to remove the item. For example, if you called `addImage(string: String, description: String = "") -> String?` or `addMovie(string: String, description: String = "") -> String?` with the path of the assets, simply call `removeImage(string: String)` or `removeMovie(string: String)` to remove them, passing the key that was returned from the `add*` call.




##### Submitting all attached assets and managing the queue

You can see how many assets are ready for upload by calling `countMedia() -> Int`.

When you are ready to submit all the queued assets simply call `uploadAllMedia()`




##### Failed media

There are times when uploads may fail. Errors are reported back to your application via the delegate protocol method. There are a number of methods designed to help your application manage these failures and allow the framework to try uploading again.

`resetAllRetryCounts()` can be called at application startup to reset any failed uploads to try again.

`countUploadFailedMedia() -> Int` will return the number of items that have currently failed to upload.

`purgeUploadFailedMedia()` will delete any media that has failed to upload at least once.



### Tags

Your applicatin can get all the tags and organize them according to UIGroups.  Use the methods in the framework to get and set them accordingly.

See `RWFrameworkTags.swift` and `RWFrameworkUIGroups.swift`

### Tags

Tags can be submitted by calling `submitTags()`. This will update the current stream (if playing) accordingly.

Tags can and should be uploaded with media content by passing their IDs joined as a string as an argument to  `uploadAllMedia()`. 

See `RWFrameworkTags.swift`


### Assets

Not many methods in `RWFrameworkAPI.swift` are public as most of them are used internally but a few are available for application use.

To get a list of assets for a project or session you can call `apiGetAssets(dict: [String:String], success:(data: NSData?) -> Void, failure:(error: NSError) -> Void)`. Note that the `dict` is a dictionary of filters documented in the API documentation for the GET Assets endpoint. It can be nil.

To get the details of a specific asset you can call `apiGetAssetsId(asset_id: String, success:(data: NSData?) -> Void, failure:(error: NSError) -> Void)`.

See `RWFrameworkAPI.swift`




### Voting

You can vote on an asset by calling the `apiPostAssetsIdVotes(asset_id: String, session_id: String, vote_type: String, value: NSNumber = 0, success:(data: NSData?) -> Void, failure:(error: NSError) -> Void)` method. See the documentation for valid vote_types and value parameter specifics.

You can get the votes for an asset by calling the `apiGetAssetsIdVotes(asset_id: String, success:(data: NSData?) -> Void, failure:(error: NSError) -> Void)` method.




### RWFrameworkProtocol

Your application can implement the `RWFrameworkProtocol` in order to be kept in tune with the workings of the framework. Review `RWFrameworkProtocol.swift` for all the methods you can implement and when they are called throughout the lifecycle of the framework.

NOTE: You can have any number of delegates receive these calls simply by adding and removing them using the `addDelegate(object: AnyObject)` and `removeDelegate(object: AnyObject)` calls.

NOTE: All of these methods will be called on the main thread.

NOTE: The example app shows how some of them are used in the `ViewController.swift` file.

See `RWFrameworkProtocol.swift`

## Development

`RWFramework` depends on `SwiftyJSON` so you will need to run:

```bash
pod install
```


##Authors

- Joe Zobkiw, @zobskewed
- Christopher Reed, @seereadnow

## License

RWFramework is available under the MIT license. See the LICENSE file for more info.
