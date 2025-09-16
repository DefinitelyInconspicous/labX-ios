//
//  EditProfileView.swift
//  labX-ios
//
//  Created by Avyan Mehra on 5/6/25.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import PhotosUI

struct EditProfileView: View {
    @Environment(\.presentationMode) var presentationMode
    @State var user: User
    let onSave: (User, String) -> Void

    let classes = (1...4).flatMap { level in (1...10).map { "S\(level)-\($0 < 10 ? "0\($0)" : "\($0)")" } }
    let registerNumbers = (1...30).map { $0 < 10 ? "0\($0)" : "\($0)" }

    @State private var showAlert = false
    @State private var alertMessage = ""
    
    // Profile picture
    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var profileImage: UIImage? = nil
    @State private var profileBase64: String? = nil

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Profile Picture").font(.headline)) {
                    VStack {
                        if let image = profileImage {
                            // Display picked/new profile image
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.gray, lineWidth: 1))
                                .padding(.bottom, 8)

                            Button("Remove Photo") {
                                profileImage = nil
                                profileBase64 = nil
                            }
                            .foregroundColor(.red)

                        } else if let base64 = user.profilePicture,
                                  let data = Data(base64Encoded: base64),
                                  let uiImage = UIImage(data: data) {
                            // Display current saved profile picture
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.gray, lineWidth: 1))
                                .padding(.bottom, 8)

                            Button("Remove Photo") {
                                user.profilePicture = nil
                                profileImage = nil
                                profileBase64 = nil
                            }
                            .foregroundColor(.red)

                        } else {
                            // Default placeholder
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 120, height: 120)
                                .overlay(Image(systemName: "person.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.gray))
                                .padding(.bottom, 8)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    
                        PhotosPicker("Choose Photo", selection: $selectedPhoto, matching: .images)
                            .onChange(of: selectedPhoto) { newItem in
                                Task {
                                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                                       let uiImage = UIImage(data: data) {
                                        if let compressedData = compressImage(uiImage) {
                                            profileImage = uiImage
                                            profileBase64 = compressedData.base64EncodedString()
                                        } else {
                                            alertMessage = "Image compression failed. Try another photo."
                                            showAlert = true
                                        }
                                    }
                                }
                            }

                }

                Section(header: Text("Personal Info").font(.headline)) {
                    HStack {
                        Text("First Name")
                        Spacer()
                        TextField("First Name", text: $user.firstName)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 200)
                    }

                    HStack {
                        Text("Last Name")
                        Spacer()
                        TextField("Last Name", text: $user.lastName)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 200)
                    }

                    HStack {
                        Text("Email")
                        Spacer()
                        TextField("Email", text: $user.email)
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .autocapitalization(.none)
                            .autocorrectionDisabled(true)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 250)
                    }
                }

                if user.className != "Staff" {
                    Section(header: Text("School Info")) {
                        Picker("Class", selection: $user.className) {
                            ForEach(classes, id: \.self) { Text($0) }
                        }
                        Picker("Register Number", selection: $user.registerNumber) {
                            ForEach(registerNumbers, id: \.self) { Text($0) }
                        }
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

    private func compressImage(_ image: UIImage) -> Data? {
        var quality: CGFloat = 0.9
        let maxSize = 500_000
        var compressedData = image.jpegData(compressionQuality: quality)
        
        while let data = compressedData, data.count > maxSize, quality > 0.1 {
            quality -= 0.1
            compressedData = image.jpegData(compressionQuality: quality)
        }
        
        return compressedData
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
        var data: [String: Any] = [
            "firstName": user.firstName,
            "lastName": user.lastName,
            "email": user.email,
            "className": user.className,
            "registerNumber": user.registerNumber
        ]
        
        if let profileBase64 = profileBase64 {
            data["profilePicture"] = profileBase64
            user.profilePicture = profileBase64
        } else if user.profilePicture == nil {
            // Explicitly remove profile picture if deleted
            data["profilePicture"] = FieldValue.delete()
        }
        
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
