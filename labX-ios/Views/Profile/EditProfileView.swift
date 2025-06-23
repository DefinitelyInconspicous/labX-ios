//
//  EditProfileView.swift
//  labX-ios
//
//  Created by Avyan Mehra on 5/6/25.
//


import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct EditProfileView: View {
    @Environment(\.presentationMode) var presentationMode
    @State var user: User
    let onSave: (User, String) -> Void

    let classes = (1...4).flatMap { level in (1...10).map { "S\(level)-\($0 < 10 ? "0\($0)" : "\($0)")" } } + ["Staff"]
    let registerNumbers = (1...30).map { $0 < 10 ? "0\($0)" : "\($0)" } + ["Staff"]

    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Personal Info")) {
                    TextField("First Name", text: $user.firstName)
                    TextField("Last Name", text: $user.lastName)
                    TextField("Email", text: $user.email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }
                Section(header: Text("School Info")) {
                    Picker("Class", selection: $user.className) {
                        ForEach(classes, id: \.self) { Text($0) }
                    }
                    Picker("Register Number", selection: $user.registerNumber) {
                        ForEach(registerNumbers, id: \.self) { Text($0) }
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarItems(leading: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            }, trailing: Button("Save") {
                saveChanges()
            })
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Status"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }

    private func saveChanges() {
        guard !user.firstName.isEmpty, !user.lastName.isEmpty, !user.email.isEmpty else {
            alertMessage = "Please fill in all fields."
            showAlert = true
            return
        }
        guard let uid = Auth.auth().currentUser?.uid else {
            alertMessage = "User not logged in."
            showAlert = true
            return
        }
        let db = Firestore.firestore()
        let data: [String: Any] = [
            "firstName": user.firstName,
            "lastName": user.lastName,
            "email": user.email,
            "className": user.className,
            "registerNumber": user.registerNumber
        ]
        db.collection("users").document(uid).setData(data, merge: true) { error in
            if let error = error {
                alertMessage = "Failed to save: \(error.localizedDescription)"
                showAlert = true
            } else {
                onSave(user, "Changes saved successfully!")
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}