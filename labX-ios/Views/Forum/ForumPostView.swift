//
//  ForumPostView.swift
//  labX-ios
//
//  Created by Avyan Mehra on 3/9/25.
//

import SwiftUI
import FirebaseFirestore

struct ForumPostView: View {
    let post: ForumPost
    let user: User?
    @StateObject private var forumManager = ForumManager()
    @State private var newComment = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var showReportView = false
    @State var reportMessage = ""
    @State var submitReport = false
    
    // Track the current user's vote for this post
    @State private var userVote: Int = 0
    @State private var currentVoteCount: Int = 0
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 20) {
                    // Post Card
                    HStack(alignment: .top, spacing: 16) {
                        // Votes Column
                        VStack(spacing: 8) {
                            Button {
                                vote(delta: 1)
                            } label: {
                                Image(systemName: "arrow.up")
                                    .font(.headline)
                                    .foregroundColor(userVote == 1 ? .green : .gray)
                            }
                            
                            Text("\(currentVoteCount)")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .fontWeight(.semibold)
                            
                            Button {
                                vote(delta: -1)
                            } label: {
                                Image(systemName: "arrow.down")
                                    .font(.headline)
                                    .foregroundColor(userVote == -1 ? .red : .gray)
                            }
                        }
                        // Post Content
                        VStack(alignment: .leading, spacing: 8) {
                            Text(post.title.isEmpty ? "Untitled" : post.title)
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                                .fixedSize(horizontal: false, vertical: true)
                            Text(post.topic)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                                .fixedSize(horizontal: false, vertical: true)
                            if let base64 = post.imageBase64, let imageData = Data(base64Encoded: base64), let uiImage = UIImage(data: imageData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxHeight: 220)
                                    .cornerRadius(12)
                                    .padding(.vertical, 8)
                            }
                            Text(post.content)
                                .font(.body)
                                .fixedSize(horizontal: false, vertical: true)
                            HStack {
                                Text("By \(post.author)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(post.level)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        Button {
                            reportComment(commentID: post.id)
                        } label: {
                            Image(systemName: "flag")
                                .foregroundColor(.red)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color(.systemGray6))
                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    )
                    if let user = user, user.email == post.authorEmail {
                        Button(role: .destructive) {
                            showAlert = true
                            alertMessage = "Are you sure you want to delete this post? This action cannot be undone."
                            
                        } label: {
                            Label("Delete Post", systemImage: "trash")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .padding(.vertical, 8)
                    }
                    // Comments Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Comments")
                            .font(.headline)
                        
                        if forumManager.comments.isEmpty {
                            Text("No comments yet. Be the first to comment!")
                                .foregroundColor(.secondary)
                                .font(.callout)
                                .padding(.vertical, 8)
                        } else {
                            VStack(spacing: 10) {
                                ForEach(forumManager.comments) { comment in
                                    ForumCommentView(comment: comment, forumManager: forumManager, user: user)
                                        .padding()
                                        .background(Color(.systemGray6))
                                        .cornerRadius(12)
                                        .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 1)
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            
            // Comment Input
            if let _ = user {
                HStack(spacing: 10) {
                    TextField("Write a comment...", text: $newComment)
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    
                    Button {
                        postComment()
                        forumManager.fetchComments(for: post.id)
                    } label: {
                        Text("Post")
                            .fontWeight(.semibold)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 18)
                            .background(newComment.trimmingCharacters(in: .whitespaces).isEmpty ? Color.gray.opacity(0.3) : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .disabled(newComment.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding([.horizontal, .bottom])
            } else {
                Text("Log in to comment.")
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding()
            }
        }
        .navigationTitle("Post Details")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showReportView) {
            ForumReportView(reason: $reportMessage, postID: .constant(post.id), submitReport: $submitReport)
        }
        .onAppear {
            forumManager.fetchComments(for: post.id)
            currentVoteCount = post.vote
            userVote = forumManager.getUserVote(for: post.id)
        }
        .onChange(of: submitReport) { newValue in
            if newValue {
                let db = Firestore.firestore()
                db.collection("reportedComments").addDocument(data: [
                    "commentID": post.id,
                    "postID": post.id,
                    "reason": reportMessage,
                    "reportedAt": Timestamp(date: Date()),
                    "reporter": user?.email ?? "Unknown"
                ]) { error in
                    if let error = error {
                        alertMessage = "Failed to report: \(error.localizedDescription)"
                    } else {
                        alertMessage = "Comment reported successfully."
                    }
                    showAlert = true
                    showReportView = false
                    submitReport = false
                    reportMessage = ""
                }
            }
        }

        .alert(isPresented: $showAlert) {
            if alertMessage.contains("delete this post") {
                return Alert(
                    title: Text("Delete Post"),
                    message: Text(alertMessage),
                    primaryButton: .destructive(Text("Delete")) {
                        forumManager.deletePost(postID: post.id) { success in
                            if success {
                                alertMessage = "Post deleted successfully."
                                forumManager.fetchPosts()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                                       let rootVC = windowScene.windows.first?.rootViewController {
                                        rootVC.dismiss(animated: true)
                                    }
                                }
                            } else {
                                alertMessage = "Failed to delete post."
                            }
                        }
                    },
                    secondaryButton: .cancel()
                )
            } else if alertMessage.contains("reported successfully") || alertMessage.contains("This comment has already been reported.") {
                return Alert(title: Text("Report"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            } else {
                return Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }
    
    private func vote(delta: Int) {
        guard let _ = user else { return }
        
        if userVote == delta {
            currentVoteCount -= delta
            userVote = 0
            forumManager.votePost(postID: post.id, delta: 0)
        } else {
            currentVoteCount += delta - userVote
            userVote = delta
            forumManager.votePost(postID: post.id, delta: delta)
        }
    }
    
    private func postComment() {
        guard let user = user else { return }
        let authorName = "\(user.firstName) \(user.lastName)"
        forumManager.createComment(postID: post.id, author: authorName, comment: newComment) { success in
            if success {
                newComment = ""
                forumManager.fetchComments(for: post.id)
            } else {
                alertMessage = "Failed to post comment: \(forumManager.errorMessage ?? "Unknown error")"
                showAlert = true
            }
        }
    }
private func reportComment(commentID: String) {
        let db = Firestore.firestore()
        
        db.collection("reportedComments")
            .whereField("commentID", isEqualTo: commentID)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error checking reported comments: \(error.localizedDescription)")
                    return
                }
                
                if let documents = snapshot?.documents, !documents.isEmpty {
                    alertMessage = "This comment has already been reported."
                    showAlert = true
                } else {
                    // Open the sheet
                    showReportView = true
                }
            }
    }


    
}



#Preview {
    ForumPostView(
        post: ForumPost(
            id: "1",
            title: "Quantum Entanglement",
            topic: "Physics",
            content: "What is quantum entanglement?",
            level: "S3",
            author: "StudentA",
            authorEmail: "studentA@s20xx.ssts.edu.sg",
            vote: 5
        ),
        user: User(
            id: "1",
            firstName: "John",
            lastName: "Doe",
            email: "john_doe@s2023.ssts.edu.sg",
            className: "S1-01",
            registerNumber: "1"
        )
    )
}
