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
                                HomeView()
                            }
                            .navigationTitle("Home")
                            .navigationBarTitleDisplayMode(.large)
                            .toolbar {
                                if user.className != "Staff" {
                                    ToolbarItem(placement: .topBarTrailing) {
                                        Button(action: {
                                            createConsult = true
                                        }) {
                                            Image(systemName: "plus")
                                                .imageScale(.large)
                                                .fontWeight(.heavy)
                                        }
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
                Label("Home", systemImage: "house")
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
            if userManager.user == nil {
                userManager.fetchUser()
            }
            if let user = userManager.user {
                if user.className == "Staff" && user.registerNumber == "Staff" {
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
