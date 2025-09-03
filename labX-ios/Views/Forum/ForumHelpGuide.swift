//
//  ForumHelpGuide.swift
//  labX-ios
//
//  Created by Avyan Mehra on 4/9/25.
//

import SwiftUI

struct ForumHelpGuide: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
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
