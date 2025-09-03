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
    
    let topics = ["Physics", "Chemistry", "Biology"]
    
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
                    ForEach(topics, id: \.self) { topic in
                        Text(topic).tag(topic)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 8)
                .onChange(of: selectedTopic) { newTopic in
                    forumManager.fetchPosts(topic: newTopic)
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
                                
                                Text(post.content)
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

struct ForumHelpGuide: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        Text("Forum Help Guide")
                            .font(.title)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        Text("Learn how to use the forum and get the most out of your experience.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 20)
                    // Step-by-Step Instructions
                    VStack(spacing: 16) {
                        Text("Step-by-Step Instructions")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                        VStack(spacing: 12) {
                            ForumStepCard(number: 1, title: "Filter by Topic", description: "Use the topic picker at the top to filter posts by subject.", icon: "line.3.horizontal.decrease.circle")
                            ForumStepCard(number: 2, title: "Sort Posts", description: "Sort posts using the sort menu for upvotes, recency, title, or author.", icon: "arrow.up.arrow.down.circle")
                            ForumStepCard(number: 3, title: "Create a Post", description: "Tap the plus button to create a new post and share your question or idea.", icon: "plus.circle")
                            ForumStepCard(number: 4, title: "Vote & Comment", description: "Vote and comment on posts to join the discussion and help others.", icon: "hand.thumbsup.circle")
                        }
                        .padding(.horizontal)
                    }
                    // Tips Section
                    VStack(spacing: 16) {
                        Text("Tips")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                        VStack(spacing: 8) {
                            ForumTipRow(text: "You can only vote once per post or comment.")
                            ForumTipRow(text: "Use your real name for credibility.")
                            ForumTipRow(text: "Be respectful and constructive in your comments.")
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(16)
                        .padding(.horizontal)
                    }
                    // Troubleshooting
                    VStack(spacing: 16) {
                        Text("Troubleshooting")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                        VStack(spacing: 8) {
                            ForumTipRow(text: "If posts don’t appear, check your internet connection.")
                            ForumTipRow(text: "If you can’t vote or comment, make sure you’re logged in.")
                            ForumTipRow(text: "Refresh the page if you encounter issues.")
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(16)
                        .padding(.horizontal)
                    }
                    Spacer(minLength: 20)
                }
            }
            .navigationTitle("Forum Help")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct ForumStepCard: View {
    let number: Int
    let title: String
    let description: String
    let icon: String
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 36, height: 36)
                Text("\(number)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
            }
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.blue)
                        .frame(width: 20)
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(nil)
            }
            Spacer()
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
    }
}

struct ForumTipRow: View {
    let text: String
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "circle.fill")
                .font(.system(size: 6))
                .foregroundColor(.blue)
                .padding(.top, 8)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(nil)
            Spacer()
        }
    }
}

#Preview {
    ForumMainView()
}
