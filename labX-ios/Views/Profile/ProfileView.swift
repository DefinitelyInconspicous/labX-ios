//
//  ProfileView.swift
//  labX-ios
//
//  Created by Avyan Mehra on 14/4/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import Forever

struct ProfileView: View {
    @State var user: User
    @Forever("isLoggedIn") var isLoggedIn: Bool = true
    @State  var showEditSheet = false
    @State  var showAlert = false
    @State  var alertMessage = ""
    
    var body: some View {
        NavigationStack {
            HStack {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.blue)
                    .padding()
                Spacer()
            }
            
            Form {
                Section(header: Text("Personal Info")) {
                    LabeledContent {
                        Text(user.firstName)
                    } label: {
                        Text("First Name")
                    }
                    LabeledContent {
                        Text(user.lastName)
                    } label: {
                        Text("Last Name")
                    }
                    LabeledContent {
                        Text(user.email)
                    } label: {
                        Text("Email")
                    }
                }
                
                if user.className != "Staff" {
                    Section(header: Text("School Info")) {
                        LabeledContent {
                            Text(user.className)
                        } label: {
                            Text("Class")
                        }
                        LabeledContent {
                            Text(user.registerNumber)
                        } label: {
                            Text("Register Number")
                        }
                    }
                }
                Button(role: .destructive) {
                    logout()
                } label: {
                    Text("Log Out")
                }
            }
        }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showEditSheet = true
                    }) {
                        Image(systemName: "pencil")
                    }
                }
        
        }
        .sheet(isPresented: $showEditSheet) {
            EditProfileView(user: user) { updatedUser, message in
                self.user = updatedUser
                self.alertMessage = message
                self.showAlert = true
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Status"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        .onAppear {
            loadUserData()
        }
    }
    
    func logout() {
        do {
            try Auth.auth().signOut()
            isLoggedIn = false
        } catch {
            alertMessage = "Error signing out: \(error.localizedDescription)"
            showAlert = true
        }
    }
    
    func loadUserData() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("users").document(uid).getDocument { snapshot, error in
            if let data = snapshot?.data() {
                if let firstName = data["firstName"] as? String,
                   let lastName = data["lastName"] as? String,
                   let email = data["email"] as? String,
                   let className = data["className"] as? String,
                   let registerNumber = data["registerNumber"] as? String {
                    user = User(id: uid, firstName: firstName, lastName: lastName, email: email, className: className, registerNumber: registerNumber)
                }
            }
        }
    }
}
