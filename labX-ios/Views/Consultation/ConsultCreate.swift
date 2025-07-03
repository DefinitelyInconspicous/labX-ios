//
//  ConsultCreate.swift
//  labX-ios
//
//  Created by Avyan Mehra on 14/4/25.
//

import SwiftUI
import Forever
import FirebaseFirestore

struct ConsultCreate: View {
    @Binding var consultations: [consultation]
    @StateObject private var consultationManager = ConsultationManager()
    @StateObject private var userManager = UserManager()
    @StateObject private var emailService = EmailService()
    
    @State var selectedTeacher: staff?
    @State var selectedDate: Date = Date()
    @State var selectedLocation: String = ""
    @State var showAlert = false
    @State var alertMessage = ""
    @State var comments: String = ""
    @State var teachers: [staff] = []
    @State var isCreating = false
    @State var showEmailSetupGuide = false
    @Environment(\.dismiss) var dismiss
    
    let locations: [String] = [
        "Outside Staffroom",
        "Classroom (Please specify in comments)",
        "Outside Labs (Level 1)",
        "Outside Labs (Level 2)",
        "Online"
    ]
    
    var body: some View {
        NavigationStack {
            NavigationLink {
                ConsultationScheduler()
            } label: {
                Text("Dev bypass to schedule")
            }
            Form {
                Section(header: Text("Select Teacher")) {
                    Picker("Teacher", selection: $selectedTeacher) {
                        Text("Select a teacher").tag(nil as staff?)
                        ForEach(teachers, id: \.self) { teacher in
                            Text(teacher.name).tag(teacher as staff?)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section(header: Text("Select Date")) {
                    DatePicker("Date", selection: $selectedDate, displayedComponents: [.date, .hourAndMinute])
                }
                
                Section(header: Text("Select location")) {
                    Picker("Location", selection: $selectedLocation) {
                        ForEach(locations, id: \.self) { location in
                            Text(location).tag(location)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section(header: Text("Comments")) {
                    TextField("I would like to catch up on...", text: $comments)
                }
                
                // Email Status Section
                Section {
                    HStack {
                        Image(systemName: emailService.canSendEmail() ? "envelope.fill" : "envelope.slash")
                            .foregroundColor(emailService.canSendEmail() ? .green : .orange)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(emailService.canSendEmail() ? "Email notifications available" : "Email notifications unavailable")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            if !emailService.canSendEmail() {
                                Text("Teacher will not be notified by email")
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
                    Button {
                        createConsultation()
                    } label: {
                        HStack {
                            if isCreating {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                            Text(isCreating ? "Creating..." : "Create Consultation")
                        }
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                    }
                    .disabled(isCreating || selectedTeacher == nil || comments.isEmpty || selectedDate < Date() || selectedLocation.isEmpty)
                }
            }
            .navigationTitle("Create Consultation")
            .navigationBarTitleDisplayMode(.inline)
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Consultation Status"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
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
                userManager.fetchUser()
                fetchTeachers()
            }
        }
    }
    
    private func createConsultation() {
        guard let teacher = selectedTeacher,
              let user = userManager.user,
              !comments.isEmpty,
              selectedDate > Date(),
              !selectedLocation.isEmpty else {
            alertMessage = "Please ensure you have selected a teacher, added a comment, selected a valid future date, and chosen a location"
            showAlert = true
            return
        }
        
        isCreating = true
        
        let newConsult = consultation(
            teacher: teacher,
            date: selectedDate,
            comment: comments,
            student: user.email,
            location: selectedLocation
        )
        
        // Add consultation to Firestore
        consultationManager.addConsultation(newConsult)
        
        // Send email notification if available
        if emailService.canSendEmail() {
            let emailSent = emailService.sendConsultationEmail(
                to: teacher,
                from: user,
                date: selectedDate,
                comment: comments,
                location: selectedLocation,
                onSent: {
                    print("📧 Consultation email sent successfully")
                    DispatchQueue.main.async {
                        self.isCreating = false
                        self.alertMessage = "Consultation created successfully!\n\nEmail notification sent to \(teacher.name)."
                        self.showAlert = true
                        
                        // Dismiss after showing success message
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            self.dismiss()
                        }
                    }
                },
                onCancelled: {
                    print("📧 Consultation email was not sent")
                    DispatchQueue.main.async {
                        self.isCreating = false
                        self.alertMessage = "Consultation created successfully!\n\nEmail notification was not sent."
                        self.showAlert = true
                        
                        // Dismiss after showing success message
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            self.dismiss()
                        }
                    }
                }
            )
            
            if !emailSent {
                // Email composer failed to open
                DispatchQueue.main.async {
                    self.isCreating = false
                    self.alertMessage = "Consultation created successfully!\n\n⚠️ Email notification could not be sent."
                    self.showAlert = true
                    
                    // Dismiss after showing success message
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        self.dismiss()
                    }
                }
            }
        } else {
            // Email not available
            DispatchQueue.main.async {
                self.isCreating = false
                self.alertMessage = "Consultation created successfully!\n\n⚠️ Email notifications are not available on this device.\n\nTeacher: \(teacher.name)\nDate: \(selectedDate.formatted(date: .abbreviated, time: .shortened))\nLocation: \(selectedLocation)"
                self.showAlert = true
                
                // Dismiss after showing success message
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    self.dismiss()
                }
            }
        }
        
        let newEvent: Event = Event(
            id: UUID(),
            title: "Consultation with \(teacher.name)",
            date: selectedDate,
            duration: 30,
            description: comments,
        )
            requestCalendarAccess()
            requestEvent(newEvent)
        print("Added Calendar Event")

        
    
}

    private func fetchTeachers() {
        let db = Firestore.firestore()
        print("Fetching teachers from Firestore...")
        db.collection("users")
            .whereField("className", isEqualTo: "Staff")
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching teachers: \(error.localizedDescription)")
                    return
                }
                
                if let documents = snapshot?.documents {
                    print("Found \(documents.count) teachers")
                    teachers = documents.compactMap { document in
                        let data = document.data()
                        guard let firstName = data["firstName"] as? String,
                              let lastName = data["lastName"] as? String,
                              let email = data["email"] as? String else {
                            print("Failed to parse teacher data: \(data)")
                            return nil
                        }
                        let fullName = "\(firstName) \(lastName)"
                        print("Parsed teacher: \(fullName) (\(email))")
                        return staff(name: fullName, email: email)
                    }
                    print("Successfully loaded \(teachers.count) teachers")
                } else {
                    print("No teachers found in Firestore")
                }
            }
    }
}

#Preview {
    ConsultCreate(consultations: .constant([consultation(teacher: staff(name: "", email: ""), date: .now, comment: "", student: "", location: "")]))
}
