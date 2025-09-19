//
//  LoginView.swift
//  labX-ios
//
//  Created by Avyan Mehra on 14/4/25.
//


import SwiftUI
import FirebaseAuth
import FirebaseCore
import FirebaseFirestore

struct LoginView: View {
    @StateObject private var auth = AuthManager.shared
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
    @State private var isStaffEmail = false
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var isStaffSignup = false
    @State private var resetPasswordSheetShowing = false
    @State private var showVerificationSheet = false
    @State private var verificationMessage = ""
    @State private var isEmailVerified = false
    @Namespace private var namespace
    var classes = (1...4).flatMap { level in (1...10).map { "S\(level)-\($0 < 10 ? "0\($0)" : "\($0)")" } }
    var registerNumbers = (1...30).map { $0 < 10 ? "0\($0)" : "\($0)" }
    
    private let bypassEmails = [
        "iamastaff@sst.edu.sg",
        "avyan_mehra@s2023.ssts.edu.sg"
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    TypingText(fullText: "Welcome to labX")
                        .padding(.top, 40)
                    
                    Group {
                        if #available(iOS 26, *) {
                            GlassEffectContainer {
                                formFields
                            }
                        } else {
                            formFields
                        }
                    }
                    .padding(.horizontal)
                    
                    VStack(spacing: 16) {
                        
                        if #available(iOS 26, *) {
                            Button {
                                handleAuthentication()
                            } label: {
                                Text(isRegistering ? "Sign Up" : "Log In")
                                    .bold()
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                            }
                            .buttonStyle(.glassProminent)
                            .tint(.blue)
                            .glassEffectID("primaryButton", in: namespace)
                        } else {
                            Button {
                                handleAuthentication()
                            } label: {
                                Text(isRegistering ? "Sign Up" : "Log In")
                                    .bold()
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                                    .modifier(GlassEffectIfAvailableRounded(cornerRadius: 10))
                            }
                        }
                        
