//
//  SplashScreenView.swift
//  labX-ios
//
//  Created by Avyan Mehra on 22/6/25
//

import SwiftUI

struct SplashScreenView: View {
    @State private var logoScale: CGFloat = 0.5
    @State private var logoOpacity: Double = 0.0
    @State private var textOpacity: Double = 0.0
    @State private var versionOpacity: Double = 0.0
    @State private var isAnimating = false
    @State private var pulseScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // Animated background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.blue.opacity(0.8),
                    Color.gray.opacity(0.6),
                    Color.blue.opacity(0.4)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Floating particles effect
            ForEach(0..<6, id: \.self) { index in
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: CGFloat.random(in: 4...12))
                    .position(
                        x: CGFloat.random(in: 50...350),
                        y: CGFloat.random(in: 100...800)
                    )
                    .animation(
                        Animation.easeInOut(duration: Double.random(in: 2...4))
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.3),
                        value: isAnimating
                    )
            }
            
            VStack(spacing: 30) {
                // App Logo/Icon with enhanced effects
                ZStack {
                    // Outer glow
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 140, height: 140)
                        .blur(radius: 30)
                        .scaleEffect(pulseScale)
                    
                    // Inner glow
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 120, height: 120)
                        .blur(radius: 20)
                    
                    // Main icon
                    Image("iconcopy")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 200, height: 200)
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)
                        .shadow(color: .white.opacity(0.3), radius: 10, x: 0, y: 0)
                }
                
                // App Name with enhanced typography
                VStack(spacing: 8) {
                    Text("labX")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .opacity(textOpacity)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                }
                
                // Enhanced loading indicator
                VStack(spacing: 12) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.2)
                        .opacity(textOpacity)
                        .shadow(color: .white.opacity(0.3), radius: 5, x: 0, y: 0)
                    
                    Text("Loading...")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .opacity(textOpacity)
                }
                
                Spacer()
                
                // Version and branding
                VStack(spacing: 4) {
                    Text("Version Beta 1.0.0")
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
            // Trigger haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            
            startAnimation()
        }
    }
    
    private func startAnimation() {
        // Animate logo appearance
        withAnimation(.easeOut(duration: 1.0).delay(0.2)) {
            logoScale = 1.0
            logoOpacity = 1.0
        }
        
        // Animate text appearance
        withAnimation(.easeOut(duration: 0.8).delay(0.8)) {
            textOpacity = 1.0
        }
        
        // Animate version text appearance
        withAnimation(.easeOut(duration: 0.6).delay(1.2)) {
            versionOpacity = 1.0
        }
        
        // Start pulsing animation
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true).delay(1.5)) {
            pulseScale = 1.1
        }
        
        // Start particle animation
        withAnimation(.easeInOut(duration: 1.0).delay(1.0)) {
            isAnimating = true
        }
    }
}

#Preview {
    SplashScreenView()
} 
