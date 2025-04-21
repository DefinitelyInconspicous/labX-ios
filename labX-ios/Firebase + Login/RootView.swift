//
//  RootView.swift
//  labX-ios
//
//  Created by Avyan Mehra on 14/4/25.
//

import Foundation
import SwiftUI
import Firebase

struct RootView: View {
    @StateObject private var auth = AuthManager.shared

    var body: some View {
        if auth.user != nil {
            ContentView()
        } else {
            LoginView()
        }
    }
}
