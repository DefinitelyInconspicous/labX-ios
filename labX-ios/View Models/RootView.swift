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
    @State private var showSplash = true

    var body: some View {
        ZStack {
            if showSplash {
                SplashScreenView()
                    .transition(.opacity)
                    .zIndex(1)
            } else {
                Group {
                    if auth.user != nil {
                        ContentView()                            
                    } else {
                        LoginView()
                    }
                }
                .transition(.opacity)
                .zIndex(0)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                withAnimation {
                    showSplash = false
                }
            }
        }
    }
}
