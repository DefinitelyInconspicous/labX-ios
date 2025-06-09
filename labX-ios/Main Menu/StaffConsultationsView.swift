//
//  StaffConsultationsView.swift
//  labX-ios
//
//  Created by Avyan Mehra on 5/6/25.
//


import SwiftUI

struct StaffConsultationsView: View {
    var staff: staff
    @Binding var consultations: [consultation]
    @State private var statuses: [UUID: String] = [:]

    var body: some View {
        NavigationStack {
            List {
                ForEach(consultations.filter { $0.teacher.id == staff.id }) { consult in
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Student Comment: \(consult.comment)")
                        Text("Date: \(consult.date.formatted(date: .abbreviated, time: .shortened))")
                        HStack {
                            Button("Yes") {
                                statuses[consult.id] = "Yes"
                            }
                            .foregroundColor(statuses[consult.id] == "Yes" ? .green : .primary)
                            Button("No") {
                                statuses[consult.id] = "No"
                            }
                            .foregroundColor(statuses[consult.id] == "No" ? .red : .primary)
                            Button("Reschedule") {
                                statuses[consult.id] = "Reschedule"
                            }
                            .foregroundColor(statuses[consult.id] == "Reschedule" ? .orange : .primary)
                        }
                        if let status = statuses[consult.id] {
                            Text("Status: \(status)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Your Bookings")
        }
    }
}