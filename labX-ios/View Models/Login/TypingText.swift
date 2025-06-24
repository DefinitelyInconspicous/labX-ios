//
//  TypingText.swift
//  labX-ios
//
//  Created by Avyan Mehra on 23/6/25.
//

import SwiftUI

struct TypingText: View {
    let fullText: String
    @State private var displayText = ""
    @State private var cursorVisible = true
    @State private var isTypingFinished = false
    
    var body: some View {
        HStack {
            Text(displayText)
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            if !isTypingFinished {
                Text(cursorVisible ? "|" : "")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .animation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true), value: cursorVisible)
            }
        }
        .onAppear {
            typeText()
            startBlinkingCursor()
        }
    }
    
     func typeText() {
        displayText = ""
        var charIndex = 0
        Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { timer in  // Slow down typing speed
            if charIndex < fullText.count {
                let index = fullText.index(fullText.startIndex, offsetBy: charIndex)
                displayText.append(fullText[index])
                charIndex += 1
            } else {
                timer.invalidate()
                isTypingFinished = true
            }
        }
    }
    
     func startBlinkingCursor() {
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            if isTypingFinished {
                cursorVisible.toggle()
            }
        }
    }
}
