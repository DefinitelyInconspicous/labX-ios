//
//  ForumCommentView.swift
//  labX-ios
//
//  Created by Avyan Mehra on 3/9/25.
//

import SwiftUI
import FirebaseFirestore

extension UserManager {
    func fetchUser(byEmail email: String, completion: @escaping (User?) -> Void) {
        let db = Firestore.firestore()
        db.collection("users").whereField("email", isEqualTo: email).getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching user by email: \(error)")
                completion(nil)
                return
            }
            if let doc = snapshot?.documents.first {
                let data = doc.data()
                let user = User(
                    id: doc.documentID,
                    firstName: data["firstName"] as? String ?? "",
                    lastName: data["lastName"] as? String ?? "",
                    email: data["email"] as? String ?? "",
                    className: data["className"] as? String ?? "",
                    registerNumber: data["registerNumber"] as? String ?? "",
                    profilePicture: data["profilePicture"] as? String
                )
                completion(user)
            } else {
                completion(nil)
            }
        }
    }
}

struct ForumCommentView: View {
    let comment: ForumComment
    @ObservedObject var forumManager: ForumManager
    @ObservedObject var userManager: UserManager
    @State private var authorUser: User? = nil

    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isVoting = false
    @State private var localUserVote: Int = 0
    @State private var currentVoteCount: Int = 0

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Left: Author profile pic
            if let base64 = authorUser?.profilePicture,
               !base64.isEmpty,
               let data = Data(base64Encoded: base64),
               let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 36, height: 36)
                    .clipShape(Circle())
                    .onAppear {
                        print("profile pic found")
                    }
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 36, height: 36)
                    .foregroundColor(.gray)
                    .onAppear {
                        print("no profile pic found")
                    }
            }

            // Middle: Author + Comment
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(comment.author)
                        .font(.caption)
                        .foregroundColor(.blue)
                    Spacer()
                }
                Text(comment.comment)
                    .font(.body)
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            // Right: Voting
            VStack(spacing: 4) {
                Button(action: {
                    guard userManager.user != nil, !isVoting else { return }
                    isVoting = true
                    if localUserVote == 1 {
                        currentVoteCount -= 1
                        forumManager.voteComment(commentID: comment.id, delta: 0)
                        localUserVote = 0
                    } else {
                        currentVoteCount += 1 - localUserVote
                        forumManager.voteComment(commentID: comment.id, delta: 1)
                        localUserVote = 1
                    }
                    isVoting = false
                }) {
                    Image(systemName: "arrow.up")
                        .foregroundColor(userManager.user == nil ? .gray : (localUserVote == 1 ? .green : .gray))
                }
                .disabled(userManager.user == nil || isVoting)

                Text("\(currentVoteCount)")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 4)
        }
        .padding()
        .background(.gray.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        .onAppear {
            // Fetch author profile
            userManager.fetchUser(byEmail: comment.authorEmail) { fetched in
                self.authorUser = fetched
            }

            localUserVote = forumManager.getUserVoteForComment(comment.id)
            currentVoteCount = comment.vote
        }
        .onChange(of: forumManager.commentUserVotes[comment.id]) { _, newVote in
            localUserVote = newVote ?? 0
        }
        .onChange(of: comment.vote) { _, newVote in
            currentVoteCount = newVote
        }
    }
}
