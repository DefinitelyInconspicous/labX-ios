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
    @State var showEditSheet = false
    @State var showAlert = false
    @State var alertMessage = ""
    @State var showCredits = false
    @State private var resetPasswordSheetShowing = false
    @State private var showDeleteConfirm = false
    @State private var isUnderMaintenance = false
    @StateObject private var auth = AuthManager.shared
    
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
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    } label: {
                        Text("First Name")
                    }
                    LabeledContent {
                        Text(user.lastName)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    } label: {
                        Text("Last Name")
                    }
                    LabeledContent {
                        Text(user.email)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    } label: {
                        Text("Email")
                    }
                }
                
                if user.className != "Staff" {
                    Section(header: Text("School Info")) {
                        LabeledContent {
                            Text(user.className)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        } label: {
                            Text("Class")
                        }
                        LabeledContent {
                            Text(user.registerNumber)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        } label: {
                            Text("Register Number")
                        }
                    }
                }
                if auth.user?.email == "avyan_mehra@s2023.ssts.edu.sg" {
                Section("Dev Options") {
                    Button {
                        unlockApp()
                    } label: {
                        Text("Unlock App for Everyone")
                            .padding()
                            .foregroundColor(.white)
                            .background(Color.blue)
                            .cornerRadius(10)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    Button(role: .destructive) {
                        lockApp()
                    } label: {
                        Text("Lock App for Everyone")
                            .padding()
                            .foregroundColor(.white)
                            .background(Color.blue)
                            .cornerRadius(10)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                }
                }
                Section {
                    
                    Button {
                        resetPasswordSheetShowing = true
                    } label: {
                        Text("Forgot Password?")
                            .foregroundStyle(.blue)
                    }
                    .sheet(isPresented: $resetPasswordSheetShowing) {
                        ForgotPassword()
                    }
                    
                    
                    Button {
                        logout()
                    } label: {
                        Text("Log Out")
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                }
                
                Section {
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Text("Delete Account")
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                }
            }
        
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showEditSheet = true
                    } label: {
                        Image(systemName: "pencil")
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showCredits = true
                    } label: {
                        Image(systemName: "person.2.fill")
                    }
                    
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
        .sheet(isPresented: $showCredits ) {
            Credits()
        }
        
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Status"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        .alert("Delete Account?",
               isPresented: $showDeleteConfirm,
               actions: {
                   Button("Cancel", role: .cancel) { }
                   Button("Delete", role: .destructive) {
                       Task {
                           await DeleteAccount(docID: user.id)
                       }
                   }
               },
               message: {
                   Text("This action cannot be undone. Are you sure you want to delete your account?")
               })
        .onAppear {
            loadUserData()
        }
    }
    
    func DeleteAccount(docID: String) async {
        let db = Firestore.firestore()
        let curuser = Auth.auth().currentUser
        
        do {
            try await db.collection("users").document(docID).delete()
            print("Document successfully removed!")
            alertMessage = "Account Deleted Successfully"
            showAlert = true
        } catch {
            print("Error removing document: \(error)")
            alertMessage = "Error Deleting Account: \(error.localizedDescription)"
            showAlert = true
        }
        curuser?.delete { error in
            if let error = error {
                print("Error deleting user: \(error.localizedDescription)")
                alertMessage = "Error Deleting Account: \(error.localizedDescription)"
                showAlert = true
            } else {
                print("User account deleted successfully")
                isLoggedIn = false
            }
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
    
    func unlockApp() {
        let db = Firestore.firestore()
        db.collection("settings").document("maintanence").setData(["status": false], merge: true) { error in
            if let error = error {
                print("Failed to update status: \(error.localizedDescription)")
                alertMessage = "Failed to update status: \(error.localizedDescription)"
                showAlert = true
            } else {
                print("Maintenance mode disabled by admin")
                alertMessage = "Maintenance mode disabled by admin"
                showAlert = true
            }
        }
    }
    
    func lockApp() {
        let db = Firestore.firestore()
        db.collection("settings").document("maintanence").setData(["status": true], merge: true) { error in
            if let error = error {
                print("Failed to update status: \(error.localizedDescription)")
                alertMessage = "Failed to update status: \(error.localizedDescription)"
                showAlert = true
            } else {
                print("Maintanence Mode Enabled")
                alertMessage = "Maintanence Mode Enabled"
                showAlert = true
            }
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

#Preview {
    ProfileView(user: User(id: "1", firstName: "John", lastName: "Doe", email: "john_doe@s2023.ssts.edu.sg", className: "S1-01", registerNumber: "1"))
}
