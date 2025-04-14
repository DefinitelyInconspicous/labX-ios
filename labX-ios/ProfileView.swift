//
//  ProfileView.swift
//  labX-ios
//
//  Created by Avyan Mehra on 14/4/25.
//

import SwiftUI
import FirebaseAuth
import Forever

struct ProfileRow: View {
    var label: String
    var value: String

    var body: some View {
        HStack {
            Text(label + ":")
                .fontWeight(.semibold)
            Spacer()
            Text(value)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 4)
    }
}

struct ProfileView: View {
    let user: User
    @Forever("isLoggedIn") var isLoggedIn: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "person.crop.circle")
                    .imageScale(.large)
                    .font(.system(size: 50))
                    .padding(.bottom, 16)
                Text(user.firstName + " " + user.lastName)
                    .font(.title2)
            }
            ProfileRow(label: "Email", value: user.email)
            ProfileRow(label: "Class", value: user.className)
            ProfileRow(label: "Register No.", value: user.registerNumber)

            Spacer()

            Button(action: logout) {
                Text("Log Out")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .foregroundColor(.red)
                    .background(Color(.systemGray5))
                    .cornerRadius(8)
            }
            .padding(.top, 32)
        }
        .padding()
        .navigationTitle("Profile")
    }

    private func logout() {
        do {
            try Auth.auth().signOut()
            isLoggedIn = false
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
}