                        if #available(iOS 26, *) {
                            Button {
                                isRegistering.toggle()
                                errorMessage = ""
                                isEmailValid = true
                                isPasswordValid = true
                                isStaffSignup = false
                                if !isRegistering {
                                    firstName = ""
                                    lastName = ""
                                    confirmPassword = ""
                                }
                            } label: {
                                Text(isRegistering ? "Have an account? Log in" : "No account? Sign up")
                            }
                            .buttonStyle(.glass)
                            .tint(.blue)
                            .font(.footnote)
                        } else {
                            Button {
                                isRegistering.toggle()
                                errorMessage = ""
                                isEmailValid = true
                                isPasswordValid = true
                                isStaffSignup = false
                                if !isRegistering {
                                    firstName = ""
                                    lastName = ""
                                    confirmPassword = ""
                                }
                            } label: {
                                Text(isRegistering ? "Have an account? Log in" : "No account? Sign up")
                                    .foregroundColor(.blue)
                                    .font(.footnote)
                            }
                        }
                        
                        if #available(iOS 26, *) {
                            Button {
                                resetPasswordSheetShowing = true
                            } label: {
                                Text("Forgot Password?")
                            }
                            .buttonStyle(.glass)
                            .tint(.blue)
                            .font(.footnote)
                            .sheet(isPresented: $resetPasswordSheetShowing) {
                                ForgotPassword(email: $email)
                            }
                        } else {
                            Button {
                                resetPasswordSheetShowing = true
                            } label: {
                                Text("Forgot Password?")
                                    .font(.footnote)
                                    .foregroundStyle(.blue)
                            }
                            .sheet(isPresented: $resetPasswordSheetShowing) {
                                ForgotPassword(email: $email)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .onChange(of: auth.authErrorMessage) { newMessage in
                if let newMessage = newMessage {
                    // If this is a bypass email, ignore verification-related messages
                    if bypassEmails.contains(email.lowercased()) {
                        // Clear any verification UI for bypass users
                        showVerificationSheet = false
                        errorMessage = ""
                        showAlert = false
                        return
                    }
                    errorMessage = newMessage
                    showAlert = true
                    if newMessage.contains("verify your email") {
                        showVerificationSheet = true
                        verificationMessage = "A verification email has been sent. Please verify your email before logging in."
                    }
                }
            }
            .onAppear {
                checkEmailVerificationOnLaunch()
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Login Failed"),
                    message: Text(errorMessage == "The supplied auth credential is malformed or has expired." ? "No account found. Please sign up." : errorMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .sheet(
                isPresented: $showVerificationSheet,
                onDismiss: {
                    // Skip verification re-check for bypass users
                    if bypassEmails.contains(email.lowercased()) { return }
                    AuthManager.shared.checkEmailVerified { verified in
                        DispatchQueue.main.async {
                            isEmailVerified = verified
                            verificationMessage = verified
                            ? "Email verified! You can now log in."
                            : "Please verify your email before logging in."
                        }
                    }
                },
                content: {
                    VerificationView(
                        verificationMessage: $verificationMessage,
                        showVerificationSheet: $showVerificationSheet
                    )
                }
            )
            
        }
    }
    @ViewBuilder
    private var formFields: some View {
        VStack(spacing: 16) {
            if isRegistering {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("First Name")
                            .font(.caption)
                            .foregroundColor(.gray)
                        if #available(iOS 26, *) {
                            TextField("First Name", text: $firstName)
                                .textContentType(.givenName)
                                .padding()
                                .glassEffect(.regular, in: .rect(cornerRadius: 10))
                        } else {
                            TextField("First Name", text: $firstName)
                                .textContentType(.givenName)
                                .padding()
                                .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Last Name")
                            .font(.caption)
                            .foregroundColor(.gray)
                        if #available(iOS 26, *) {
                            TextField("Last Name", text: $lastName)
                                .textContentType(.familyName)
                                .padding()
                                .glassEffect(.regular, in: .rect(cornerRadius: 10))
                        } else {
                            TextField("Last Name", text: $lastName)
                                .textContentType(.familyName)
                                .padding()
                                .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
                        }
                    }
                }
            }
            VStack(alignment: .leading, spacing: 6) {
                Text("Email")
                    .font(.caption)
                    .foregroundColor(.gray)
                if #available(iOS 26, *) {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .padding()
                        .glassEffect(.regular, in: .rect(cornerRadius: 10))
                        .onChange(of: email) { newEmail in
                            validateEmail(newEmail)
                            isStaffSignup = newEmail.lowercased().hasSuffix("@sst.edu.sg")
                            if isStaffSignup {
                                selectedClass = "Staff"
                                registerNumber = "Staff"
                            }
                        }
                } else {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
                        .onChange(of: email) { newEmail in
                            validateEmail(newEmail)
                            isStaffSignup = newEmail.lowercased().hasSuffix("@sst.edu.sg")
                            if isStaffSignup {
                                selectedClass = "Staff"
                                registerNumber = "Staff"
                            }
                        }
                }
                
                
                if !isEmailValid && !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
            VStack(alignment: .leading, spacing: 6) {
                Text("Password")
                    .font(.caption)
                    .foregroundColor(.gray)
                if #available(iOS 26, *) {
                    SecureField("Password", text: $password)
                        .textContentType(.password)
                        .padding()
                        .glassEffect(.regular, in: .rect(cornerRadius: 10))
                        .onChange(of: password) { _ in
                            validatePassword(password)
                        }
                } else {
                    SecureField("Password", text: $password)
                        .textContentType(.password)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
                        .onChange(of: password) { _ in
                            validatePassword(password)
                        }
                }
                
                if !isPasswordValid && !errorMessage.isEmpty {
                    Text("Password cannot be empty")
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
            
            if isRegistering {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Confirm Password")
                        .font(.caption)
                        .foregroundColor(.gray)
                    if #available(iOS 26, *) {
                        SecureField("Confirm Password", text: $confirmPassword)
                            .textContentType(.password)
                            .padding()
                            .glassEffect(.regular, in: .rect(cornerRadius: 10))
                    } else {
                        SecureField("Confirm Password", text: $confirmPassword)
                            .textContentType(.password)
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
                    }
                }
                
                if !isStaffSignup {
                    HStack {
                        Spacer()
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Class")
                                .font(.caption)
                                .foregroundColor(.gray)
                            if #available(iOS 26, *) {
                                Picker("Class", selection: $selectedClass) {
                                    ForEach(classes, id: \.self) { Text($0) }
                                }
                                .pickerStyle(.menu)
                                .padding()
                                .glassEffect(.regular, in: .rect(cornerRadius: 10))
                            } else {
                                Picker("Class", selection: $selectedClass) {
                                    ForEach(classes, id: \.self) { Text($0) }
                                }
                                .pickerStyle(.menu)
                                .padding()
                                .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Register Number")
                                .font(.caption)
                                .foregroundColor(.gray)
                            if #available(iOS 26, *) {
                                Picker("Register Number", selection: $registerNumber) {
                                    ForEach(registerNumbers, id: \.self) { Text($0) }
                                }
                                .pickerStyle(.menu)
                                .padding()
                                .glassEffect(.regular, in: .rect(cornerRadius: 10))
                            } else {
                                Picker("Register Number", selection: $registerNumber) {
                                    ForEach(registerNumbers, id: \.self) { Text($0) }
                                }
                                .pickerStyle(.menu)
                                .padding()
                                .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
                            }
                        }
                        Spacer()
                    }
                }
            }
        }
    }
    
    private func handleAuthentication() {
        validateEmail(email)
        validatePassword(password)
        
        if isEmailValid && isPasswordValid {
            if isRegistering {
                guard !firstName.isEmpty && !lastName.isEmpty else {
                    errorMessage = "Please enter your full name"
                    showAlert = true
                    return
                }
                
                guard password == confirmPassword else {
                    errorMessage = "Passwords do not match"
                    showAlert = true
                    return
                }
                
                AuthManager.shared.signUp(email: email, password: password) { error in
                    if let error = error {
                        errorMessage = error.localizedDescription
                        showAlert = true
                    } else {
                        if bypassEmails.contains(email.lowercased()) {
                            // Instantly "logged in" via AuthManager; ensure no verification UI
                            showVerificationSheet = false
                            verificationMessage = ""
                            errorMessage = ""
                            showAlert = false
                        } else {
                            showVerificationSheet = true
                            verificationMessage = "A verification email has been sent. Please check your inbox and verify your email before logging in."
                        }
                    }
                }
            } else {
                AuthManager.shared.signIn(email: email, password: password) { error in
                    if let error = error as NSError? {
                        switch error.code {
                        case AuthErrorCode.wrongPassword.rawValue:
                            errorMessage = "Incorrect password. Please try again."
                        case AuthErrorCode.userNotFound.rawValue:
                            errorMessage = "No account found with this email. Check for spelling errors, or sign up."
                        case AuthErrorCode.invalidEmail.rawValue:
                            errorMessage = "Invalid email format."
                        default:
                            errorMessage = error.localizedDescription
                        }
                        showAlert = true
                        if errorMessage.contains("verify your email") &&
                            !bypassEmails.contains(email.lowercased()) {
                            showVerificationSheet = true
                            verificationMessage = "Please verify your email before logging in."
                        }
                    } else {
                        // Successful sign-in
                        if bypassEmails.contains(email.lowercased()) {
                            // Skip any verification checks and UI
                            showVerificationSheet = false
                            verificationMessage = ""
                            isEmailVerified = true
                        } else {
                            AuthManager.shared.checkEmailVerified { verified in
                                DispatchQueue.main.async {
                                    isEmailVerified = verified
                                    if !verified {
                                        showVerificationSheet = true
                                        verificationMessage = "Please verify your email before logging in."
                                    }
                                }
                            }
                        }
                    }

                }
            }
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
        } else if email.hasSuffix("@sst.edu.sg") {
            isEmailValid = true
            errorMessage = ""
        } else {
            isEmailValid = false
            errorMessage = "Email must end with @s20XX.ssts.edu.sg OR @sst.edu.sg"
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
    
    private func checkEmailVerificationOnLaunch() {
        if let _ = Auth.auth().currentUser {
            // Skip verification prompt for bypass users
            if bypassEmails.contains(email.lowercased()) {
                showVerificationSheet = false
                isEmailVerified = true
                return
            }
            AuthManager.shared.checkEmailVerified { verified in
                DispatchQueue.main.async {
                    isEmailVerified = verified
                    if !verified && !bypassEmails.contains(email.lowercased()) {
                        showVerificationSheet = true
                        verificationMessage = "Please verify your email before logging in."
                    }
                }
            }
        }
    }
}

private struct GlassEffectIfAvailableRounded: ViewModifier {
    var cornerRadius: CGFloat
    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content.glassEffect(.regular.tint(.blue).interactive())
        } else {
            content.background(Color.blue).clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        }
    }
}

#Preview {
    LoginView()
}

