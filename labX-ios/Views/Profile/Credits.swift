//
//  Credits.swift
//  labX-ios
//
//  Created by Avyan Mehra on 29/8/25.
//

import SwiftUI

struct CreditCard: View {
    var role: String
    var personClass: String
    var name: String
    var icon: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(role)
                    .font(.headline)
                    .foregroundColor(.blue)
                
                Text(personClass)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(name)
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            Spacer()
            VStack {
                Spacer()
                Image(systemName: icon)
                    .resizable()
                    .frame(width: 60, height: 60)
                Spacer()
            }
            .padding()
        }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray6))
                    .shadow(radius: 4)
            )
            .padding(.horizontal)
            

        
    }
}

struct Credits: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    CreditCard(role: "CEO", personClass: "S3-01", name: "Avyan Mehra", icon: "apple.terminal.circle.fill")
                    CreditCard(role: "COO", personClass: "S3-03", name: "Prakash Dhanvin", icon: "questionmark.circle.fill")
                    CreditCard(role: "CTO", personClass: "S3-01", name: "Balasaravanan Dhanwin Basil", icon: "leaf.circle.fill")
                    CreditCard(role: "CDO/CMO", personClass: "S3-03", name: "Dhanush Parthasarathy", icon: "hydrogen.circle.fill")
                    CreditCard(role: "Advisor", personClass: "Alumni", name: "Tristan Chay", icon: "bolt.circle.fill")
                    CreditCard(role: "Advisor", personClass: "Alumni", name: "Aathithya Jegatheesan", icon: "rugbyball.circle.fill")
                    CreditCard(role: "Former CDO", personClass: "S3-02", name: "Lee Yu Hang", icon: "eject.circle.fill")
                }
                .padding(.vertical)
            }
            .navigationTitle("Credits")
        }
    }
}

#Preview {
    Credits()
}
