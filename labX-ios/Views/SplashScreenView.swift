//
//  SplashScreenView.swift
//  labX-ios
//
//  Created by Avyan Mehra on 22/6/25
//

import SwiftUI

struct SplashScreenView: View {
    @State private var logoOpacity: Double = 0.0
    @State private var textOpacity: Double = 0.0
    @State private var versionOpacity: Double = 0.0
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Image("iconcopy")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 180, height: 180)
                    .cornerRadius(20)
                    .opacity(logoOpacity)
                
                Text("labX")
                    .font(.system(size: 60, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .opacity(textOpacity)
                
                Spacer()
                
                VStack(spacing: 4) {
                    Text("Release 1.1.2")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                        .opacity(versionOpacity)
                    
                    Text("Brought to you by teamX 2024 - 2025")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(.white.opacity(0.5))
                        .opacity(versionOpacity)
                }
                .padding(.bottom, 50)
            }
            .padding(.top, 100)
        }
        .onAppear {
            let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
            impactFeedback.impactOccurred()
            
            withAnimation(.easeOut(duration: 1.0)) {
                logoOpacity = 1.0
            }
            withAnimation(.easeOut(duration: 1.0).delay(0.5)) {
                textOpacity = 1.0
            }
            withAnimation(.easeOut(duration: 1.0).delay(1.0)) {
                versionOpacity = 1.0
            }
        }
    }
}

#Preview {
    SplashScreenView()
}
