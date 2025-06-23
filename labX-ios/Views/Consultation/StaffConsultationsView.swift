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
                                ConsultationTile(consult: consult)
                            }
                        }
                    }

                    // Past Section with Disclosure
                    Section {
                        DisclosureGroup(isExpanded: $showPast) {
                            let past = consultationManager.consultations.filter { $0.date <= Date() }
                            if past.isEmpty {
                                Text("No past consultations")
                                    .foregroundColor(.secondary)
                            } else {
                                ForEach(past) { consult in
                                    ConsultationTile(consult: consult)
                                }
                            }
                        } label: {
                            Text("Past Consultations")
                                .font(.headline)
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

    private func ConsultationTile(consult: consultation) -> some View {
        NavigationLink {
            VStack(alignment: .leading, spacing: 12) {
                Text("Student: \(consult.student)")
                    .font(.headline)
                Text("Student Comment: \(consult.comment)")
                    .font(.subheadline)
                Text("Date: \(consult.date.formatted(date: .abbreviated, time: .shortened))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Divider()

                HStack(spacing: 16) {
                    Button(action: {
                        updateConsultationStatus(consult, status: "Yes")
                    }) {
                        Text("Accept")
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(statuses[consult.id] == "Yes" ? Color.green : Color.gray)
                            .cornerRadius(8)
                    }

                    Button(action: {
                        updateConsultationStatus(consult, status: "No")
                    }) {
                        Text("Decline")
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(statuses[consult.id] == "No" ? Color.red : Color.gray)
                            .cornerRadius(8)
                    }

                    Button(action: {
                        updateConsultationStatus(consult, status: "Reschedule")
                    }) {
                        Text("Reschedule")
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(statuses[consult.id] == "Reschedule" ? Color.orange : Color.gray)
                            .cornerRadius(8)
                    }
                }

                if let status = statuses[consult.id] {
                    Text("Status: \(status)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
            }
            .padding()
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                Text(consult.student)
                    .font(.headline)
                    .foregroundColor(.primary)
                Text(consult.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
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

    private func updateConsultationStatus(_ consultation: consultation, status: String) {
        statuses[consultation.id] = status
        db.collection("consultations").document(consultation.id.uuidString).updateData([
            "status": status
        ]) { error in
            if let error = error {
                print("Error updating consultation status: \(error.localizedDescription)")
            }
        }
    }
}
