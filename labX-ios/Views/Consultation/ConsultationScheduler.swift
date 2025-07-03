//
//  ConsultationScheduler.swift
//  labX-ios
//
//  Created by Avyan Mehra on 2/7/25.
//


import SwiftUI
import EventKit
import FirebaseFirestore

struct ConsultationScheduler: View {
    @State private var selectedTeacher: staff?
    @State private var selectedDate: Date = Date()
    @State private var selectedTimeSlots: Set<Date> = []
    @State private var bookedTimeSlots: Set<Date> = []
    @State private var selectedLocation: String = ""
    @State private var comments: String = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @StateObject private var userManager = UserManager()
    @StateObject private var consultationManager = ConsultationManager()
    @State private var teachers: [staff] = []
    @StateObject private var emailService = EmailService()
    @State private var isCreating = false
    @State private var showEmailSetupGuide = false
    @Environment(\.dismiss) private var dismiss

    
    let locations = [
        "Outside Staffroom", "Classroom", "Outside Labs (Level 1)",
        "Outside Labs (Level 2)", "Online"
    ]
    
    var timeSlots: [Date] {
        var slots: [Date] = []
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        components.hour = 8
        components.minute = 0
        guard var current = calendar.date(from: components) else { return [] }
        
        while current < calendar.date(bySettingHour: 19, minute: 20, second: 0, of: selectedDate)! {
            slots.append(current)
            current = calendar.date(byAdding: .minute, value: 20, to: current)!
        }
        return slots
    }
    
