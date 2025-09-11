//
//  ContentView.swift
//  labX-ios
//
//  Created by Avyan Mehra on 17/3/25.
//

import SwiftUI
import Forever
import FirebaseFirestore

struct ContentView: View {
    @StateObject private var consultationManager = ConsultationManager()
    @State private var createConsult: Bool = false
    @StateObject private var userManager = UserManager()
    @State private var bookingmaintanence: Bool = false
    @State private var consultationMaintanence: Bool = false
    @State private var forumMaintanence: Bool = false
    
    var body: some View {
        TabView {
            NavigationStack {
                if consultationMaintanence == false {
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
                                    ConsultationScheduler()
                                }
                            }
                        }
                    }
                } else {
                        VStack(spacing: 12) {
                            Image(systemName: "wrench.and.screwdriver.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.orange)
                            Text("Consultation is Under Maintenance")
                                .font(.title)
                                .fontWeight(.semibold)
                            Text("We apologise for the inconvenience.\nPlease check back later.")
                                .foregroundColor(.gray)
                    }
                }
            }
            .tabItem {
                Label("Home", systemImage: "house")
            }
            
            if let user = userManager.user, user.className == "Staff", bookingmaintanence == false {
                   NavigationStack {
                       BookingMain()
                   }
                   .tabItem {
                       Label("Lab Booking", systemImage: "building.2")
                   }
               } else if bookingmaintanence == true, userManager.user?.className == "Staff" {
                   NavigationStack {
                       VStack(spacing: 12) {
                           Image(systemName: "wrench.and.screwdriver.fill")
                               .font(.system(size: 60))
                               .foregroundColor(.orange)
                           Text("Lab Booking is Under Maintenance")
                               .font(.title)
                               .fontWeight(.semibold)
                           Text("We apologise for the inconvenience.\nPlease check back later.")
                               .foregroundColor(.gray)
                       }
                   }
                   .tabItem {
                       Label("Lab Booking", systemImage: "building.2")
                   }
               }
            NavigationStack {
                ForumMainView()
            }
            .tabItem {
                Label("Forum", systemImage: "text.bubble")
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
            let db = Firestore.firestore()
            db.collection("settings").document("lab_booking_maintanence")
                .addSnapshotListener { snapshot, error in
                    guard let doc = snapshot, error == nil else {
                        print("Error fetching lab booking maintenance status: \(error?.localizedDescription ?? "Unknown error")")
                        return
                    }
                    if let status = doc["status"] as? Bool {
                        bookingmaintanence = status
                        print(bookingmaintanence ? "lab booking is under maintenance." : "lab booking is operational.")
                    }
                }
            db.collection("settings").document("consultation_maintanence")
                .addSnapshotListener { snapshot, error in
                    guard let doc = snapshot, error == nil else {
                        print("Error fetching consultation maintenance status: \(error?.localizedDescription ?? "Unknown error")")
                        return
                    }
                    if let status = doc["status"] as? Bool {
                        consultationMaintanence = status
                        print(consultationMaintanence ? "Consultation is under maintenance." : "Consultation is operational.")
                    }
                }
            db.collection("settings").document("forum_maintanence")
                .addSnapshotListener { snapshot, error in
                    guard let doc = snapshot, error == nil else {
                        print("Error fetching Forum maintenance status: \(error?.localizedDescription ?? "Unknown error")")
                        return
                    }
                    if let status = doc["status"] as? Bool {
                        forumMaintanence = status
                        print(forumMaintanence ? "Forum is under maintenance." : "Forum is operational.")
                    }
                }
        }
    }
}

#Preview {
    ContentView()
}
