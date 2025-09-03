//
//  ForumManager.swift
//  labX-ios
//
//  Created by Avyan Mehra on 3/9/25.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

struct ForumPost: Identifiable, Codable {
    var id: String
    var title: String
    var topic: String
    var content: String
    var level: String
    var author: String
    var authorEmail: String
    var vote: Int
    var imageBase64: String?
}

struct ForumComment: Identifiable, Codable {
    var id: String
    var postID: String
    var author: String
    var comment: String
    var vote: Int
}

class ForumManager: ObservableObject {
    @Published var posts: [ForumPost] = []
    @Published var comments: [ForumComment] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    private let db = Firestore.firestore()
    @Published var userVotes: [String: Int] = [:] // postID: vote
    @Published var commentUserVotes: [String: Int] = [:] // commentID: vote (local only)
    private var currentUserID: String? {
        Auth.auth().currentUser?.uid
    }
    // Local vote storage for comments
    private let commentVoteKey = "localCommentVotes"
    
    // Load local votes from UserDefaults
    func loadLocalCommentVotes() {
        if let data = UserDefaults.standard.data(forKey: commentVoteKey),
           let dict = try? JSONDecoder().decode([String: Int].self, from: data) {
            commentUserVotes = dict
        }
    }
    // Save local votes to UserDefaults
    func saveLocalCommentVotes() {
        if let data = try? JSONEncoder().encode(commentUserVotes) {
            UserDefaults.standard.set(data, forKey: commentVoteKey)
        }
    }
    // Get user's vote for a comment
    func getUserVoteForComment(_ commentID: String) -> Int {
        commentUserVotes[commentID] ?? 0
    }
    // Set user's vote for a comment
    func setUserVoteForComment(_ commentID: String, vote: Int) {
        commentUserVotes[commentID] = vote
        saveLocalCommentVotes()
    }
    
    // MARK: - Posts
    
    func fetchPosts(topic: String? = nil, completion: (() -> Void)? = nil) {
        isLoading = true
        var query: Query = db.collection("forum")
        if let topic = topic, !topic.isEmpty {
            query = query.whereField("topic", isEqualTo: topic)
        }
        query.order(by: "vote", descending: true)
            .getDocuments { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    if let error = error {
                        self?.errorMessage = error.localizedDescription
                        self?.posts = []
                        completion?()
                        return
                    }
                    self?.posts = snapshot?.documents.compactMap { doc in
                        let data = doc.data()
                        return ForumPost(
                            id: doc.documentID,
                            title: data["title"] as? String ?? "",
                            topic: data["topic"] as? String ?? "",
                            content: data["content"] as? String ?? "",
                            level: data["level"] as? String ?? "",
                            author: data["author"] as? String ?? "",
                            authorEmail: data["authorEmail"] as? String ?? "",
                            vote: data["vote"] as? Int ?? 0,
                            imageBase64: data["imageBase64"] as? String
                        )
                    } ?? []
                    completion?()
                }
            }
    }
    
    func getUserVote(for postID: String) -> Int {
        userVotes[postID] ?? 0
    }
    
    func votePost(postID: String, delta: Int) {
        guard let uid = currentUserID else { return }
        
        let previousVote = userVotes[postID] ?? 0
        let increment = delta - previousVote
        userVotes[postID] = (previousVote == delta) ? 0 : delta
        let ref = db.collection("forum").document(postID)
        ref.updateData(["vote": FieldValue.increment(Int64(increment))])
    }
    
    func createPost(title: String, topic: String, content: String, level: String, author: String, authorEmail: String, imageBase64: String?, completion: @escaping (Bool) -> Void) {
        var data: [String: Any] = [
            "title": title,
            "topic": topic,
            "content": content,
            "level": level,
            "author": author,
            "authorEmail": authorEmail,
            "vote": 0
        ]
        if let imageBase64 = imageBase64 {
            data["imageBase64"] = imageBase64
        }
        db.collection("forum").addDocument(data: data) { error in
            DispatchQueue.main.async {
                completion(error == nil)
            }
        }
    }
    
    func deletePost(postID: String, completion: @escaping (Bool) -> Void) {
        db.collection("forum").document(postID).delete { error in
            DispatchQueue.main.async {
                completion(error == nil)
            }
        }
    }
    
    // MARK: - Comments
    
    func fetchComments(for postID: String) {
        db.collection("forumComments")
            .whereField("PostID", isEqualTo: postID)
            .order(by: "vote", descending: true)
            .getDocuments { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.errorMessage = error.localizedDescription
                        self?.comments = []
                        return
                    }
                    self?.comments = snapshot?.documents.compactMap { doc in
                        let data = doc.data()
                        return ForumComment(
                            id: doc.documentID,
                            postID: data["PostID"] as? String ?? "",
                            author: data["Author"] as? String ?? "",
                            comment: data["comment"] as? String ?? "",
                            vote: data["vote"] as? Int ?? 0
                        )
                    } ?? []
                    self?.loadLocalCommentVotes()
                }
            }
    }
    
    func voteComment(commentID: String, delta: Int) {
        let previousVote = getUserVoteForComment(commentID)
        let increment = delta - previousVote
        setUserVoteForComment(commentID, vote: (previousVote == delta) ? 0 : delta)
        let ref = db.collection("forumComments").document(commentID)
        ref.updateData(["vote": FieldValue.increment(Int64(increment))])
    }
    
    func createComment(postID: String, author: String, comment: String, completion: @escaping (Bool) -> Void) {
        let data: [String: Any] = [
            "PostID": postID,
            "Author": author,
            "comment": comment,
            "vote": 0
        ]
        db.collection("forumComments").addDocument(data: data) { error in
            DispatchQueue.main.async {
                completion(error == nil)
            }
        }
    }
}
