//
//  StaffConsultationsView.swift
//  labX-ios
//
//  Created by Avyan Mehra on 5/6/25.
//


import SwiftUI
import FirebaseFirestore

struct StaffConsultationsView: View {
    var staff: staff
    @Binding var consultations: [consultation]
    @StateObject private var consultationManager = ConsultationManager()
    @State private var statuses: [UUID: String] = [:]
    @State private var createConsult: Bool = false
    @StateObject private var userManager = UserManager()
    @State private var showPast = false
    
    private let db = Firestore.firestore()
    
    var body: some View {
        VStack {
            if consultationManager.consultations.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    Text("No consultations yet")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.gray)
                    Spacer()
                }
            } else {
                List {
                    // Upcoming Section
                    Section(header: Text("Upcoming Consultations")) {
                        let upcoming = consultationManager.consultations.filter { $0.date > Date() }
                        if upcoming.isEmpty {
                            Text("No upcoming consultations")
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(upcoming) { consult in
                                NavigationLink(destination: DetailView(consultation: consult, consultations: $consultations)) {
                                    ConsultationTile(consult)
                                }
                            }
                        }
                    }
                    Section {
                        DisclosureGroup(isExpanded: $showPast) {
                            let past = consultationManager.consultations.filter { $0.date <= Date() }
                            if past.isEmpty {
                                Text("No past consultations")
                                    .foregroundColor(.secondary)
                            } else {
                                ForEach(past) { consult in
                                    NavigationLink(destination: DetailView(consultation: consult, consultations: $consultations)) {
                                        ConsultationTile(consult)
                                    }
                                }
                            }
                        } label: {
                            HStack {
                                Image(systemName: "archivebox.fill")
                                    .padding()
                                    .imageScale(.large)
                                Text("Past Consultations")
                                    .font(.headline)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Your Bookings")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    createConsult = true
                }) {
                    Image(systemName: "plus")
                        .imageScale(.large)
                        .fontWeight(.heavy)
                }
            }
            
            if let user = userManager.user {
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink(destination: ProfileView(user: user)) {
                        Image(systemName: "person.crop.circle")
                            .imageScale(.large)
                    }
                }
            }
        }
        .sheet(isPresented: $createConsult) {
            ConsultCreate(consultations: $consultationManager.consultations)
        }
        .onAppear {
            consultationManager.fetchTeacherConsultations(forTeacher: staff.email)
            if userManager.user == nil {
                userManager.fetchUser()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                loadConsultationStatuses()
            }
        }
    }
    
    private func ConsultationTile(_ consultation: consultation) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(consultation.teacher.name)
                    .font(.headline)
                Spacer()
                Text(statusText(for: consultation.status))
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(statusColor(for: consultation.status))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor(for: consultation.status).opacity(0.1))
                    .cornerRadius(8)
            }
            
            Text("Date: \(consultation.date.formatted(date: .abbreviated, time: .shortened))")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("Location: \(consultation.location)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if !consultation.comment.isEmpty {
                Text("Comment: \(consultation.comment)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
    private func statusText(for status: String?) -> String {
        guard let status = status else { return "Pending" }
        switch status.lowercased() {
        case "approved": return "Confirmed"
        case "denied": return "Declined"
        case "reschedule": return "Reschedule"
        default: return "Pending"
        }
    }
    private func statusColor(for status: String?) -> Color {
        switch status {
        case "Approved":
            return .green
        case "Declined":
            return .red
        default:
            return .yellow
        }
    }

    
    private func loadConsultationStatuses() {
        for consult in consultationManager.consultations {
            db.collection("consultations").document(consult.id.uuidString).getDocument { document, error in
                if let document = document, document.exists,
                   let status = document.data()?["status"] as? String {
                    statuses[consult.id] = status
                }
            }
        }
    }

}



