//
//  LabMain.swift
//  labX-ios
//
//  Created by Avyan Mehra on 15/4/25.
//

import SwiftUI
import Forever

struct Booking {
    var teacher: staff
    var selectedTimeSlots: [String]
    var subject: String
    var lab: String
}



// MARK: - Main View
struct LabMain: View {
    let teacherNames: [staff] = teachers

    let subjects = ["Physics", "Chemistry", "Biology", "Health Science", "Transport Science", "Material Science", "Communication Science"]
    let labs = ["Physics Lab 1", "Communications Lab", "Research Lab", "Bio Lab 1", "Bio Lab 2", "Chem Lab 1", "Chem Lab 2"]

    let timeSlots: [String] = {
        var slots = [String]()
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        var date = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date())!
        let end = Calendar.current.date(bySettingHour: 19, minute: 0, second: 0, of: Date())!
        while date <= end {
            slots.append(formatter.string(from: date))
            date = Calendar.current.date(byAdding: .minute, value: 20, to: date)!
        }
        return slots
    }()

    @State private var selectedTimeSlots: [String] = []
    @State private var selectedDate = Date()
    @State private var selectedTeacher: staff?
    
    @State private var booking = Booking(
        teacher: staff(name: "", email: ""),
        selectedTimeSlots: [],
        subject: "Physics",
        lab: "Physics Lab 1"
    )

    var body: some View {
        NavigationView {
            Form {
                
                Section(header: Text("Staff")) {
                    Picker("Select Staff", selection: Binding<staff>(
                        get: { selectedTeacher ?? teacherNames.first! },
                        set: { newTeacher in
                            selectedTeacher = newTeacher
                            booking.teacher = newTeacher
                        })) {
                        ForEach(teacherNames) { teacher in
                            Text(teacher.name).tag(teacher)
                        }
                    }
                }

                Section(header: Text("Time Slots")) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 5) {
                        ForEach(timeSlots, id: \.self) { slot in
                            Button(action: {
                                if selectedTimeSlots.contains(slot) {
                                    selectedTimeSlots.remove(slot)
                                } else {
                                    selectedTimeSlots.insert(slot)
                                }
                            }) {
                                Text(slot)
                                    .font(.system(size: 12))
                                    .padding(8)
                                    .frame(maxWidth: .infinity)
                                    .background(selectedTimeSlots.contains(slot) ? Color.blue.opacity(0.7) : Color.gray.opacity(0.2))
                                    .foregroundColor(selectedTimeSlots.contains(slot) ? .white : .primary)
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                .onChange(of: selectedTimeSlots) { newSelection in
                    booking.selectedTimeSlots = Array(newSelection).sorted()
                }



                // Subject Picker
                Section(header: Text("Subject")) {
                    Picker("Subject", selection: $booking.subject) {
                        ForEach(subjects, id: \.self) {
                            Text($0)
                        }
                    }
                }

                // Lab Picker
                Section(header: Text("Lab")) {
                    Picker("Lab", selection: $booking.lab) {
                        ForEach(labs, id: \.self) {
                            Text($0)
                        }
                    }
                }

                // Summary
                Section(header: Text("Summary")) {
                    Text("Teacher: \(booking.teacher.name)")
                    Text("Email: \(booking.teacher.email)")
                    Text("Subject: \(booking.subject)")
                    Text("Lab: \(booking.lab)")
                    Text("Time Slots: \(booking.selectedTimeSlots.joined(separator: ", "))")
                }
            }
            .navigationTitle("Book a Lab")
        }
    }
}

#Preview {
    LabMain()
}
