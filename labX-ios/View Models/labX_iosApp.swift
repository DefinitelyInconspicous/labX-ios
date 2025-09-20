//
//  labX_iosApp.swift
//  labX-ios
///Users/dhanushpartha/Downloads/labX-ios/labX-ios.xcodeproj
//  Created by Avyan Mehra on 17/3/25.
//

import Firebase
import FirebaseCore
import SwiftUI

@main
struct labX_iosApp: App {
    init() {
        FirebaseApp.configure()
    }
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}


