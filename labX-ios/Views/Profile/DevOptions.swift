//
//  DevOptions.swift
//  labX-ios
//
//  Created by Avyan Mehra on 11/9/25.
//

import SwiftUI
import FirebaseFirestore

struct DevOptions: View {
    @State var showAlert: Bool = false
    @State var alertMessage: String = ""
    @StateObject private var auth = AuthManager.shared
    
    @State private var forumMaintanence = false
    @State private var consultationMaintanence = false
    @State private var labBookingMaintanence = false
    @State private var appMaintanence = false
    
    var body: some View {
        NavigationStack {
            if auth.user?.email == "avyan_mehra@s2023.ssts.edu.sg" {
                Form {
                    Section("Dev Options") {
                        Toggle("App Maintenance", isOn: $appMaintanence)
                            .onChange(of: appMaintanence) { newValue in
                                updateMaintanence(doc: "maintanence", value: newValue)
                            }
                        
                        Toggle("Forum Maintenance", isOn: $forumMaintanence)
                            .onChange(of: forumMaintanence) { newValue in
                                updateMaintanence(doc: "forum_maintanence", value: newValue)
                            }
                        
                        Toggle("Consultation Maintenance", isOn: $consultationMaintanence)
                            .onChange(of: consultationMaintanence) { newValue in
                                updateMaintanence(doc: "consultation_maintanence", value: newValue)
                            }
                        
                        Toggle("Lab Booking Maintenance", isOn: $labBookingMaintanence)
                            .onChange(of: labBookingMaintanence) { newValue in
                                updateMaintanence(doc: "lab_booking_maintanence", value: newValue)
                            }
                    }
                }
                .navigationTitle("Dev Options")
                .onAppear {
                    fetchMaintanenceStatus()
                }
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Status"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }
    
    private func fetchMaintanenceStatus() {
        let db = Firestore.firestore()
        let docs = ["maintanence", "forum_maintanence", "consultation_maintanence", "lab_booking_maintanence"]
        
        for doc in docs {
            db.collection("settings").document(doc).getDocument { snapshot, _ in
                if let data = snapshot?.data(), let status = data["status"] as? Bool {
                    switch doc {
                    case "maintanence": appMaintanence = status
                    case "forum_maintanence": forumMaintanence = status
                    case "consultation_maintanence": consultationMaintanence = status
                    case "lab_booking_maintanence": labBookingMaintanence = status
                    default: break
                    }
                }
            }
        }
    }
    
    private func updateMaintanence(doc: String, value: Bool) {
        let db = Firestore.firestore()
        db.collection("settings").document(doc).setData(["status": value], merge: true) { error in
            if let error = error {
                print("Failed to update \(doc): \(error.localizedDescription)")
                alertMessage = "Failed to update \(doc): \(error.localizedDescription)"
                showAlert = true
            } else {
                print("\(doc) status updated to \(value)")
                alertMessage = "\(doc) status updated to \(value ? "ON" : "OFF")"
                showAlert = true
            }
        }
    }
}

#Preview {
    DevOptions()
}
