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
    @State var showAlert = false
    @Environment(\.dismiss) var dismiss
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Reason for Reporting").font(.headline)) {
                    TextEditor(text: $reason)
                        .frame(height: 150)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.5)))
                }
                Button {
                    if reason.trimmingCharacters(in: .whitespacesAndNewlines).count < 20 {
                        return
                    } else {
                        submitReport = true
                        dismiss()
                    }
                } label: {
                    Text("Submit Report")
                        .bold()
                        .frame(maxWidth: .infinity)
                }
            }

            .navigationTitle("Report Post")
        }
        .alert("Please fill in a valid response more than 20 words", isPresented: $showAlert) {
            Button {
                showAlert = false
            } label: {
                Text("OK")
            }
        }
    }
}

#Preview {
    ForumReportView(reason: .constant(""), postID: .constant(""), submitReport: .constant(false))
}
