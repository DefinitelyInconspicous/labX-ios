//
//  UserManager.swift
//  labX-ios
//
//  Created by Avyan Mehra on 14/4/25.
//


import FirebaseAuth
import FirebaseFirestore

class UserManager: ObservableObject {
    @Published var user: User?

    func fetchUser() {
        guard let currentUser = Auth.auth().currentUser else { return }

        let email = currentUser.email ?? ""
        let level = user
        
        self.user = User(
            firstName: "Avyan",
            lastName: "Mehra",
            email: email,
            className: "S3-01",
            registerNumber: "05"
        )

    }


}
