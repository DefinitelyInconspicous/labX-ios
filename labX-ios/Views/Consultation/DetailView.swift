//
//  RescheduleView.swift
//  labX-ios
//
//  Created by Avyan Mehra on 14/4/25.
//

import SwiftUI
import Forever
import FirebaseFirestore

struct DetailView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var consultationManager = ConsultationManager()
    @State private var showAlert = false
    @State private var alertMessage = ""
    @StateObject private var userManager = UserManager()
    var consultation: consultation
    @Binding var consultations: [consultation]

    var body: some View {
        if let user = userManager.user {
            if user.className == "Staff"  {
                VStack {
                    HStack {
                        Spacer()
                        Button {
                            updateConsultationStatus(consultation, status: "Approved")
                            alertMessage = "Consultation successfully approved"
                            showAlert.toggle()
                        } label: {
                            HStack {
                                Image(systemName: "calendar.badge.checkmark")
                                    .padding()
                                Text("Accept")
                                    .padding()
                                    .font(.headline)
                            }
                        }
                        .buttonBorderShape(.roundedRectangle)
                        .background(.green)
                        .foregroundStyle(.white)
                        .cornerRadius(8)
                        
                        Spacer()
                        
                        Button {
                            updateConsultationStatus(consultation, status: "Declined")
                            alertMessage = "Consultation successfully declined"
                            showAlert.toggle()
                        } label: {
                            HStack {
                                Image(systemName: "calendar.badge.minus")
                                    .padding()
                                Text("Decline")
                                    .padding()
                                    .font(.headline)
                            }
                        }
                        .buttonBorderShape(.roundedRectangle)
                        .background(.red)
                        .foregroundStyle(.white)
                        .cornerRadius(8)
                        Spacer()
                    }
                    .padding(.top, 4)
                    
                    
                    
                    NavigationLink {
                        RescheduleView(consultation: consultation)
                    } label: {
                        HStack {
                            Image(systemName: "calendar.badge.clock")
                                .padding()
                            Text("Reschedule")
                                .padding()
                                .font(.headline)
                        }
                    }
                    .buttonBorderShape(.roundedRectangle)
                    .background(.yellow)
                    .foregroundStyle(.white)
                    .cornerRadius(8)
                }
            }
        }
        
        Form {
            
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
        .onAppear {
            if userManager.user == nil {
                userManager.fetchUser()
            }
        }
        .navigationTitle("Consultation Info")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Status", isPresented: $showAlert, actions: {
            Button("Ok") {}
        }, message: {
            Text(alertMessage)
        })
    }

    func cancelConsultation() {
        consultationManager.deleteConsultation(consultation)
        if let index = consultations.firstIndex(where: { $0.id == consultation.id }) {
            consultations.remove(at: index)
        }
        dismiss()
    }
}

private func updateConsultationStatus(_ consultation: consultation, status: String) {
    let db = Firestore.firestore()
    db.collection("consultations").document(consultation.id.uuidString).updateData([
        "status": status
    ]) { error in
        if let error = error {
            print("Error updating consultation status: \(error.localizedDescription)")
        }
    }
    print("Updated status with \(status)")
}

#Preview {
    DetailView(consultation: consultation(teacher: staff(name: "", email: ""), date: .now, comment: "", student: "", location: ""), consultations: .constant([]))
}
