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

        // This can be moved to the appropriate place in the application where it makes sense
        avAudioSession.requestRecordPermission { (granted: Bool) -> Void in
            print("AppDelegate: record permission granted: \(granted)")
        }

        do {
            // Play and record for VOIP
            try avAudioSession.setCategory(AVAudioSessionCategoryPlayAndRecord)
            // Send audio to the speaker
            try avAudioSession.overrideOutputAudioPort(AVAudioSessionPortOverride.Speaker)
            // Activiate the AVAudioSession
            try avAudioSession.setActive(true)
        } catch {
            print("RWExample - Couldn't setup audio session \(error)")
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

