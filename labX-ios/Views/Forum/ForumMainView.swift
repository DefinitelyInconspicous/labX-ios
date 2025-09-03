//
//  ForumMainView.swift
//  labX-ios
//
//  Created by Avyan Mehra on 3/9/25.
//

import SwiftUI

struct ForumMainView: View {
    @StateObject private var forumManager = ForumManager()
    @State private var selectedTopic: String = ""
    @State private var showCreateSheet = false
    @StateObject private var userManager = UserManager()
    let topics = ["Physics", "Chemistry", "Biology"]
    
    var filteredPosts: [ForumPost] {
        if selectedTopic.isEmpty {
            return forumManager.posts
        } else {
            return forumManager.posts.filter { $0.topic == selectedTopic }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                Picker("Topic", selection: $selectedTopic) {
                    Text("All").tag("")
                    ForEach(topics, id: \.self) { topic in
                        Text(topic).tag(topic)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                Spacer()
                if forumManager.isLoading {
                    ProgressView("Loading posts...")
                        .padding()
                } else if filteredPosts.isEmpty {
                    Text("No posts found.")
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    List(filteredPosts) { post in
                        NavigationLink(destination: ForumPostView(post: post, user: userManager.user)) {
                            HStack(alignment: .top, spacing: 12) {
                                if let base64 = post.imageBase64, let imageData = Data(base64Encoded: base64), let uiImage = UIImage(data: imageData) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 40, height: 40)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(post.topic)
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                        Spacer()
                                        Text("Votes: \(post.vote)")
                                            .font(.caption2)
                                            .foregroundColor(.gray)
                                    }
                                    Text(post.content)
                                        .font(.body)
                                        .lineLimit(2)
                                    HStack {
                                        Text(post.author)
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        Text(post.level)
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
                Spacer()
                
                Button(action: { showCreateSheet = true }) {
                    Text("Create Post")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(userManager.user == nil ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()
                .disabled(userManager.user == nil)
                if userManager.user == nil {
                    Text("Log in to create posts and comments.")
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.bottom, 8)
                }
            }
            .navigationTitle("Forum")
            .onAppear {
                forumManager.fetchPosts(topic: selectedTopic)
                userManager.fetchUser()
            }
            .sheet(isPresented: $showCreateSheet) {
                if let user = userManager.user {
                    ForumCreateView(forumManager: forumManager, user: user)
                } else {
                    Text("Log in to create posts.")
                }
            }
        }
    }
}

#Preview {
    ForumMainView()
}
