//
//  ContentView.swift
//  labX-ios
//
//  Created by Avyan Mehra on 17/3/25.
//

import SwiftUI
import Forever

struct ContentView: View {
    @StateObject private var consultationManager = ConsultationManager()
    @State private var createConsult: Bool = false
    @StateObject private var userManager = UserManager()
    @State public var key = "AIzaSyBEu_-xF1kGjRyPVAWIGo7sGTlWakPbYuo"
    
    var body: some View {
        TabView {
            NavigationStack {
                if let user = userManager.user {
                    if user.className == "Staff" && user.registerNumber == "Staff" {
                        let staffId = UUID(uuidString: user.id) ?? UUID()
                        StaffConsultationsView(
                            staff: staff(id: staffId, name: user.firstName + " " + user.lastName, email: user.email),
                            consultations: $consultationManager.consultations
                        )
                    } else {
                        NavigationStack {
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
                                        ForEach(consultationManager.consultations) { consultation in
                                            NavigationLink {
                                                DetailView(consultation: consultation, consultations: $consultationManager.consultations)
                                            } label: {
                                                VStack(alignment: .leading, spacing: 6) {
                                                    Text(consultation.teacher.name)
                                                        .font(.headline)
                                                        .foregroundColor(.primary)
                                                    Text(consultation.date.formatted(date: .abbreviated, time: .shortened))
                                                        .font(.subheadline)
                                                        .foregroundColor(.secondary)
                                                }
                                                .padding(.vertical, 8)
                                            }
                                        }
                                    }
                                    .listStyle(.insetGrouped)
                                }
                            }
                            .navigationTitle("Your Consultations")
                            .navigationBarTitleDisplayMode(.large)
                            .toolbar {
                                ToolbarItem() {
                                    Button(action: {
                                        createConsult = true
                                    }) {
                                        Image(systemName: "plus")
                                            .imageScale(.large)
                                            .fontWeight(.heavy)
                                            .frame(maxWidth: .infinity)
                                    }
                                }
                                
                                ToolbarItem(placement: .topBarLeading) {
                                    NavigationLink(destination: ProfileView(user: user)) {
                                        Image(systemName: "person.crop.circle")
                                            .imageScale(.large)
                                    }
                                }
                            }
                            .sheet(isPresented: $createConsult) {
                                ConsultCreate(consultations: $consultationManager.consultations)
                            }
                        }
                    }
                }
            }
            .onAppear {
                userManager.fetchUser()
                if let user = userManager.user {
                    if user.className == "Staff" && user.registerNumber == "Staff" {
                        // Don't fetch consultations for staff here, it's handled in StaffConsultationsView
                    } else {
                        consultationManager.fetchConsultations(forUser: user.email)
                    }
                }
            }
        }
    }
    
    func deleteConsultation(at offsets: IndexSet) {
        consultationManager.consultations.remove(atOffsets: offsets)
    }
}

#Preview {
    ContentView()
}
