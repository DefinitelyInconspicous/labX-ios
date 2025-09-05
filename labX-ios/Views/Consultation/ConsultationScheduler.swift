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
    @State private var selectedLocation: String = "Select Location"
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
        
        while current < calendar.date(bySettingHour: 19, minute: 00, second: 0, of: selectedDate)! {
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
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
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
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(chunked(timeSlots, size: 3), id: \.self) { row in
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
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .disabled(isBooked)
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
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                    }
                }
                
                Section("Comments") {
                    TextField("I would like to discuss...", text: $comments)
                }
                
                Section {
                    Button("Confirm Consultation", action: submitConsultation)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
            .navigationTitle("Schedule Consultation")
            .scrollDismissesKeyboard(.interactively)
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
        print("fetchcalendarevents called")
        bookedTimeSlots = []
        guard let teacher = selectedTeacher else { return }

        let db = Firestore.firestore()
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(secondsFromGMT: 0)! // ← Force UTC to match Firestore

        let startOfDay = calendar.startOfDay(for: selectedDate)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let teacherEmail = teacher.email.lowercased()

        db.collection("timings")
            .whereField("teacherEmail", isEqualTo: teacherEmail)
            .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: startOfDay))
            .whereField("date", isLessThan: Timestamp(date: endOfDay))
            .getDocuments { snapshot, error in
                var blocked: Set<Date> = []

                if let documents = snapshot?.documents {
                    for doc in documents {
                        if let startTimestamp = doc["date"] as? Timestamp,
                           let duration = doc["duration"] as? Int {
                            let startDate = startTimestamp.dateValue()
                            let endDate = Calendar.current.date(byAdding: .minute, value: duration, to: startDate)!

                            var current = roundDownToNearest20(startDate)
                            while current < endDate {
                                blocked.insert(current)
                                current = Calendar.current.date(byAdding: .minute, value: 20, to: current)!
                            }
                        }
                    }
                }

                DispatchQueue.main.async {
                    self.bookedTimeSlots = blocked
                    print("Fetched \(snapshot?.documents.count ?? 0) timing entries for \(teacherEmail) on \(selectedDate)")
                    for doc in snapshot?.documents ?? [] {
                        print(">> \(doc.data())")
                    }

                }
            }
    }

    
    private func roundDownToNearest20(_ date: Date) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: date)
        let roundedMinute = (components.minute ?? 0) / 20 * 20
        var newComponents = calendar.dateComponents([.year, .month, .day], from: date)
        newComponents.hour = components.hour
        newComponents.minute = roundedMinute
        newComponents.second = 0
        return calendar.date(from: newComponents)!
    }



    
    private func fetchTeachers() {
        print("Fetching teachers")
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
        print("Handling time slot selection for \(timeString(from: slot))")
        let sortedSlots = selectedTimeSlots.sorted()

        if selectedTimeSlots.contains(slot) {

            let toRemove = sortedSlots.filter { $0 >= slot }
            selectedTimeSlots.subtract(toRemove)
            return
        }

        if sortedSlots.isEmpty {
            selectedTimeSlots.insert(slot)
            return
        }

        guard let minSlot = sortedSlots.first,
              let maxSlot = sortedSlots.last else { return }

        let calendar = Calendar.current
        let prevSlot = calendar.date(byAdding: .minute, value: -20, to: minSlot)!
        let nextSlot = calendar.date(byAdding: .minute, value: 20, to: maxSlot)!

        if slot == prevSlot || slot == nextSlot {
            selectedTimeSlots.insert(slot)
        } else {
            alertMessage = "Please select consecutive time slots only."
            showAlert = true
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
        print("formattimerange called")
        guard let start = selectedTimeSlots.min(), let end = selectedTimeSlots.max() else { return "" }
        let fmt = DateFormatter()
        fmt.timeStyle = .short
        return "\(fmt.string(from: start)) - \(fmt.string(from: Calendar.current.date(byAdding: .minute, value: 20, to: end)!))"
    }
    
    private func submitConsultation() {
        print("submit consultation called")
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
        print("SubmitConsultation called")
        let consult = consultation(
            id: "",
            teacher: teacher,
            date: start,
            comment: comments,
            student: user.email,
            status: nil,
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
                        print("Consultation created successfully!\n\nEmail notification sent to \(teacher.name).")
                        self.selectedTimeSlots.removeAll()
                        self.dismiss()
                    }
                },
                onCancelled: {
                    DispatchQueue.main.async {
                        self.isCreating = false
                        self.alertMessage = "Consultation created, but email notification was not sent."
                        self.showAlert = true
                        print("Consultation created, but email notification was not sent.")
                        self.selectedTimeSlots.removeAll()
                        self.dismiss()
                    }
                }
            )
            
            if !emailSent {
                DispatchQueue.main.async {
                    self.isCreating = false
                    self.alertMessage = "Consultation created, but unable to open email composer."
                    print("Consultation created, but unable to open email composer.")
                    self.showAlert = true
                    self.selectedTimeSlots.removeAll()
                    self.dismiss()
                }
            }
        } else {
            DispatchQueue.main.async {
                self.isCreating = false
                self.alertMessage = "Consultation created.\n\nEmail notifications are unavailable on this device."
                print("Consultation created.\n\nEmail notifications are unavailable on this device.")
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
