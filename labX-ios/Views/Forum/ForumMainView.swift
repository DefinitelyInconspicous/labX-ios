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
    @State private var sortType: SortType = .mostUpvoted
    @State private var showTipSheet = false
    
    let topics = ["physics", "chemistry", "biology"]
    let topicDisplayNames = ["Physics", "Chemistry", "Biology"]
    
    enum SortType: String, CaseIterable, Identifiable {
        case mostUpvoted = "Most Upvoted"
        case leastUpvoted = "Least Upvoted"
        case mostRecent = "Most Recent"
        case titleAZ = "Title A-Z"
        case titleZA = "Title Z-A"
        case authorAZ = "Author A-Z"
        case authorZA = "Author Z-A"
        var id: String { rawValue }
    }
    
    var filteredPosts: [ForumPost] {
        let normalizedTopic = selectedTopic.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        var posts = forumManager.posts.filter { post in
            normalizedTopic.isEmpty || post.topic.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == normalizedTopic
        }
        switch sortType {
        case .mostUpvoted:
            posts.sort { $0.vote > $1.vote }
        case .leastUpvoted:
            posts.sort { $0.vote < $1.vote }
        case .mostRecent:
            posts.sort { $0.id > $1.id }
        case .titleAZ:
            posts.sort { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case .titleZA:
            posts.sort { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedDescending }
        case .authorAZ:
            posts.sort { $0.author.localizedCaseInsensitiveCompare($1.author) == .orderedAscending }
        case .authorZA:
            posts.sort { $0.author.localizedCaseInsensitiveCompare($1.author) == .orderedDescending }
        }
        return posts
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Topic Picker
                Picker("Topic", selection: $selectedTopic) {
                    Text("All").tag("")
                    ForEach(topics.indices, id: \ .self) { idx in
                        Text(topicDisplayNames[idx]).tag(topics[idx])
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 8)
                .onChange(of: selectedTopic) { newTopic in
                    forumManager.fetchPosts(topic: newTopic.trimmingCharacters(in: .whitespacesAndNewlines).lowercased())
                }
                
                // Sorting Picker
                Picker("Sort by", selection: $sortType) {
                    ForEach(SortType.allCases) { sort in
                        Text(sort.rawValue).tag(sort)
                    }
                }
                .pickerStyle(.menu)
                .padding(.horizontal)
                .padding(.bottom, 4)
                
                // Posts List
                if forumManager.isLoading {
                    Spacer()
                    ProgressView("Loading posts...")
                        .padding()
                    Spacer()
                } else if filteredPosts.isEmpty {
                    Spacer()
                    Text("No posts found.")
                        .foregroundColor(.secondary)
                        .padding()
                    Spacer()
                } else {
                    List(filteredPosts) { post in
                        NavigationLink(
                            destination: ForumPostView(
                                post: post,
                                user: userManager.user
                            )
                        ) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(post.topic)
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                    .fontWeight(.semibold)
                                
                                Text(post.title.isEmpty ? "Untitled" : post.title)
                                    .font(.body)
                                    .foregroundColor(.primary)
                                    .lineLimit(2)
                                
                                // Optional Image
                                if let base64 = post.imageBase64,
                                   let imageData = Data(base64Encoded: base64),
                                   let uiImage = UIImage(data: imageData) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(height: 120)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                        .clipped()
                                }
                                
                                // Metadata row
                                HStack {
                                    Text("By \(post.author)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(post.level)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    HStack(spacing: 4) {
                                        Image(systemName: "arrow.up")
                                            .font(.caption2)
                                            .foregroundColor(.gray)
                                        Text("\(post.vote)")
                                            .font(.caption2)
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    .listStyle(.insetGrouped)
                }
                
                // Login warning
                if userManager.user == nil {
                    Text("Log in to create posts and comments.")
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.vertical, 6)
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
            .sheet(isPresented: $showTipSheet) {
                ForumHelpGuide()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showCreateSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .imageScale(.large)
                    }
                    .disabled(userManager.user == nil)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showTipSheet = true
                    } label: {
                        Image(systemName: "questionmark.circle")
                            .imageScale(.large)
                    }
                    .accessibilityLabel("Forum Help")
                }
            }
        }
    }
}





#Preview {
    ForumMainView()
}
