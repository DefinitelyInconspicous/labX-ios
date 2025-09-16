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
    @StateObject private var userManager = UserManager()
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
        NavigationStack {
            VStack(spacing: 0) {
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        
                        // MARK: - Post Card
                        VStack(alignment: .leading, spacing: 12) {
                            Text(post.title.isEmpty ? "Untitled" : post.title)
                                .font(.title2.bold())
                            
                            Text(post.topic)
                                .font(.caption.bold())
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue, in: RoundedRectangle(cornerRadius: 6))
                            
                            if let base64 = post.imageBase64,
                               let data = Data(base64Encoded: base64),
                               let uiImage = UIImage(data: data) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxHeight: 220)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            
                            Text(post.content)
                                .font(.body)
                            
                            HStack {
                                Text("By \(post.author) • \(post.level)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                VoteView(voteCount: $currentVoteCount,
                                         userVote: $userVote,
                                         onVote: vote)
                            }
                        }
                        .padding()
                        .background(.gray.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                        
                        
                        
                        
                        
                        // MARK: - Comments
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Comments")
                                .font(.headline)
                            
                            if forumManager.comments.isEmpty {
                                Text("No comments yet. Be the first to comment!")
                                    .foregroundStyle(.secondary)
                                    .font(.callout)
                            } else {
                                VStack(spacing: 8) {
                                    ForEach(forumManager.comments) { comment in
                                        ForumCommentView(comment: comment,
                                                         forumManager: forumManager,
                                                         userManager: userManager)
                                    }
                                }
                            }
                            // MARK: - Comment Input
                            if let _ = user {
                                HStack(spacing: 8) {
                                    TextField("Write a comment...", text: $newComment)
                                        .textFieldStyle(.roundedBorder)
                                    
                                    Button("Post") {
                                        postComment()
                                        forumManager.fetchComments(for: post.id)
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .disabled(newComment.trimmingCharacters(in: .whitespaces).isEmpty)
                                }
                            } else {
                                Text("Log in to comment.")
                                    .foregroundStyle(.red)
                                    .font(.caption)
                                    .padding()
                            }
                        }
                    }
                    .padding()
                }
                
                
                
            }
            .navigationTitle("Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            reportComment(commentID: post.id)
                        } label: {
                            Image(systemName: "flag.fill")
                                .foregroundStyle(.red)
                        }
                    }
                if let user = user, user.email == post.authorEmail {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(role: .destructive) {
                            showAlert = true
                            alertMessage = "Are you sure you want to delete this post? This action cannot be undone."
                        } label: {
                            Label("Delete Post", systemImage: "trash")
                                .frame(maxWidth: .infinity)
                                .foregroundStyle(.red)
                        }
                    }
                }
            }
            .sheet(isPresented: $showReportView) {
                ForumReportView(reason: $reportMessage,
                                postID: .constant(post.id),
                                submitReport: $submitReport)
            }
            .onAppear {
                forumManager.fetchComments(for: post.id)
                currentVoteCount = post.vote
                userVote = forumManager.getUserVote(for: post.id)
            }
            .alert(isPresented: $showAlert) {
                makeAlert()
            }
        }
    }
    private func makeAlert() -> Alert {
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
                                if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                                   let root = scene.windows.first?.rootViewController {
                                    root.dismiss(animated: true)
                                }
                            }
                        } else {
                            alertMessage = "Failed to delete post."
                        }
                    }
                },
                secondaryButton: .cancel()
            )
        } else {
            return Alert(title: Text("Notice"),
                         message: Text(alertMessage),
                         dismissButton: .default(Text("OK")))
        }
    }
    
    struct VoteView: View {
        @Binding var voteCount: Int
        @Binding var userVote: Int
        var onVote: (Int) -> Void
        
        var body: some View {
            HStack(spacing: 6) {
                Button { onVote(1) } label: {
                    Image(systemName: "arrow.up")
                        .foregroundColor(userVote == 1 ? .green : .secondary)
                }
                Text("\(voteCount)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
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
        forumManager.createComment(postID: post.id, author: authorName, authorEmail: user.email, comment: newComment) { success in
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
