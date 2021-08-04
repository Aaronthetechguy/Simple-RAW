//
//  AppDelegate.swift
//  camera version 2
//
//  Created by Aaron Goldgewert on 11/5/20.
//

import UIKit

@main

class AppDelegate: UIResponder, UIApplicationDelegate {
    var enableAllOrientation = false


    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        if (enableAllOrientation == true){
            return UIInterfaceOrientationMask.allButUpsideDown
        }
        return UIInterfaceOrientationMask.portrait
    }


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }

}
