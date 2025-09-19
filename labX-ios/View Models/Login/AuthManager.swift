//
//  AuthManager.swift
//  labX-ios
//
//  Created by Avyan Mehra on 14/4/25.
//

import Foundation
import FirebaseAuth

class AuthManager: ObservableObject {
    static let shared = AuthManager()

    @Published var user: FirebaseAuth.User?
    @Published var isLoading: Bool = true
    @Published var authErrorMessage: String? = nil
    
    private let bypassEmails = [
        "iamastaff@sst.edu.sg",
        "avyan_mehra@s2023.ssts.edu.sg"
    ]

    private init() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.user = user
                self?.isLoading = false
            }
        }
    }
    
    private func extractErrorMessage(from error: Error) -> String {
        let errCode = AuthErrorCode(rawValue: (error as NSError).code)
        switch errCode {
        case .wrongPassword:
            return "Incorrect password. Please try again."
        case .userNotFound:
            return "No account found with this email."
        case .invalidEmail:
            return "Invalid email format."
        default:
            return error.localizedDescription
        }
    }

    func signIn(email: String, password: String, completion: @escaping (Error?) -> Void) {
        isLoading = true
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    self?.authErrorMessage = self?.extractErrorMessage(from: error)
                    self?.user = nil
                    completion(error)
                    return
                }

                guard let user = result?.user else {
                    completion(NSError(domain: "AuthManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "No user returned"]))
                    return
                }

                if !user.isEmailVerified && !(self?.bypassEmails.contains(email.lowercased()) ?? false) {
                    print("Email not verified for \(email)")
                    print(self?.bypassEmails.contains(email.lowercased()) ?? false)
                    self?.authErrorMessage = "Please verify your email before logging in."
                    self?.user = nil
                } else {
                    print("authorised login")
                    self?.authErrorMessage = nil
                    self?.user = user
                }
                completion(nil)
            }
        }
    }

    func signUp(email: String, password: String, completion: @escaping (Error?) -> Void) {
        isLoading = true
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            DispatchQueue.main.async {
                self?.isLoading = false

                guard let self = self else { return }
                guard let user = result?.user, error == nil else {
                    self.authErrorMessage = error?.localizedDescription
                    completion(error)
                    return
                }

                if self.bypassEmails.contains(email.lowercased()) {
                    // 🚀 Skip verification for bypass accounts
                    self.authErrorMessage = nil
                    self.user = user
                } else {
                    // Normal flow: send verification email
                    user.sendEmailVerification { err in
                        if let err = err {
                            print("Error sending verification email: \(err.localizedDescription)")
                        } else {
                            print("Verification email sent to \(email)")
                        }
                    }
                    self.authErrorMessage = "A verification email has been sent. Please verify your email before logging in."
                    self.user = nil
                }

                completion(error)
            }
        }
    }

    func forceBypassForCurrentUser() {
        guard let user = Auth.auth().currentUser else { return }
        user.reload { [weak self] _ in
            DispatchQueue.main.async {
                self?.user = user
                self?.authErrorMessage = nil
            }
        }
    }

    func resendVerificationEmail(completion: @escaping (Error?) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(NSError(domain: "AuthManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "No user signed in"]))
            return
        }
        user.sendEmailVerification { error in
            completion(error)
        }
    }

    func checkEmailVerified(completion: @escaping (Bool) -> Void) {
        Auth.auth().currentUser?.reload(completion: { error in
            if let user = Auth.auth().currentUser {
                completion(user.isEmailVerified)
                
            } else {
                completion(false)
            }
            
            if self.bypassEmails.contains(self.user?.email?.lowercased() ?? "") {
                completion(true)
            }
        })
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            self.user = nil
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
}
