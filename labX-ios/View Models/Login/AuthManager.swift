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

    private init() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.user = user
                self?.isLoading = false
            }
        }
    }

    func signIn(email: String, password: String, completion: @escaping (Error?) -> Void) {
        isLoading = true
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            DispatchQueue.main.async {
                self?.user = result?.user
                self?.isLoading = false
                completion(error)
            }
        }
    }

    func signUp(email: String, password: String, completion: @escaping (Error?) -> Void) {
        isLoading = true
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            DispatchQueue.main.async {
                self?.user = result?.user
                self?.isLoading = false
                completion(error)
            }
        }
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
