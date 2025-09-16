//
//  ForumReportView.swift
//  labX-ios
//
//  Created by Avyan Mehra on 10/9/25.
//

import SwiftUI

struct ForumReportView: View {
    @Binding var reason: String
    @Binding var postID: String
    @Binding var submitReport: Bool
    @State private var showAlert = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                
                // MARK: - Input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Reason for Reporting")
                        .font(.headline)
                    
                    TextEditor(text: $reason)
                        .frame(height: 140)
                        .padding(4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(.secondary.opacity(0.4))
                        )
                }
                .padding(.horizontal)
                
                // MARK: - Submit Button
                Button {
                    if reason.trimmingCharacters(in: .whitespacesAndNewlines).split(separator: " ").count < 10 {
                        showAlert = true
                    } else {
                        submitReport = true
                        dismiss()
                    }
                } label: {
                    Text("Submit Report")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .padding(.horizontal)
            }
            .padding(.top, 20)
            .navigationTitle("Report Post")
            .navigationBarTitleDisplayMode(.inline)
        }
        .alert("Please provide at least 10 words.", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        }
    }
}

#Preview {
    ForumReportView(reason: .constant(""),
                    postID: .constant(""),
                    submitReport: .constant(false))
}
