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
        
        self.user = User(
            firstName: "",
            lastName: "",
            email: email,
            className: "",
            registerNumber: ""
        )

    }


}
