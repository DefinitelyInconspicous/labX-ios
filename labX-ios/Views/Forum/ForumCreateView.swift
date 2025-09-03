//
//  ForumCreateView.swift
//  labX-ios
//
//  Created by Avyan Mehra on 3/9/25.
//

import SwiftUI
import PhotosUI

struct ForumCreateView: View {
    @ObservedObject var forumManager: ForumManager
    @Environment(\.dismiss) var dismiss
    @State private var topic = "Physics"
    @State private var content = ""
    @State private var level = "S1"
    @StateObject private var auth = AuthManager.shared
    @State var user: User
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var selectedImage: UIImage? = nil
    @State private var imageBase64: String? = nil
    @State private var showImagePicker = false
    @State private var selectedPickerItem: PhotosPickerItem? = nil
    let topics = ["Physics", "Chemistry", "Biology"]
    let levels = ["S1", "S2", "S3", "S4"]
    
    var body: some View {
        NavigationStack {
            Form {
                Picker("Topic", selection: $topic) {
                    ForEach(topics, id: \.self) { Text($0) }
                }
                    
                TextField("Content", text: $content, axis: .vertical)
                    .lineLimit(3...6)
                Picker("Level", selection: $level) {
                    ForEach(levels, id: \.self) { Text($0) }
                }
                LabeledContent("Author", value: user.firstName + " " + user.lastName)
                Section(header: Text("Image (optional)")) {
                    if let selectedImage = selectedImage {
                        VStack {
                            Image(uiImage: selectedImage)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 180)
                                .cornerRadius(12)
                            Button("Remove Image") {
                                self.selectedImage = nil
                                self.imageBase64 = nil
                                self.selectedPickerItem = nil
                            }
                            .foregroundColor(.red)
                        }
                    } else {
                        PhotosPicker(selection: $selectedPickerItem, matching: .images, photoLibrary: .shared()) {
                            Text("Add Image")
                        }
                    }
                }
            }
            .navigationTitle("Create Post")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Post") {
                        guard !content.trimmingCharacters(in: .whitespaces).isEmpty else {
                            alertMessage = "Please fill in all fields."
                            showAlert = true
                            return
                        }
                        forumManager.createPost(
                            topic: topic,
                            content: content,
                            level: level,
                            author: user.firstName + " " + user.lastName,
                            authorEmail: user.email, // Pass email
                            imageBase64: imageBase64
                        ) { success in
                            if success {
                                dismiss()
                            } else {
                                alertMessage = "Failed to create post."
                                showAlert = true
                            }
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
            .onChange(of: selectedPickerItem) { _, newItem in
                guard let item = newItem else { return }
                item.loadTransferable(type: Data.self) { result in
                    switch result {
                    case .success(let data):
                        if let data = data, let image = UIImage(data: data) {
                            let resized = resizedImage(image, maxDimension: 800)
                            self.selectedImage = resized
                            // Compress to lower quality to fit Firestore limit
                            if let compressedData = resized.jpegData(compressionQuality: 0.4) {
                                self.imageBase64 = compressedData.base64EncodedString()
                            } else {
                                self.imageBase64 = nil
                            }
                        }
                    case .failure:
                        break
                    }
                }
            }
        }
    }
    
    private func resizedImage(_ image: UIImage, maxDimension: CGFloat = 800) -> UIImage {
        let size = image.size
        let aspectRatio = size.width / size.height
        var newSize: CGSize
        if aspectRatio > 1 {
            newSize = CGSize(width: maxDimension, height: maxDimension / aspectRatio)
        } else {
            newSize = CGSize(width: maxDimension * aspectRatio, height: maxDimension)
        }
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resized = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resized ?? image
    }
}

#Preview {
    ForumCreateView(forumManager: ForumManager(), user: User(id: "1", firstName: "John", lastName: "Doe", email: "john_doe@s2023.ssts.edu.sg", className: "S1-01", registerNumber: "1"))
}
