//
//  ConsultationScheduler.swift
//  labX-ios
//
//  Created by Avyan Mehra on 2/7/25.
//


import SwiftUI
import EventKit
import FirebaseFirestore
import PhotosUI

struct ConsultationScheduler: View {
    enum UploadType: String, CaseIterable, Identifiable {
        case image = "Image"
        case file = "File"
        var id: String { rawValue }
    }

    @State private var uploadType: UploadType = .image
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
    @State private var quotaExceeded = false
    @State private var quotaJustification = ""
    @State private var blackoutActive = false
    @State private var selectedTopic: String = ""
    @State private var selectedAssignment: String = ""
    @State private var prepMaterialUrls: [String] = []
    @State private var showReflectionPrompt = false
    @State private var reflectionResponse = ""
    @State private var selectedPickerItem: PhotosPickerItem? = nil
    @State private var selectedImage: UIImage? = nil
    @State private var selectedFileUrl: URL? = nil
    @State private var selectedFileName: String? = nil
    @State private var selectedFileType: String? = nil
    @State private var showDocumentPicker: Bool = false
    @State private var filePickerResult: Result<Data, Error>? = nil
    @Environment(\.dismiss) private var dismiss
    let topics = ["Physics", "Chemistry", "Biology", "Other"]
    let assignments = ["Homework", "Coursework/PT", "Revision", "Other"]
    
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
                    if let quota = consultationManager.quotaStatus {
                        HStack {
                            Text("Quota: \(quota.used)/\(quota.limit)")
                                .font(.caption)
                                .foregroundColor(quota.used < quota.limit ? .green : .red)
                            Spacer()
                            if quota.used >= quota.limit {
                                Text("Approval required")
                                    .font(.caption2)
                                    .foregroundColor(.red)
                            }
                        }
                    } else {
                        Text("Loading quota...")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                Section {
                    Picker("Upload Type", selection: $uploadType) {
                        Text("Image").tag(UploadType.image)
                        Text("File").tag(UploadType.file)
                    }
                    .pickerStyle(.segmented)
                    .padding(.bottom, 4)
                    
                    if uploadType == .image {
                        PhotosPicker(selection: $selectedPickerItem, matching: .images, photoLibrary: .shared()) {
                            Text("Upload Image")
                        }
                        .onChange(of: selectedPickerItem) { newItem in
                            guard let item = newItem else { return }
                            item.loadTransferable(type: Data.self) { result in
                                switch result {
                                case .success(let data):
                                    if let data = data, let image = UIImage(data: data) {
                                        let resized = resizedImage(image, maxDimension: 800)
                                        self.selectedImage = resized
                                        if let compressedData = resized.jpegData(compressionQuality: 0.4) {
                                            if compressedData.count < 1024 * 1024 {
                                                let base64 = compressedData.base64EncodedString()
                                                self.prepMaterialUrls.append("image|" + base64)
                                            } else {
                                                self.alertMessage = "Image too large. Please select a smaller image (<1MB)."
                                                self.showAlert = true
                                            }
                                        }
                                    }
                                case .failure:
                                    break
                                }
                            }
                        }
                    } else if uploadType == .file {
                        Button("Upload File") {
                            showDocumentPicker = true
                        }
                        .fileImporter(isPresented: $showDocumentPicker, allowedContentTypes: [.pdf, .plainText, .rtf], allowsMultipleSelection: false) { result in
                            switch result {
                            case .success(let urls):
                                guard let url = urls.first else { return }
                                selectedFileUrl = url
                                selectedFileName = url.lastPathComponent
                                selectedFileType = url.pathExtension
                                do {
                                    let fileData = try Data(contentsOf: url)
                                    if fileData.count < 1024 * 1024 {
                                        let base64 = fileData.base64EncodedString()
                                        let meta = "file|" + (selectedFileName ?? "") + "|" + (selectedFileType ?? "") + "|" + base64
                                        self.prepMaterialUrls.append(meta)
                                    } else {
                                        self.alertMessage = "File too large. Please select a file <1MB."
                                        self.showAlert = true
                                    }
                                } catch {
                                    self.alertMessage = "Failed to read file."
                                    self.showAlert = true
                                }
                            case .failure:
                                self.alertMessage = "Failed to select file."
                                self.showAlert = true
                            }
                        }
                    }
                    if prepMaterialUrls.isEmpty {
                        Text("Prep material required before submitting.")
                            .foregroundColor(.orange)
                    } else {
                        ForEach(prepMaterialUrls, id: \.self) { item in
                            if item.hasPrefix("image|") {
                                let base64 = String(item.dropFirst(6))
                                if let data = Data(base64Encoded: base64), let uiImage = UIImage(data: data) {
                                    VStack {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(height: 120)
                                            .cornerRadius(10)
                                        Button("Remove") {
                                            if let idx = prepMaterialUrls.firstIndex(of: item) {
                                                prepMaterialUrls.remove(at: idx)
                                            }
                                        }
                                        .foregroundColor(.red)
                                    }
                                }
                            } else if item.hasPrefix("file|") {
                                let parts = item.split(separator: "|", maxSplits: 3)
                                if parts.count == 4 {
                                    let filename = String(parts[1])
                                    let filetype = String(parts[2])
                                    VStack {
                                        HStack {
                                            Image(systemName: "doc.fill")
                                                .foregroundColor(.blue)
                                            Text("\(filename) (\(filetype))")
                                                .font(.subheadline)
                                                .foregroundColor(.primary)
                                        }

                                        Button("Remove") {
                                            if let idx = prepMaterialUrls.firstIndex(of: item) {
                                                prepMaterialUrls.remove(at: idx)
                                            }
                                        }
                                        .foregroundColor(.red)
                                    }
                                }
                            }
                        }
                    }
                }
                Section("Topic") {
                    Picker("Select Topic", selection: $selectedTopic) {
                        ForEach(topics, id: \.self) { topic in
                            Text(topic).tag(topic as String)
                        }
                    }
                    
                    Picker("Link Assignment", selection: $selectedAssignment) {
                        ForEach(assignments, id: \.self) { assignment in
                            Text(assignment).tag(assignment as String)
                        }
                    }
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
                            Text(location).tag(location as String)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                    }
                }
                
