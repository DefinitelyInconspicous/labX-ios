//
//  VerificationView.swift
//  labX-ios
//
//  Created by Avyan Mehra on 30/8/25.
//

import SwiftUI

struct VerificationView: View {
    @Binding var verificationMessage: String
    @Binding var showVerificationSheet: Bool
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "envelope.circle.fill")
                .resizable()
                .frame(width: 100, height: 100)
            Text("Email Verification Required")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.top)
            Text(verificationMessage)
                .foregroundColor(.orange)
                .font(.body)
                .multilineTextAlignment(.center)
                .padding()
            Button("Resend Verification Email") {
                AuthManager.shared.resendVerificationEmail { error in
                    if let error = error {
                        verificationMessage = "Failed to resend: \(error.localizedDescription)"
                    } else {
                        verificationMessage = "Verification email resent. Please check your inbox."
                    }
                }
            }
            .font(.footnote)
            .padding(.vertical, 4)
            Button("Check Verification Status") {
                AuthManager.shared.checkEmailVerified { verified in
                    if verified {
                        showVerificationSheet = false
                        verificationMessage = "Email verified! You can now log in."
                    } else {
                        verificationMessage = "Email not verified yet. Please check your inbox."
                    }
                }
            }
            .font(.footnote)
            .padding(.bottom, 8)
            Button("Close") {
                showVerificationSheet = false
            }
        }
        .padding()
    }
}

#Preview {
    VerificationView(verificationMessage: .constant("Please verify your email to continue."), showVerificationSheet: .constant(true))
}
