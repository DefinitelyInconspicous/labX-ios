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
    
    var body: some View {
        TabView {
            NavigationStack {
                Group {
                    if let user = userManager.user {
                        if user.className == "Staff" && user.registerNumber == "Staff" {
                            let staffId = UUID(uuidString: user.id) ?? UUID()
                            StaffConsultationsView(
                                staff: staff(name: user.firstName + " " + user.lastName, email: user.email),
                                consultations: $consultationManager.consultations
                            )
                        } else {
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
                                ToolbarItem(placement: .topBarTrailing) {
                                    Button(action: {
                                        createConsult = true
                                    }) {
                                        Image(systemName: "plus")
                                            .imageScale(.large)
                                            .fontWeight(.heavy)
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
            .tabItem {
                Label("Consultations", systemImage: "calendar")
            }
            
            NavigationStack {
                Group {
                    if let user = userManager.user, user.className == "Staff" {
                        BookingMain()
                    } else {
                        VStack(spacing: 12) {
                            Spacer()
                            Image(systemName: "lock.shield")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                            Text("Access Restricted")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.gray)
                            Text("Only staff members can access lab booking")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            Spacer()
                        }
                    }
                }
            }
            .tabItem {
                Label("Lab Booking", systemImage: "building.2")
            }
        }
        .onAppear {
            // Fetch user data only once when view appears
            if userManager.user == nil {
                userManager.fetchUser()
            }
            
            // Fetch consultations only if we have a user
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

#Preview {
    ContentView()
}
