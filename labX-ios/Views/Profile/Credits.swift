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
    
    var body: some View {
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
                    CreditCard(role: "CEO", personClass: "S3-01", name: "Avyan Mehra")
                    CreditCard(role: "COO", personClass: "S3-03", name: "Prakash Dhanvin")
                    CreditCard(role: "CTO", personClass: "S3-01", name: "Balasaravanan Dhanwin Basil")
                    CreditCard(role: "CDO/CMO", personClass: "S3-03", name: "Dhanush Parthasarathy")
                    CreditCard(role: "Advisor", personClass: "Alumni", name: "Tristan Chay")
                    CreditCard(role: "Advisor", personClass: "Alumni", name: "Aathithya Jegatheesan")
                    CreditCard(role: "Former CTO", personClass: "S3-07", name: "Matthias Ang")
                    CreditCard(role: "Former CDO", personClass: "S3-02", name: "Lee Yu Hang")
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
