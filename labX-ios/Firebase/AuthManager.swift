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

    private init() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.user = user
        }
    }

    func signIn(email: String, password: String, completion: @escaping (Error?) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            self?.user = result?.user
            completion(error)
        }
    }

    func signUp(email: String, password: String, completion: @escaping (Error?) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            self?.user = result?.user
            completion(error)
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
