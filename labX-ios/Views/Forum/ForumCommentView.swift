//
//  ForumCommentView.swift
//  labX-ios
//
//  Created by Avyan Mehra on 3/9/25.
//

import SwiftUI

struct ForumCommentView: View {
    let comment: ForumComment
    @ObservedObject var forumManager: ForumManager
    let user: User?
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isVoting = false
    @State private var localUserVote: Int = 0
    @State private var currentVoteCount: Int = 0

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Left: Author + Comment content
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
            // Right: Voting section
            VStack(spacing: 4) {
                Button(action: {
                    guard let _ = user, !isVoting else { return }
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
                        .foregroundColor(user == nil ? .gray : (localUserVote == 1 ? .green : .gray))
                }
                .disabled(user == nil || isVoting)
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
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        .onAppear {
            localUserVote = forumManager.getUserVoteForComment(comment.id)
            currentVoteCount = comment.vote
        }
        .onChange(of: forumManager.commentUserVotes[comment.id]) { newVote in
            localUserVote = newVote ?? 0
        }
        .onChange(of: comment.vote) { newVote in
            currentVoteCount = newVote
        }
    }
}

#Preview {
    ForumCommentView(
        comment: ForumComment(
            id: "1",
            postID: "1",
            author: "StudentB",
            comment: "Great explanation!",
            vote: 3
        ),
        forumManager: ForumManager(),
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
