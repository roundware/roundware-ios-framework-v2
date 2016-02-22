//
//  AppDelegate.swift
//  RWExample
//
//  Created by Joe Zobkiw on 1/24/15.
//  Copyright (c) 2015 Roundware. All rights reserved.
//

import UIKit
import RWFramework
import AVFoundation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        // Configure AVAudioSession for the application
        let avAudioSession = AVAudioSession.sharedInstance()
        var error: NSError?

        // This can be moved to the appropriate place in the application where it makes sense
        avAudioSession.requestRecordPermission { (granted: Bool) -> Void in
            print("AppDelegate: record permission granted: \(granted)")
        }

        // Play and record for VOIP
        do {
            try avAudioSession.setCategory(AVAudioSessionCategoryPlayAndRecord)
        } catch let error1 as NSError {
            error = error1
            print("AppDelegate: could not set session category")
            if let e = error {
                print(e.localizedDescription)
            }
        }

        // Send audio to the speaker
        do {
            try avAudioSession.overrideOutputAudioPort(AVAudioSessionPortOverride.Speaker)
        } catch let error1 as NSError {
            error = error1
            print("AppDelegate: could not overide output audio port")
            if let e = error {
                print(e.localizedDescription)
            }
        }

        // Activiate the AVAudioSession
        do {
            try avAudioSession.setActive(true)
        } catch let error1 as NSError {
            error = error1
            print("AppDelegate: could not make session active")
            if let e = error {
                print(e.localizedDescription)
            }
        }

        let rwf = RWFramework.sharedInstance
        rwf.addDelegate(self)

        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

