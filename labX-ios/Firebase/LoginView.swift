//
//  LoginView.swift
//  labX-ios
//
//  Created by Avyan Mehra on 14/4/25.
//


import SwiftUI

struct User: Identifiable, Codable {
    var id: String = UUID().uuidString
    var firstName: String
    var lastName: String
    var email: String
    var className: String
    var registerNumber: String
}



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

    private func typeText() {
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

    private func startBlinkingCursor() {
        // Only start the cursor after typing is done
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            if isTypingFinished {
                cursorVisible.toggle()
            }
        }
    }
}


struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isRegistering = false
    @State private var errorMessage = ""
    @State private var isEmailValid = true
    @State private var isPasswordValid = true
    @State private var confirmPassword = ""
    @State private var selectedClass = "S1-01"
    @State private var registerNumber = "01"
    @State private var showAlert = false


    let classes = (1...4).flatMap { level in (1...10).map { "S\(level)-\($0 < 10 ? "0\($0)" : "\($0)")" } }
    let registerNumbers = (1...30).map { $0 < 10 ? "0\($0)" : "\($0)" }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                TypingText(fullText: "Welcome to labX")
                    .padding(.top, 40)

                VStack(spacing: 16) {
                    Group {
                        VStack(alignment: .leading, spacing: 6) {
                            TextField("Email", text: $email)
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .padding()
                                .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
                                .onChange(of: email) { _ in
                                    errorMessage = ""
                                    isEmailValid = true
                                }

                            if !isEmailValid && !errorMessage.isEmpty {
                                Text(errorMessage)
                                    .foregroundColor(.red)
                                    .font(.caption)
                            }
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            SecureField("Password", text: $password)
                                .textContentType(.password)
                                .padding()
                                .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))

                            if !isPasswordValid && !errorMessage.isEmpty {
                                Text("Password cannot be empty")
                                    .foregroundColor(.red)
                                    .font(.caption)
                            }
                        }
                    }

                    if isRegistering {
                        Group {
                            VStack(alignment: .leading, spacing: 6) {
                                SecureField("Confirm Password", text: $confirmPassword)
                                    .padding()
                                    .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
                            }
                            HStack {
                                Spacer()
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Class")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Picker("Class", selection: $selectedClass) {
                                        ForEach(classes, id: \.self) { Text($0) }
                                    }
                                    .pickerStyle(.menu)
                                    .padding()
                                    .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
                                }
                                
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Register Number")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Picker("Register Number", selection: $registerNumber) {
                                        ForEach(registerNumbers, id: \.self) { Text($0) }
                                    }
                                    .pickerStyle(.menu)
                                    .padding()
                                    .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
                                }
                                Spacer()
                            }
                        }
                    }
                }

                VStack(spacing: 16) {
                    Button(action: {
                        validateEmail(email)
                        validatePassword(password)

                        if isEmailValid && isPasswordValid {
                            if isRegistering {
                                AuthManager.shared.signIn(email: email, password: password) { error in
                                    if let error = error {
                                        errorMessage = error.localizedDescription
                                        showAlert = true
                                    }
                                }

                            } else {
                                AuthManager.shared.signIn(email: email, password: password) { error in
                                    if let error = error {
                                        errorMessage = error.localizedDescription
                                        showAlert = true
                                    }
                                }

                            }
                        }
                    }) {
                        Text(isRegistering ? "Sign Up" : "Log In")
                            .bold()
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }

                    Button(isRegistering ? "Have an account? Log in" : "No account? Sign up") {
                        isRegistering.toggle()
                    }
                    .foregroundColor(.blue)
                    .font(.footnote)
                }
                .alert(isPresented: $showAlert) {
                    Alert(
                        title: Text("Login Failed"),
                        message: Text(" \(errorMessage == "The supplied auth credential is malformed or has expired." ? "No account found. Please sign up." : "OR \(errorMessage)")"),
                        dismissButton: .default(Text("OK"))
                    )
                }

            }
            .padding()
        }
    }

    private func validateEmail(_ email: String) {
        let pattern = #"^[A-Za-z0-9._%+-]+@s20\d{2}\.ssts\.edu\.sg$"#
        let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        let range = NSRange(location: 0, length: email.utf16.count)

        if let match = regex?.firstMatch(in: email, options: [], range: range),
           match.range.location != NSNotFound {
            isEmailValid = true
            errorMessage = ""
        } else {
            isEmailValid = false
            errorMessage = "Email must end with @s20XX.ssts.edu.sg"
        }
    }

    private func validatePassword(_ password: String) {
        if password.isEmpty {
            isPasswordValid = false
            errorMessage = "Password cannot be empty"
        } else {
            isPasswordValid = true
        }
    }
}
