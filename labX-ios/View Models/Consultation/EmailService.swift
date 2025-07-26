//
//  EmailService.swift
//  labX-ios
//
//  Created by Avyan Mehra on 23/6/25.
//

import Foundation
import MessageUI
import SwiftUI
class EmailService: NSObject, ObservableObject {
    @Published var isShowingMailView = false
    @Published var mailResult: MFMailComposeResult?
    @Published var emailSent = false
    @Published var emailCancelled = false
    
    var mailComposer: MFMailComposeViewController?
    var onEmailSent: (() -> Void)?
    var onEmailCancelled: (() -> Void)?
    func canSendEmail() -> Bool {
        return MFMailComposeViewController.canSendMail()
    }
    func sendConsultationEmail(
        to teacher: staff, 
        from student: User, 
        date: Date, 
        comment: String, 
        location: String,
        onSent: @escaping () -> Void,
        onCancelled: @escaping () -> Void
    ) -> Bool {
        print("sendConsultationEmail called for teacher: \(teacher.name)")
        
        guard MFMailComposeViewController.canSendMail() else {
            print("Device cannot send emails")
            return false
        }
        
        self.onEmailSent = onSent
        self.onEmailCancelled = onCancelled
        
        self.emailSent = false
        self.emailCancelled = false
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .short
        
        let subject = "New Consultation Request - \(student.firstName) \(student.lastName)"
        
        let body = """
        Dear \(teacher.name),
        
        You have received a new consultation request from a student.
        
        Student Details:
        - Name: \(student.firstName) \(student.lastName)
        - Class: \(student.className)
        - Register Number: \(student.registerNumber)
        - Email: \(student.email)
        
        Consultation Details:
        - Date: \(dateFormatter.string(from: date))
        - Location: \(location)
        - Student's Comment: \(comment)
        
        Please review this request and respond accordingly.
        
        Best regards,
        LabX iOS App
        """
        
        let mailComposer = MFMailComposeViewController()
        mailComposer.mailComposeDelegate = self
        mailComposer.setToRecipients([teacher.email])
        mailComposer.setSubject(subject)
        mailComposer.setMessageBody(body, isHTML: false)
        
        self.mailComposer = mailComposer
        self.isShowingMailView = true
        
        print("Mail composer set up, showing mail view")
        return true
    }
    func sendRescheduleEmail(
        to studentEmail: String,
        from teacherName: String,
        originalDate: Date,
        newDate: Date,
        originalLocation: String,
        newLocation: String,
        reason: String,
        originalComment: String,
        onSent: @escaping () -> Void,
        onCancelled: @escaping () -> Void
    ) -> Bool {
        print("sendRescheduleEmail called for student: \(studentEmail)")
        
        guard MFMailComposeViewController.canSendMail() else {
            print("Device cannot send emails")
            return false
        }
            
        self.onEmailSent = onSent
        self.onEmailCancelled = onCancelled
        
        self.emailSent = false
        self.emailCancelled = false
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .short
        
        let subject = "Consultation Rescheduled - \(teacherName)"
        
        let body = """
        Dear Student,
        
        Your consultation with \(teacherName) has been rescheduled.
        
        Original Consultation Details:
        - Date: \(dateFormatter.string(from: originalDate))
        - Location: \(originalLocation)
        - Your Comment: \(originalComment)
        
        New Consultation Details:
        - Date: \(dateFormatter.string(from: newDate))
        - Location: \(newLocation)
        
        Reason for Rescheduling: \(reason.isEmpty ? "No reason provided" : reason)
        
        Please update your calendar accordingly.
        
        Best regards,
        \(teacherName)
        LabX iOS App
        """
        
        let mailComposer = MFMailComposeViewController()
        mailComposer.mailComposeDelegate = self
        mailComposer.setToRecipients([studentEmail])
        mailComposer.setSubject(subject)
        mailComposer.setMessageBody(body, isHTML: false)
        
        self.mailComposer = mailComposer
        self.isShowingMailView = true
        
        print("Reschedule mail composer set up, showing mail view")
        return true
    }
}

extension EmailService: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        print("Mail compose controller finished with result: \(result.rawValue)")
        self.mailResult = result
        
        switch result {
        case .cancelled:
            print("Email cancelled")
            self.emailCancelled = true
            self.onEmailCancelled?()
        case .saved:
            print("Email saved as draft")
            self.emailCancelled = true
            self.onEmailCancelled?()
        case .sent:
            print("Email sent successfully")
            self.emailSent = true
            self.onEmailSent?()
        case .failed:
            print("Email failed to send: \(error?.localizedDescription ?? "Unknown error")")
            self.emailCancelled = true
            self.onEmailCancelled?()
        @unknown default:
            print("Unknown email result")
            self.emailCancelled = true
            self.onEmailCancelled?()
        }
        
        print("Setting isShowingMailView to false")
        self.isShowingMailView = true
        self.mailComposer = nil
    }
}

struct MailView: UIViewControllerRepresentable {
    @Binding var isShowing: Bool
    let mailComposer: MFMailComposeViewController
    
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        return mailComposer
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        let parent: MailView
        
        init(_ parent: MailView) {
            self.parent = parent
        }
    }
}

#Preview {
    Text("EmailService Preview")
        .onAppear {
            let emailService = EmailService()
            print("Can send email: \(emailService.canSendEmail())")
        }
} 
