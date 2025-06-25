//
//  ForgotPassword.swift
//  labX-ios
//
//  Created by Dhanush  on 25/6/25.
//

import SwiftUI

import SwiftUI
import FirebaseAuth

struct ForgotPassword: View {
    @State private var email = ""
    @State private var message = ""
    @State private var showAlert = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Email")
                        .font(.caption)
                        .foregroundColor(.gray)
                    TextField("Enter your email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
                }
                
                Button(action: resetPassword) {
                    Text("Send Reset Link")
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(email.isEmpty)
                
                Spacer()
            }
            .padding()
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Password Reset"),
                    message: Text(message),
                    dismissButton: .default(Text("OK"))
                )
            }
            .navigationTitle("Password Reset")
        }
    }

    private func resetPassword() {
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error = error {
                message = error.localizedDescription
            } else {
                message = "A password reset email has been sent."
            }
            showAlert = true
        }
    }
}

#Preview {
    ForgotPassword()
}
