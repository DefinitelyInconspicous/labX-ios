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
                    
                    VStack(spacing: 16) {
                        if isRegistering {
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("First Name")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    TextField("First Name", text: $firstName)
                                        .textContentType(.givenName)
                                        .padding()
                                        .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
                                }
                                
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Last Name")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    TextField("Last Name", text: $lastName)
                                        .textContentType(.familyName)
                                        .padding()
                                        .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
                                }
                            }
                        }
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Email")
                                .font(.caption)
                                .foregroundColor(.gray)
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
                            SecureField("Password", text: $password)
                                .textContentType(.password)
                                .padding()
                                .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
                                .onChange(of: password) { _ in
                                    validatePassword(password)
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
                                SecureField("Confirm Password", text: $confirmPassword)
                                    .textContentType(.password)
                                    .padding()
                                    .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
                            }
                            
                            if !isStaffSignup {
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
                    .padding(.horizontal)
                    
                    VStack(spacing: 16) {
                        
                        Button {
                            handleAuthentication()
                        } label: {
                            Text(isRegistering ? "Sign Up" : "Log In")
                                .bold()
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        
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
//                        // Google Sign-In Button
//                        Button {
//                            signInWithGoogle()
//                        } label: {
//                            HStack {
//                                Image(systemName: "globe")
//                                    .foregroundColor(.white)
//                                Text("Sign in with Google")
//                                    .bold()
//                                    .foregroundColor(.white)
//                            }
//                            .frame(maxWidth: .infinity)
//                            .padding()
//                            .background(Color.red)
//                            .cornerRadius(10)
//                        }
//                        .padding(.top, 8)
                    }
                    .padding(.horizontal)
                }
            }
            .onChange(of: auth.authErrorMessage) { newMessage in
                if let newMessage = newMessage {
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
    
    private func handleAuthentication() {
        print("Handling auth")
        // Validate email and password
        validateEmail(email)
        validatePassword(password)
        
        guard isEmailValid && isPasswordValid else {
            showAlert = true // Show error alert if validation fails
            return
        }
        
        let emailLowercased = email.lowercased()
        
        // If email is in bypass list, skip verification entirely
        let isBypassEmail = bypassEmails.contains(emailLowercased)
        
        if isRegistering {
            // Registration flow
            print("isregistering")
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
                print("Signed up callback")
                DispatchQueue.main.async {
                    if let error = error {
                        errorMessage = error.localizedDescription
                        print("Error during signup: \(error.localizedDescription)")
                        showAlert = true
                    } else {
                        print("checking email")
                        if isBypassEmail {
                            // Skip verification for bypass emails
                            print("bypass email detected")
                            isEmailVerified = true
                            showVerificationSheet = false
                               return
                        } else {
                            // Normal verification
                            print("normal email detected")
                            showVerificationSheet = true
                            verificationMessage = "A verification email has been sent. Please check your inbox and verify your email before logging in."
                        }
                    }
                }
            }
            
        } else {
            // Login flow
            AuthManager.shared.signIn(email: email, password: password) { error in
                DispatchQueue.main.async {
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
                        return
                    }
                    
                    // If login succeeds
                    if isBypassEmail {
                        isEmailVerified = true
                        showVerificationSheet = false
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
        if let currentUser = Auth.auth().currentUser {
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
    
    private func signInWithGoogle() {
        guard let rootVC = UIApplication.shared.connectedScenes
            .compactMap({ ($0 as? UIWindowScene)?.keyWindow?.rootViewController })
            .first else {
            errorMessage = "Unable to get root view controller."
            showAlert = true
            return
        }
        AuthManager.shared.signInWithGoogle(presentingViewController: rootVC) { error in
            if let error = error {
                errorMessage = error.localizedDescription
                showAlert = true
            }
        }
    }
}
