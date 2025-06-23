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
        let db = Firestore.firestore()
        
        // Check if user exists in Firestore
        db.collection("users").document(currentUser.uid).getDocument { [weak self] document, error in
            if let document = document, document.exists {
                // User exists, fetch their data
                let data = document.data()
                self?.user = User(
                    id: currentUser.uid,
                    firstName: data?["firstName"] as? String ?? "",
                    lastName: data?["lastName"] as? String ?? "",
                    email: email,
                    className: data?["className"] as? String ?? "",
                    registerNumber: data?["registerNumber"] as? String ?? ""
                )
            } else {
                // New user, create their document
                let isStaff = email.hasSuffix("@sst.edu.sg") || email == "amspy2468@gmail.com"
                let userData: [String: Any] = [
                    "firstName": "",
                    "lastName": "",
                    "email": email,
                    "className": isStaff ? "Staff" : "",
                    "registerNumber": isStaff ? "Staff" : ""
                ]
                
                db.collection("users").document(currentUser.uid).setData(userData) { error in
                    if let error = error {
                        print("Error creating user document: \(error.localizedDescription)")
                    } else {
                        self?.user = User(
                            id: currentUser.uid,
                            firstName: "",
                            lastName: "",
                            email: email,
                            className: isStaff ? "Staff" : "",
                            registerNumber: isStaff ? "Staff" : ""
                        )
                    }
                }
            }
        }
    }


}