                Section("Comments") {
                    TextField("I would like to discuss...", text: $comments)
                }
                if consultationManager.quotaStatus?.used ?? 0 >= consultationManager.quotaStatus?.limit ?? 3 {
                    Section("Justification for Approval") {
                        TextField("Why do you need this extra consult?", text: $quotaJustification)
                    }
                }
                Section {
                    Button("Confirm Consultation", action: submitConsultation)
                        .disabled(!canSubmitConsult())
                }
            }
            .navigationTitle("Schedule Consultation")
            .onAppear {
                userManager.fetchUser()
                fetchTeachers()
                if let email = userManager.user?.email {
                    consultationManager.fetchQuota(forStudent: email) { quota in
                        consultationManager.quotaStatus = quota
                        quotaExceeded = (quota?.used ?? 0) >= (quota?.limit ?? 3)
                    }
                }
                consultationManager.isBlackoutActive(date: selectedDate) { active in
                    blackoutActive = active
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Consultation"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
            .sheet(isPresented: $showReflectionPrompt) {
                VStack {
                    Text("Reflection Prompt")
                        .font(.headline)
                    TextField("What did you learn from this consult?", text: $reflectionResponse)
                        .padding()
                    Button("Submit Reflection") {
                        // TODO: Save reflectionResponse to consult record
                        showReflectionPrompt = false
                        dismiss()
                    }
                }
                .padding()
            }
        }
    }
    private var canSubmit: Bool {
        selectedTeacher != nil && !selectedTimeSlots.isEmpty && !comments.isEmpty && !selectedLocation.isEmpty
    }
    private func canSubmitConsult() -> Bool {
        guard let quota = consultationManager.quotaStatus else { return false }
        if blackoutActive { return false }
        if prepMaterialUrls.isEmpty { return false }
        if selectedTeacher == nil || selectedTopic.isEmpty || selectedLocation.isEmpty || selectedTimeSlots.isEmpty || comments.isEmpty { return false }
        if quota.used >= quota.limit && quotaJustification.isEmpty { return false }
        return true
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
            location: selectedLocation,
            topic: selectedTopic,
            assignmentId: selectedAssignment,
            prepMaterialUrls: prepMaterialUrls,
            approvalStatus: quotaExceeded ? "pending" : "",
            justification: quotaExceeded ? quotaJustification : "",
            outcomeTags: nil,
            summary: nil,
            reflectionPrompt: "What did you learn from this consult?",
            reflectionResponse: nil,
            auditTrail: [AuditLog(actorID: user.email, action: "created", targetID: "", timestamp: Date(), role: user.className)],
            schoolId: nil
        )
        if quotaExceeded {
            consultationManager.submitApprovalRequest(for: consult, justification: quotaJustification) { success in
                alertMessage = success ? "Approval request submitted." : "Failed to submit approval request."
                showAlert = true
            }
        } else {
            consultationManager.addConsultation(consult) { success in
                alertMessage = success ? "Consultation created successfully!" : "Failed to create consultation."
                showAlert = true
                if success {
                    showReflectionPrompt = true
                }
            }
        }

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

private func resizedImage(_ image: UIImage, maxDimension: CGFloat = 800) -> UIImage {
    let size = image.size
    let aspectRatio = size.width / size.height
    var newSize: CGSize
    if aspectRatio > 1 {
        newSize = CGSize(width: maxDimension, height: maxDimension / aspectRatio)
    } else {
        newSize = CGSize(width: maxDimension * aspectRatio, height: maxDimension)
    }
    UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
    image.draw(in: CGRect(origin: .zero, size: newSize))
    let resized = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return resized ?? image
}
