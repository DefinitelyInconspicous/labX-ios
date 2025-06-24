//
//  EmailSetupGuide.swift
//  labX-ios
//
//  Created by Avyan Mehra on 23/6/25.
//

import SwiftUI
import MessageUI

struct EmailSetupGuide: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "envelope.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        Text("Email Setup Guide")
                            .font(.title)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        Text("Follow these steps to set up email on your device")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 20)
                    
                    // Steps
                    VStack(spacing: 16) {
                        Text("Step-by-Step Instructions")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            StepCard(
                                number: 1,
                                title: "Open Settings",
                                description: "Go to your device's Settings app",
                                icon: "gear"
                            )
                            
                            StepCard(
                                number: 2,
                                title: "Find Mail",
                                description: "Scroll down and tap on 'Mail'",
                                icon: "envelope"
                            )
                            
                            StepCard(
                                number: 3,
                                title: "Add Account",
                                description: "Tap 'Accounts' then 'Add Account'",
                                icon: "plus.circle"
                            )
                            
                            StepCard(
                                number: 4,
                                title: "Choose Provider",
                                description: "Select your email provider (Gmail, Outlook, iCloud, etc.)",
                                icon: "checkmark.circle"
                            )
                            
                            StepCard(
                                number: 5,
                                title: "Enter Credentials",
                                description: "Enter your email address and password",
                                icon: "key"
                            )
                            
                            StepCard(
                                number: 6,
                                title: "Enable Mail",
                                description: "Make sure 'Mail' is turned ON for this account",
                                icon: "checkmark.seal"
                            )
                            
                            StepCard(
                                number: 7,
                                title: "Test Setup",
                                description: "Return to this app and try creating a consultation again",
                                icon: "checkmark.shield"
                            )
                        }
                        .padding(.horizontal)
                    }
                    
                    // Common Email Providers
                    VStack(spacing: 16) {
                        Text("Common Email Providers")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                        
                        VStack(spacing: 8) {
                            EmailProviderRow(name: "Gmail", domain: "@gmail.com")
                            EmailProviderRow(name: "Outlook", domain: "@outlook.com")
                            EmailProviderRow(name: "Yahoo", domain: "@yahoo.com")
                            EmailProviderRow(name: "iCloud", domain: "@icloud.com")
                            EmailProviderRow(name: "School Email", domain: "@s20XX.ssts.edu.sg")
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(16)
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
                            TipRow(text: "Make sure you have an active internet connection")
                            TipRow(text: "Use your school email for better integration")
                            TipRow(text: "If you have 2FA enabled, you may need an app password")
                            TipRow(text: "Contact the IT department if you need help with school email")
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
                            TipRow(text: "If setup fails, try removing and re-adding the account")
                            TipRow(text: "Check that your email and password are correct")
                            TipRow(text: "Some providers require enabling 'Less secure apps'")
                            TipRow(text: "Restart your device if you encounter issues")
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(16)
                        .padding(.horizontal)
                    }
                    
                    // Bottom spacing
                    Spacer(minLength: 20)
                }
            }
            .navigationTitle("Email Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

struct StepCard: View {
    let number: Int
    let title: String
    let description: String
    let icon: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Step number
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

struct EmailProviderRow: View {
    let name: String
    let domain: String
    
    var body: some View {
        HStack {
            LabeledContent {
                Text(domain)
            } label: {
                Text(name)
            }
        }
        .padding(.vertical, 6)
    }
}

struct TipRow: View {
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
    EmailSetupGuide()
}
