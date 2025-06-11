//
//  BookingMain.swift
//  labX-ios
//
//  Created by Avyan Mehra on 11/6/25.
//


import SwiftUI
import FirebaseAuth

struct BookingMain: View {
    @State private var selectedLocation: String = ""
    @State private var selectedTimeSlots: Set<Date> = []
    @State var comment: String = ""
    @StateObject private var userManager = UserManager()
    @State private var showAlert = false
    @State private var alertMessage = ""
    
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
    
    // Generate time slots from 8am to 7pm in 20-minute intervals
    var timeSlots: [Date] {
        let calendar = Calendar.current
        var slots: [Date] = []
        
        // Start at 8am
        var currentDate = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: Date())!
        // End at 7pm
        let endDate = calendar.date(bySettingHour: 19, minute: 0, second: 0, of: Date())!
        
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
        
        // If slot is already selected, remove it and any slots after it
        if selectedTimeSlots.contains(slot) {
            selectedTimeSlots = selectedTimeSlots.filter { selectedSlot in
                selectedSlot < slot
            }
            return
        }
        
        // If no slots are selected, just add this one
        if selectedTimeSlots.isEmpty {
            selectedTimeSlots.insert(slot)
            return
        }
        
        // Get the last selected slot
        guard let lastSelected = selectedTimeSlots.max() else { return }
        
        // Check if the new slot is 20 minutes after the last selected slot
        let nextSlot = calendar.date(byAdding: .minute, value: 20, to: lastSelected)!
        if calendar.isDate(slot, equalTo: nextSlot, toGranularity: .minute) {
            selectedTimeSlots.insert(slot)
        } else {
            // If not consecutive, show alert
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
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Location") {
                    Picker("Select Location", selection: $selectedLocation) {
                        ForEach(locations, id: \.self) { location in
                            Text(location).tag(location)
                        }
                    }
                }
                
                Section("Time Slots") {
                    if !selectedTimeSlots.isEmpty {
                        Text("Selected: \(formatTimeRange())")
                            .foregroundColor(.blue)
                            .padding(.vertical, 4)
                    }
                    
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 60))
                    ], spacing: 10) {
                        ForEach(timeSlots, id: \.self) { slot in
                            Button(action: {
                                handleTimeSlotSelection(slot)
                            }) {
                                Text(timeString(from: slot))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(isTimeSlotSelected(slot) ? Color.blue : Color.gray.opacity(0.2))
                                    .foregroundColor(isTimeSlotSelected(slot) ? .white : .primary)
                                    .cornerRadius(8)
                            }
                            .buttonStyle(PlainButtonStyle())
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
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(selectedLocation.isEmpty || selectedTimeSlots.isEmpty)
            }
            .navigationTitle("Book a lab")
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Booking Status"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .onAppear {
                userManager.fetchUser()
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
        
        // Here you would typically save the booking to your database
        // For now, we'll just show a success message
        alertMessage = "Lab booked successfully for \(selectedLocation) from \(formatTimeRange())"
        showAlert = true
    }
}

#Preview {
    BookingMain()
}
