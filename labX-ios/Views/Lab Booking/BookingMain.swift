//
//  BookingMain.swift
//  labX-ios
//
//  Created by Avyan Mehra on 11/6/25.
//


import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct BookingMain: View {
    @State private var selectedLocation: String = ""
    @State private var selectedTimeSlots: Set<Date> = []
    @State var comment: String = ""
    @StateObject private var userManager = UserManager()
    @State private var showAlert = false
    @State private var alertMessage = ""
    private let db = Firestore.firestore()
    @State private var selectedDate: Date = Date()
    @State private var bookedTimeSlots: Set<Date> = []
    private let sheetsManager = GoogleSheetsManager(
    sheetId: "1PXCmKQf9FSlyW89XZBNAFAgVI4XVLRYEJRUwRP0E42E",
    serviceAccountFileName: "labx-sheets-service-account"
)
    let locations: [String] = [
        "Physics lab 1",
        "Engineering Lab",
        "Research Lab",
        "Electronics Lab",
        "Biotech Lab 1",
        "Biotech Lab 2",
        "Chemistry Lab 1",
        "Chemistry Lab 2",
        "Biology Lab 1",
        "Biology Lab 2",
        "R&E Lab"
    ]
    
    
    var timeSlots: [Date] {
        var slots: [Date] = []
        let calendar = Calendar(identifier: .gregorian)
        var components = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        let utc8 = TimeZone(secondsFromGMT: 8 * 3600)!
        components.timeZone = utc8

        
        components.hour = 8
        components.minute = 0
        components.second = 0
        guard var currentDate = calendar.date(from: components) else { return [] }

        
        components.hour = 19
        components.minute = 0
        guard let endDate = calendar.date(from: components) else { return [] }

        while currentDate <= endDate {
            slots.append(currentDate)
            currentDate = calendar.date(byAdding: .minute, value: 20, to: currentDate)!
        }

        return slots
    }
    
    private func isTimeSlotSelected(_ slot: Date) -> Bool {
        selectedTimeSlots.contains(slot)
    }
    
    private func handleTimeSlotSelection(_ slot: Date) {
        let calendar = Calendar.current
        
 
        if selectedTimeSlots.contains(slot) {
            selectedTimeSlots = selectedTimeSlots.filter { selectedSlot in
                selectedSlot < slot
            }
            return
        }
        

        if selectedTimeSlots.isEmpty {
            selectedTimeSlots.insert(slot)
            return
        }
        

        guard let lastSelected = selectedTimeSlots.max() else { return }

        let nextSlot = calendar.date(byAdding: .minute, value: 20, to: lastSelected)!
        if calendar.isDate(slot, equalTo: nextSlot, toGranularity: .minute) {
            selectedTimeSlots.insert(slot)
        } else {
            alertMessage = "Please select consecutive time slots"
            showAlert = true
        }
    }
    
    private func formatTimeRange() -> String {
        guard let first = selectedTimeSlots.min(),
              let last = selectedTimeSlots.max() else {
            return ""
        }
        
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "\(formatter.string(from: first)) - \(formatter.string(from: last))"
    }
    
    private func fetchBookedSlots() {
        guard !selectedLocation.isEmpty else {
            bookedTimeSlots = []
            return
        }
        let calendar = Calendar(identifier: .gregorian)
        let utc8 = TimeZone(secondsFromGMT: 8 * 3600)!
        var startOfDayComponents = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        startOfDayComponents.timeZone = utc8
        startOfDayComponents.hour = 0
        startOfDayComponents.minute = 0
        startOfDayComponents.second = 0
        guard let startOfDay = calendar.date(from: startOfDayComponents) else { return }
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return }

        db.collection("bookings")
            .whereField("location", isEqualTo: selectedLocation)
            .whereField("timeStart", isGreaterThanOrEqualTo: Timestamp(date: startOfDay))
            .whereField("timeStart", isLessThan: Timestamp(date: endOfDay))
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching bookings: \(error.localizedDescription)")
                    bookedTimeSlots = []
                    return
                }
                guard let documents = snapshot?.documents else {
                    bookedTimeSlots = []
                    return
                }
                var slots: Set<Date> = []
                for doc in documents {
                    if let start = (doc.data()["timeStart"] as? Timestamp)?.dateValue(),
                       let end = (doc.data()["timeEnd"] as? Timestamp)?.dateValue() {
                        print("Fetched booking: \(start) to \(end)")
                        var slot = start
                        while slot <= end {
                            slots.insert(slot)
                            slot = calendar.date(byAdding: .minute, value: 20, to: slot)!
                        }
                    }
                }
                bookedTimeSlots = slots
            }
    }
    

    private func isSlotBooked(_ slot: Date) -> Bool {
        let calendar = Calendar(identifier: .gregorian)
        let utc8 = TimeZone(secondsFromGMT: 8 * 3600)!
        let slotComponents = calendar.dateComponents(in: utc8, from: slot)
        for booked in bookedTimeSlots {
            let bookedComponents = calendar.dateComponents(in: utc8, from: booked)
            if slotComponents.year == bookedComponents.year &&
                slotComponents.month == bookedComponents.month &&
                slotComponents.day == bookedComponents.day &&
                slotComponents.hour == bookedComponents.hour &&
                slotComponents.minute == bookedComponents.minute {
                print("Slot is booked!")
                return true
            }
        }
        return false
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Date") {
                    DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
                        .onChange(of: selectedDate) { _ in
                            fetchBookedSlots()
                        }
                }
                Section("Location") {
                    Picker("Select Location", selection: $selectedLocation) {
                        ForEach(locations, id: \.self) { location in
                            Text(location).tag(location)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                    }
                    .onChange(of: selectedLocation) { _ in
                        fetchBookedSlots()
                    }
                }
                
                Section("Time Slots") {
                    if !selectedTimeSlots.isEmpty {
                        Text("Selected: \(formatTimeRange())")
                            .foregroundColor(.blue)
                            .padding(.vertical, 4)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 60))
                    ], spacing: 10) {
                        ForEach(timeSlots, id: \.self) { slot in
                            let isBooked = isSlotBooked(slot)
                            let isSelected = isTimeSlotSelected(slot)
                            
                            Button(action: {
                                if !isBooked {
                                    handleTimeSlotSelection(slot)
                                }
                            }) {
                                Text(timeString(from: slot))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .modifier(TimeSlotAppearance(isSelected: isSelected, isBooked: isBooked))
                                    .cornerRadius(8)
                                    .foregroundColor(isSelected ? .white : (isBooked ? .gray : .primary))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .modifier(GlassEffectIfAvailableRounded(cornerRadius: 8))
                            .disabled(isBooked)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section("Comments") {
                    TextField("Add any additional notes...", text: $comment, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Button(action: submitBooking) {
                    Text("Book Lab")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .disabled(selectedLocation.isEmpty || selectedTimeSlots.isEmpty)
            }
            .navigationTitle("Book a lab")
            .scrollDismissesKeyboard(.interactively)
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Booking Status"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .onAppear {
                userManager.fetchUser()
                fetchBookedSlots()
            }
        }
    }
    
    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func submitBooking() {
        guard let user = userManager.user else {
            alertMessage = "Please log in to book a lab"
            showAlert = true
            return
        }
        
        guard !selectedTimeSlots.isEmpty else {
            alertMessage = "Please select at least one time slot"
            showAlert = true
            return
        }
        
        // Combine selectedDate with each selected time slot's time
        let calendar = Calendar.current
        let sortedSlots = selectedTimeSlots.sorted()
        guard let minSlot = sortedSlots.first, let maxSlot = sortedSlots.last else { return }
        
        func combine(date: Date, time: Date) -> Date {
            let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
            let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: time)
            var combined = DateComponents()
            combined.year = dateComponents.year
            combined.month = dateComponents.month
            combined.day = dateComponents.day
            combined.hour = timeComponents.hour
            combined.minute = timeComponents.minute
            combined.second = timeComponents.second
            return calendar.date(from: combined) ?? date
        }
        
        let timeStart = combine(date: selectedDate, time: minSlot)
        let timeEnd = combine(date: selectedDate, time: maxSlot)
        
        let utc8 = TimeZone(secondsFromGMT: 8 * 3600)!
        let timeStartUTC8 = Calendar.current.date(byAdding: .second, value: utc8.secondsFromGMT(for: timeStart) - TimeZone.current.secondsFromGMT(for: timeStart), to: timeStart) ?? timeStart
        let timeEndUTC8 = Calendar.current.date(byAdding: .second, value: utc8.secondsFromGMT(for: timeEnd) - TimeZone.current.secondsFromGMT(for: timeEnd), to: timeEnd) ?? timeEnd
        
        let booking = [
            "location": selectedLocation,
            "timeStart": Timestamp(date: timeStartUTC8),
            "timeEnd": Timestamp(date: timeEndUTC8),
            "comment": comment,
            "staff": "\(user.firstName) \(user.lastName)",
            "createdAt": Timestamp()
        ] as [String : Any]
        
        db.collection("bookings").addDocument(data: booking) { error in
            if let error = error {
                alertMessage = "Error booking lab: \(error.localizedDescription)"
                showAlert = true
            } else {

                let locationForSheet = selectedLocation
                let commentForSheet = comment
                let teacherName = "\(user.firstName) \(user.lastName)"
                let timeSlotsArray = sortedSlots
                

                selectedLocation = ""
                selectedTimeSlots.removeAll()
                comment = ""
                
                print("Calling GoogleSheetsManager.updateSheet with location: \(locationForSheet), comment: \(commentForSheet)")
                sheetsManager.updateSheet(
                    date: selectedDate,
                    timeSlots: timeSlotsArray,
                    teacherName: teacherName,
                    comment: commentForSheet,
                    sheetName: locationForSheet
                ) { result in
                    DispatchQueue.main.async {
                        switch result {
                        case .success:
                            alertMessage = "Lab booked and Google Sheet updated!"
                            showAlert = true
                        case .failure(let error):
                            alertMessage = "Lab booked, but failed to update Google Sheet: \(error.localizedDescription)"
                            showAlert = true
                        }
                        
                    }
                }
            }
        }
    }
}


private struct GlassEffectIfAvailableRounded: ViewModifier {
    var cornerRadius: CGFloat
    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content.glassEffect(.regular.interactive())
        } else {
            content
        }
    }
}

private struct TimeSlotAppearance: ViewModifier {
    var isSelected: Bool
    var isBooked: Bool
    
    func body(content: Content) -> some View {
        let selectedColor: Color = .blue
        let bookedColor: Color = Color.gray.opacity(0.5)
        let normalColor: Color = Color.gray.opacity(0.2)
        
        if #available(iOS 26, *) {
            let tintColor: Color = isSelected ? selectedColor : (isBooked ? bookedColor : normalColor)
            content
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .glassEffect(.regular.interactive().tint(tintColor))
        } else {
            content
                .background(isSelected ? selectedColor : (isBooked ? bookedColor : normalColor))
        }
    }
}

#Preview {
    BookingMain()
}
