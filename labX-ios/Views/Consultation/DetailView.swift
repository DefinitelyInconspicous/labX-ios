//
//  DetailView.swift
//  labX-ios
//
//  Created by Avyan Mehra on 14/4/25.
//

import SwiftUI
import Forever
import FirebaseFirestore
import EventKit

struct DetailView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var consultationManager = ConsultationManager()
    @State private var showAlert = false
    @State private var alertMessage = ""
    @StateObject private var userManager = UserManager()
    var consultation: consultation
    @Binding var consultations: [consultation]
    
    @State private var events: [EKEvent] = []
    private let eventStore = EKEventStore()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let user = userManager.user, user.className == "Staff" {
                    VStack {
                        HStack {
                            Button {
                                updateConsultationStatus(status: "Approved")
                            } label: {
                                Label("Accept", systemImage: "calendar.badge.checkmark")
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(.green)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                            
                            Button {
                                updateConsultationStatus(status: "Declined")
                            } label: {
                                Label("Decline", systemImage: "calendar.badge.minus")
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(.red)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                        }
                        .padding()
                        
                        NavigationLink {
                            RescheduleView(consultation: consultation)
                        } label: {
                            Label("Reschedule", systemImage: "calendar.badge.clock")
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(.yellow)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        .padding()
                    }
                }
                
                // Consultation Info
                List {
                    Section(header: Text("Consultation Details")) {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .foregroundColor(.blue)
                            Text(consultation.teacher.name)
                                .font(.headline)
                        }
                        
                        HStack {
                            Image(systemName: "calendar")
                            Text(consultation.date.formatted(date: .long, time: .shortened))
                        }
                        
                        if !consultation.comment.isEmpty {
                            HStack(alignment: .top) {
                                Image(systemName: "text.bubble")
                                Text(consultation.comment)
                            }
                        }
                        
                        Section {
                            Button(role: .destructive) {
                                cancelConsultation()
                            } label: {
                                Label("Cancel Consultation", systemImage: "trash")
                                    .frame(maxWidth: .infinity)
                            }
                        }
                    }
                }
                .frame(height: 300) // Limit list height to avoid scroll conflict
                
                // Calendar View (moved out of List)
                VStack(alignment: .leading, spacing: 10) {
                    Text("Your Calendar")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    if events.isEmpty {
                        Text("No calendar events found for this day.")
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    } else {
                        let timeSlots = [
                            "08:00", "08:15", "08:30", "08:45",
                            "09:00", "09:15", "09:30", "09:45",
                            "10:00", "10:15", "10:30", "10:45",
                            "11:00", "11:15", "11:30", "11:45",
                            "12:00", "12:15", "12:30", "12:45",
                            "13:00", "13:15", "13:30", "13:45",
                            "14:00", "14:15", "14:30", "14:45",
                            "15:00", "15:15", "15:30", "15:45",
                            "16:00", "16:15", "16:30", "16:45",
                            "17:00", "17:15", "17:30", "17:45",
                            "18:00", "18:15", "18:30", "18:45",
                            "19:00"
                        ]
                        
                        let slotDurations: [String: (EKEvent, Int)] = {
                            var map: [String: (EKEvent, Int)] = [:]
                            for event in events {
                                let roundedStart = Calendar.current.date(bySetting: .second, value: 0, of: event.startDate)!
                                let minutes = Calendar.current.component(.minute, from: roundedStart)
                                let roundedMinutes = (minutes / 15) * 15
                                let roundedDate = Calendar.current.date(bySettingHour: Calendar.current.component(.hour, from: roundedStart),
                                                                        minute: roundedMinutes,
                                                                        second: 0,
                                                                        of: roundedStart)!
                                let key = String(format: "%02d:%02d",
                                                 Calendar.current.component(.hour, from: roundedDate),
                                                 Calendar.current.component(.minute, from: roundedDate))
                                let blocks = Int(event.endDate.timeIntervalSince(event.startDate) / 900)
                                map[key] = (event, blocks)
                            }
                            return map
                        }()
                        
                        ScrollView(.horizontal) {
                            HStack(alignment: .top, spacing: 16) {
                                
                                // Time column
                                VStack(alignment: .leading, spacing: 20) {
                                    ForEach(timeSlots, id: \.self) { slot in
                                        Text(slot)
                                            .font(.caption2)
                                            .foregroundColor(.gray)
                                            .frame(height: 24, alignment: .top)
                                    }
                                }
                                
                                // Events column with minWidth to expand
                                VStack(spacing: 0) {
                                    ForEach(timeSlots, id: \.self) { slot in
                                        ZStack(alignment: .topLeading) {
                                            Rectangle()
                                                .fill(Color.gray.opacity(0.1))
                                                .frame(height: 24)
                                            
                                            if let (event, blockCount) = slotDurations[slot] {
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(event.title ?? "No Title")
                                                        .font(.caption)
                                                        .bold()
                                                        .foregroundColor(.white)
                                                    if let location = event.location {
                                                        Text(location)
                                                            .font(.caption2)
                                                            .foregroundColor(.white.opacity(0.8))
                                                    }
                                                }
                                                .padding(6)
                                                .frame(height: CGFloat(blockCount) * 24, alignment: .topLeading)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                .background(Color.blue)
                                                .cornerRadius(6)
                                            }
                                        }
                                    }
                                }
                                .frame(minWidth: 300)
                                
                            }
                            .padding(.horizontal)
                        }
                        
                    }
                }
            }
        }
        .onAppear {
            if userManager.user == nil {
                userManager.fetchUser()
            }
            fetchEventsForConsultationDay()
        }
        .navigationTitle("Consultation Info")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Status", isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    }
    
    // MARK: - Functions
    
    func dateFrom(timeString: String, on baseDate: Date) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let calendar = Calendar.current
        let components = formatter.date(from: timeString).flatMap {
            calendar.dateComponents([.hour, .minute], from: $0)
        }
        return calendar.date(bySettingHour: components?.hour ?? 0,
                             minute: components?.minute ?? 0,
                             second: 0,
                             of: baseDate) ?? baseDate
    }
    
    func cancelConsultation() {
        consultationManager.deleteConsultation(consultation)
        if let index = consultations.firstIndex(where: { $0.id == consultation.id }) {
            consultations.remove(at: index)
        }
        dismiss()
        //delet timings (the cool calendar thing)
        let db = Firestore.firestore()
        
        db.collection("timings")
            .whereField("teacherEmail", isEqualTo: consultation.teacher.email)
            .whereField("date", isEqualTo: consultation.date)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching timing slots: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                for doc in documents {
                    if let timestamp = doc["date"] as? Timestamp {
                        let timingDate = timestamp.dateValue()
                        if Calendar.current.isDate(timingDate, equalTo: consultation.date, toGranularity: .minute) {
                            db.collection("timings").document(doc.documentID).delete { err in
                                if let err = err {
                                    print("Error deleting timing: \(err.localizedDescription)")
                                } else {
                                    print("Timing slot successfully deleted.")
                                }
                            }
                        }
                    }
                }
            }
    }
    
    func updateConsultationStatus(status: String) {
        let db = Firestore.firestore()
        print("Updating Consultation Status")
        db.collection("consultations").document(String(consultation.id)).updateData([
            "status": status
        ]) { error in
            if let error = error {
                print("Error updating consultation status: \(error.localizedDescription)")
            } else {
                alertMessage = "Consultation successfully \(status.lowercased())"
                showAlert = true
            }
        }
    }
    
    func fetchEventsForConsultationDay() {
        eventStore.requestAccess(to: .event) { granted, error in
            guard granted else {
                print("Access to calendar denied: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            let startOfDay = Calendar.current.startOfDay(for: consultation.date)
            let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
            
            let predicate = eventStore.predicateForEvents(withStart: startOfDay, end: endOfDay, calendars: nil)
            let fetchedEvents = eventStore.events(matching: predicate)
            
            let visibleStart = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: startOfDay)!
            let visibleEnd = Calendar.current.date(bySettingHour: 19, minute: 0, second: 0, of: startOfDay)!
            
            let filteredEvents = fetchedEvents.filter { event in
                event.endDate > visibleStart && event.startDate < visibleEnd
            }
            
            DispatchQueue.main.async {
                self.events = filteredEvents.sorted(by: { $0.startDate < $1.startDate })
            }
        }
    }
}
