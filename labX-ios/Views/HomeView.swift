//
//  HomeView.swift
//  labX-ios
//
//  Created by Dhanush on 19/6/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseCore
import FirebaseFirestore

//i am FAR too lazy to leave comments

class ConsultationViewModel: ObservableObject {
    @Published var consultations: [consultation] = []
    @Published var fetchError: Bool = false
    @Published var isLoaded: Bool = false
    
    var upcomingConsultations: [consultation] {
        consultations
            .filter { $0.date >= Date() }
            .sorted { $0.date < $1.date }
    }
    
    var pastConsultations: [consultation] {
        consultations
            .filter { $0.date < Date() }
            .sorted { $0.date > $1.date }
    }
    
    private let db = Firestore.firestore()
    
    func fetchConsultations(for studentEmail: String) {
        db.collection("consultations")
            .whereField("student", isEqualTo: studentEmail)
            .getDocuments { snapshot, error in
                DispatchQueue.main.async {
                    self.isLoaded = true
                    
                    if let error = error {
                        print("Error fetching consultations: \(error)")
                        self.fetchError = true
                        return
                    }
                    
                    self.consultations = snapshot?.documents.compactMap { doc in
                        let data = doc.data()
                        guard let teacherName = data["teacherName"] as? String,
                              let teacherEmail = data["teacherEmail"] as? String,
                              let date = (data["date"] as? Timestamp)?.dateValue(),
                              let location = data["location"] as? String,
                              let comment = data["comment"] as? String,
                              let student = data["student"] as? String else {
                            return nil
                        }
                        let teacher = staff(name: teacherName, email: teacherEmail)
                        return consultation(
                            id: doc.documentID,
                            teacher: teacher,
                            date: date,
                            comment: comment,
                            student: student,
                            status: data["status"] as? String,
                            location: location
                        )
                    } ?? []
                    
                    self.fetchError = false
                }
            }
    }
}

struct HomeView: View {
    @StateObject private var viewModel = ConsultationViewModel()
    @State private var showPast = false
    
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
        guard let status = status else { return .orange }
        switch status.lowercased() {
        case "approved": return .green
        case "denied": return .red
        case "reschedule": return .yellow
        default: return .orange
        }
    }
    
    private func consultationRow(_ consultation: consultation) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(consultation.teacher.name)
                    .font(.headline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Spacer()
                Text(statusText(for: consultation.status))
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(statusColor(for: consultation.status))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor(for: consultation.status).opacity(0.1))
                    .cornerRadius(8)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            HStack {
                Image(systemName: "calendar")
                Text("\(consultation.date.formatted(date: .abbreviated, time: .shortened))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            HStack {
                Image(systemName: "location")
                Text("\(consultation.location)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            HStack {
                if !consultation.comment.isEmpty {
                    Image(systemName: "message")
                    Text("\(consultation.comment)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    var body: some View {
        List {
            Section(header: Text("Upcoming Consultations")) {
                if !viewModel.isLoaded {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Loading consultations...")
                            .foregroundColor(.secondary)
                    }
                } else if viewModel.fetchError {
                    Label("Error fetching consultations", systemImage: "exclamationmark.triangle")
                        .foregroundColor(.red)
                } else if viewModel.upcomingConsultations.isEmpty {
                    Label("No upcoming consultations", systemImage: "calendar.badge.exclamationmark")
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                } else {
                    ForEach(viewModel.upcomingConsultations) { consultation in
                        NavigationLink(destination: DetailView(consultation: consultation, consultations: $viewModel.consultations)) {
                            consultationRow(consultation)
                        }
                    }
                }
            }
            
            Section {
                DisclosureGroup(isExpanded: $showPast) {
                    if viewModel.pastConsultations.isEmpty {
                        Text("No past consultations")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(viewModel.pastConsultations) { consultation in
                            NavigationLink(destination: DetailView(consultation: consultation, consultations: $viewModel.consultations)) {
                                consultationRow(consultation)
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
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                }
            }
        }
        .navigationTitle("Home")
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .onAppear {
            if let email = Auth.auth().currentUser?.email {
                viewModel.fetchConsultations(for: email)
            } else {
                viewModel.fetchError = true
                viewModel.isLoaded = true
            }
        }
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
}
