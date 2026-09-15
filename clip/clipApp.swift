//
//  clipApp.swift
//  clip
//
//  Created by Joel on 15/09/26.
//

import SwiftUI

@main
struct clipApp: App {
    #if os(iOS)
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    #endif

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
