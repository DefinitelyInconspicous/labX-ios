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
    
    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(comment.author)
                    .font(.caption)
                    .foregroundColor(.blue)
                Text(comment.comment)
                    .font(.body)
            }
            Spacer()
            VStack {
                Button(action: {
                    guard let _ = user, !isVoting else { return }
                    isVoting = true
                    forumManager.voteComment(commentID: comment.id, delta: 1)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        forumManager.fetchComments(for: comment.postID)
                        isVoting = false
                    }
                }) {
                    Image(systemName: "arrow.up")
                        .foregroundColor(user == nil ? .gray : .blue)
                }
                .disabled(user == nil || isVoting)
                Button(action: {
                    guard let _ = user, !isVoting else { return }
                    isVoting = true
                    forumManager.voteComment(commentID: comment.id, delta: -1)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        forumManager.fetchComments(for: comment.postID)
                        isVoting = false
                    }
                }) {
                    Image(systemName: "arrow.down")
                        .foregroundColor(user == nil ? .gray : .blue)
                }
                .disabled(user == nil || isVoting)
                Text("\(comment.vote)")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 4)
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }
}

#Preview {
    ForumCommentView(comment: ForumComment(id: "1", postID: "1", author: "StudentB", comment: "Great explanation!", vote: 3), forumManager: ForumManager(), user: User(id: "1", firstName: "John", lastName: "Doe", email: "john_doe@s2023.ssts.edu.sg", className: "S1-01", registerNumber: "1"))
}