    var body: some View {
        NavigationStack {
         

            Form {
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
                
                Section("Teacher") {
                    Picker("Select Teacher", selection: $selectedTeacher) {
                        Text("Select...").tag(nil as staff?)
                        ForEach(teachers, id: \.self) { teacher in
                            Text(teacher.name).tag(teacher as staff?)
                        }
                    }
                    .onChange(of: selectedTeacher) { _ in fetchCalendarEvents() }
                }
                
                Section("Date") {
                    DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
                        .onChange(of: selectedDate) { _ in fetchCalendarEvents() }
                }
                
                Section("Time Slots") {
                    if !selectedTimeSlots.isEmpty {
                        Text("Selected: \(formatTimeRange())")
                            .foregroundColor(.blue)
                    }
                    
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(chunked(timeSlots, size: 4), id: \.self) { row in
                            HStack(spacing: 10) {
                                ForEach(row, id: \.self) { slot in
                                    let isBooked = isSlotBooked(slot)
                                    Button(action: {
                                        if !isBooked {
                                            handleTimeSlotSelection(slot)
                                        }
                                    }) {
                                        Text(timeString(from: slot))
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 8)
                                            .background(
                                                isTimeSlotSelected(slot) ? Color.blue :
                                                    (isBooked ? Color.gray.opacity(0.5) : Color.gray.opacity(0.2))
                                            )
                                            .foregroundColor(
                                                isTimeSlotSelected(slot) ? .white :
                                                    (isBooked ? .gray : .primary)
                                            )
                                            .cornerRadius(8)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .disabled(isBooked)
                                }
                                // Fill remaining space if row is short
                                if row.count < 4 {
                                    ForEach(0..<(4 - row.count), id: \.self) { _ in
                                        Spacer()
                                    }
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                
                
                Section("Location") {
                    Picker("Select Location", selection: $selectedLocation) {
                        ForEach(locations, id: \.self) { location in
                            Text(location).tag(location)
                        }
                    }
                }
                
                Section("Comments") {
                    TextField("I would like to discuss...", text: $comments)
                }
                
                Section {
                    Button("Confirm Consultation", action: submitConsultation)
                        .disabled(!canSubmit)
                }
            }
            .navigationTitle("Schedule Consultation")
            .onAppear {
                requestCalendarAccess()
                fetchCalendarEvents()
                userManager.fetchUser()
                fetchTeachers()
            }

            .alert(isPresented: $showAlert) {
                Alert(title: Text("Consultation"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
        .sheet(isPresented: $emailService.isShowingMailView) {
            if let mailComposer = emailService.mailComposer {
                MailView(isShowing: $emailService.isShowingMailView, mailComposer: mailComposer)
            }
        }
        .sheet(isPresented: $showEmailSetupGuide) {
            EmailSetupGuide()
        }

    }
    
    private var canSubmit: Bool {
        selectedTeacher != nil && !selectedTimeSlots.isEmpty && !comments.isEmpty && !selectedLocation.isEmpty
    }
    
    private func fetchCalendarEvents() {
        bookedTimeSlots = []
        let events = fetchEvents(date: selectedDate)
        var blocked = Set<Date>()
        let calendar = Calendar.current
        
        for event in events {
            var time = event.startDate
            while time ?? Date.now < event.endDate {
                blocked.insert(calendar.date(bySetting: .second, value: 0, of: time ?? Date.now)!)
                time = calendar.date(byAdding: .minute, value: 20, to: time ?? Date.now)!
            }
        }
        bookedTimeSlots = blocked
    }
    
    private func fetchTeachers() {
        let db = Firestore.firestore()
        db.collection("users").whereField("className", isEqualTo: "Staff").getDocuments { snapshot, error in
            guard let docs = snapshot?.documents, error == nil else { return }
            teachers = docs.compactMap { doc in
                guard let first = doc["firstName"] as? String,
                      let last = doc["lastName"] as? String,
                      let email = doc["email"] as? String else { return nil }
                return staff(name: "\(first) \(last)", email: email)
            }
        }
    }
    
    private func isTimeSlotSelected(_ slot: Date) -> Bool {
        selectedTimeSlots.contains(slot)
    }
    
    private func handleTimeSlotSelection(_ slot: Date) {
        if selectedTimeSlots.contains(slot) {
            selectedTimeSlots.remove(slot)
        } else {
            selectedTimeSlots.insert(slot)
        }
    }
    
    private func isSlotBooked(_ slot: Date) -> Bool {
        bookedTimeSlots.contains { Calendar.current.isDate($0, equalTo: slot, toGranularity: .minute) }
    }
    
    private func timeString(from date: Date) -> String {
        let fmt = DateFormatter()
        fmt.timeStyle = .short
        return fmt.string(from: date)
    }
    
    private func formatTimeRange() -> String {
        guard let start = selectedTimeSlots.min(), let end = selectedTimeSlots.max() else { return "" }
        let fmt = DateFormatter()
        fmt.timeStyle = .short
        return "\(fmt.string(from: start)) - \(fmt.string(from: Calendar.current.date(byAdding: .minute, value: 20, to: end)!))"
    }
    
    private func submitConsultation() {
        guard let teacher = selectedTeacher,
              let user = userManager.user,
              let start = selectedTimeSlots.min(),
              let end = selectedTimeSlots.max(),
              !comments.isEmpty,
              !selectedLocation.isEmpty else {
            alertMessage = "Please fill in all details."
            showAlert = true
            return
        }

        isCreating = true

        let consult = consultation(
            teacher: teacher,
            date: start,
            comment: comments,
            student: user.email,
            location: selectedLocation
        )

        consultationManager.addConsultation(consult)

        if emailService.canSendEmail() {
            let emailSent = emailService.sendConsultationEmail(
                to: teacher,
                from: user,
                date: start,
                comment: comments,
                location: selectedLocation,
                onSent: {
                    DispatchQueue.main.async {
                        self.isCreating = false
                        self.alertMessage = "Consultation created successfully!\n\nEmail notification sent to \(teacher.name)."
                        self.showAlert = true
                        self.selectedTimeSlots.removeAll()
                        self.dismiss()
                    }
                },
                onCancelled: {
                    DispatchQueue.main.async {
                        self.isCreating = false
                        self.alertMessage = "Consultation created, but email notification was not sent."
                        self.showAlert = true
                        self.selectedTimeSlots.removeAll()
                        self.dismiss()
                    }
                }
            )
            
            if !emailSent {
                DispatchQueue.main.async {
                    self.isCreating = false
                    self.alertMessage = "Consultation created, but unable to open email composer."
                    self.showAlert = true
                    self.selectedTimeSlots.removeAll()
                    self.dismiss()
                }
            }
        } else {
            DispatchQueue.main.async {
                self.isCreating = false
                self.alertMessage = "Consultation created.\n\nEmail notifications are unavailable on this device."
                self.showAlert = true
                self.selectedTimeSlots.removeAll()
                self.dismiss()
            }
        }

        let newEvent = Event(
            id: UUID(),
            title: "Consultation with \(teacher.name)",
            date: start,
            duration: 30,
            description: comments
        )
        requestCalendarAccess()
        requestEvent(newEvent)
    }

}

func chunked<T>(_ array: [T], size: Int) -> [[T]] {
    stride(from: 0, to: array.count, by: size).map {
        Array(array[$0..<min($0 + size, array.count)])
    }
}

