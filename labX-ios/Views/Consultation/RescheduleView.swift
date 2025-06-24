//
//  RescheduleView.swift
//  labX-ios
//
//  Created by Avyan Mehra on 14/4/25.
//

import SwiftUI
import FirebaseFirestore
import MessageUI

struct RescheduleView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var emailService = EmailService()
    @StateObject private var consultationManager = ConsultationManager()
    
    let consultation: consultation
    @State private var newDate: Date = Date()
    @State private var newLocation: String = ""
    @State private var rescheduleReason: String = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isRescheduling = false
    @State private var emailPending = false
    @State private var showEmailSetupGuide = false
    
    private let db = Firestore.firestore()
    
    let locations: [String] = [
        "Outside Staffroom",
        "Classroom (Please specify in comments)",
        "Outside Labs (Level 1)",
        "Outside Labs (Level 2)",
        "Online"
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Current Consultation")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Student: \(consultation.student)")
                            .font(.headline)
                        Text("Current Date: \(consultation.date.formatted(date: .long, time: .shortened))")
                            .font(.subheadline)
                        Text("Current Location: \(consultation.location)")
                            .font(.subheadline)
                        Text("Comment: \(consultation.comment)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                
                Section(header: Text("New Details")) {
                    DatePicker("New Date & Time", selection: $newDate, displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.compact)
                    
                    Picker("New Location", selection: $newLocation) {
                        Text("Select location").tag("")
                        ForEach(locations, id: \.self) { location in
                            Text(location).tag(location)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section(header: Text("Reschedule Reason")) {
                    TextField("Why are you rescheduling? (Optional)", text: $rescheduleReason, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section {
                    HStack {
                        Image(systemName: emailService.canSendEmail() ? "envelope.fill" : "envelope.slash")
                            .foregroundColor(emailService.canSendEmail() ? .green : .orange)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(emailService.canSendEmail() ? "Email notifications available" : "Email notifications unavailable")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            if !emailService.canSendEmail() {
                                Text("Student will not be notified by email")
                                    .font(.caption2)
                                    .foregroundColor(.orange)
                            }
                        }
                        Spacer()
                        
                        if !emailService.canSendEmail() {
                            Button("Setup Guide") {
                                showEmailSetupGuide = true
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                Section {
                    Button(action: rescheduleConsultation) {
                        HStack {
                            if isRescheduling {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                            Text(isRescheduling ? "Rescheduling..." : "Reschedule Consultation")
                        }
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.orange)
                        .cornerRadius(10)
                    }
                    .disabled(isRescheduling || newLocation.isEmpty || newDate < Date())
                    
                    if emailPending {
                        HStack {
                            Image(systemName: "envelope.badge")
                                .foregroundColor(.orange)
                            Text("Email notification pending...")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                        .padding(.top, 8)
                    }
                }
            }
            .navigationTitle("Reschedule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Reschedule Status"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
            .sheet(isPresented: $emailService.isShowingMailView) {
                if let mailComposer = emailService.mailComposer {
                    MailView(isShowing: $emailService.isShowingMailView, mailComposer: mailComposer)
                }
            }
            .sheet(isPresented: $showEmailSetupGuide) {
                EmailSetupGuide()
            }
            .onAppear {
                newDate = consultation.date
                newLocation = consultation.location
            }
        }
    }
    
    private func rescheduleConsultation() {
        guard !newLocation.isEmpty else {
            alertMessage = "Please select a new location"
            showAlert = true
            return
        }
        
        guard newDate > Date() else {
            alertMessage = "Please select a future date and time"
            showAlert = true
            return
        }
        
        isRescheduling = true
        
        // Use the ConsultationManager to reschedule
        Task {
            let success = await consultationManager.rescheduleConsultation(
                consultation.id.uuidString,
                newDate: newDate,
                newLocation: newLocation,
                reason: rescheduleReason,
                rescheduledBy: consultation.teacher.email
            )
            
            if success {
                // Check if email is available before attempting to send
                if emailService.canSendEmail() {
                    // Send email notification to student
                    let emailSent = sendRescheduleEmail()
                    
                    if emailSent {
                        // Email composer will open, success message will be shown after email is sent/cancelled
                        emailPending = true
                        // Don't show immediate success message here - it will be handled by email callbacks
                    } else {
                        // Email composer failed to open, show success message without email
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            isRescheduling = false
                            alertMessage = "Consultation rescheduled successfully!\n\n⚠️ Email notification could not be sent.\n\nNew Date: \(newDate.formatted(date: .abbreviated, time: .shortened))\nNew Location: \(newLocation)"
                            showAlert = true
                            
                            // Dismiss after showing success message
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                dismiss()
                            }
                        }
                    }
                } else {
                    // Email not available, show success message without email
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        isRescheduling = false
                        alertMessage = "Consultation rescheduled successfully!\n\n⚠️ Email notifications are not available on this device.\n\nNew Date: \(newDate.formatted(date: .abbreviated, time: .shortened))\nNew Location: \(newLocation)"
                        showAlert = true
                        
                        // Dismiss after showing success message
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            dismiss()
                        }
                    }
                }
            } else {
                // Rescheduling failed
                DispatchQueue.main.async {
                    isRescheduling = false
                    alertMessage = "Failed to reschedule consultation. Please try again."
                    showAlert = true
                }
            }
        }
    }
    
    private func sendRescheduleEmail() -> Bool {
        let emailSent = emailService.sendRescheduleEmail(
            to: consultation.student,
            from: consultation.teacher.name,
            originalDate: consultation.date,
            newDate: newDate,
            originalLocation: consultation.location,
            newLocation: newLocation,
            reason: rescheduleReason,
            originalComment: consultation.comment,
            onSent: {
                print("📧 Reschedule email sent successfully")
                DispatchQueue.main.async {
                    self.isRescheduling = false
                    self.emailPending = false
                    self.alertMessage = "Consultation rescheduled successfully!\n\nEmail notification sent to student.\n\nNew Date: \(self.newDate.formatted(date: .abbreviated, time: .shortened))\nNew Location: \(self.newLocation)"
                    self.showAlert = true
                    
                    // Dismiss after showing success message
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        self.dismiss()
                    }
                }
            },
            onCancelled: {
                print("📧 Reschedule email was not sent")
                DispatchQueue.main.async {
                    self.isRescheduling = false
                    self.emailPending = false
                    self.alertMessage = "Consultation rescheduled successfully!\n\nEmail notification was not sent.\n\nNew Date: \(self.newDate.formatted(date: .abbreviated, time: .shortened))\nNew Location: \(self.newLocation)"
                    self.showAlert = true
                    
                    // Dismiss after showing success message
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        self.dismiss()
                    }
                }
            }
        )
        
        return emailSent
    }
}

#Preview {
    RescheduleView(consultation: consultation(
        teacher: staff(name: "Dr. Smith", email: "smith@school.edu"),
        date: Date(),
        comment: "Need help with physics",
        student: "student@school.edu",
        location: "Outside Staffroom"
    ))
} 
