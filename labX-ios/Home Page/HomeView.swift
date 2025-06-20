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

struct Consultation: Identifiable {
    let id: String
    let consultant: String
    let date: Date
    let location: String
    let status: String
}

class ConsultationViewThingIdk: ObservableObject {
    @Published var consultations: [Consultation] = []
    @Published var fetchError: Bool = false
    @Published var isLoaded: Bool = false
    
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
                        let consultant = data["teacherName"] as? String ?? "Unknown"
                        let date = (data["date"] as? Timestamp)?.dateValue() ?? Date()
                        let location = data["location"] as? String ?? "Unknown"
                        let status = data["status"] as? String ?? "pending"
                        
                        return Consultation(id: doc.documentID,
                                            consultant: consultant,
                                            date: date,
                                            location: location,
                                            status: status)
                    } ?? []
                    
                    self.fetchError = false
                }
            }
    }
}


struct HomeView: View {
    @StateObject private var stuffToShow = ConsultationViewThingIdk()
    
    private func statusText(for status: String) -> String {
        switch status.lowercased() {
        case "yes":
            return "Confirmed"
        case "reschedule":
            return "Reschedule"
        default:
            return "Pending"
        }
    }
    
    private func statusColour(for status: String) -> Color {
        switch status.lowercased() {
        case "yes":
            return .green
        case "reschedule":
            return .yellow
        default:
            return .red
        }
    }

    
    var body: some View {
        List {
            Section(header: Text("Upcoming")) {
                if stuffToShow.fetchError {
                    Text("Error fetching consultations, please try again")
                        .foregroundColor(.red)
                } else if stuffToShow.isLoaded && stuffToShow.consultations.isEmpty {
                    Text("No consultations")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(stuffToShow.consultations) { consultation in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(consultation.consultant)
                                .font(.headline)
                            Text("Date: \(consultation.date.formatted(date: .long, time: .shortened))")
                            Text("Location: \(consultation.location)")
                                .foregroundStyle(.secondary)
                            
                            Text(statusText(for: consultation.status))
                                .foregroundColor(statusColour(for: consultation.status))
                                .bold()
                        }
                        .padding(.vertical, 5)
                    }
                }
            }
        }
        .onAppear {
            if let email = Auth.auth().currentUser?.email {
                stuffToShow.fetchConsultations(for: email)
            } else {
                print("No logged-in user")
                stuffToShow.fetchError = true
                stuffToShow.isLoaded = true
            }
        }
    }
}


#Preview {
    HomeView()
}
