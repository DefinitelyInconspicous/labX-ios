//
//  RootView.swift
//  labX-ios
//
//  Created by Avyan Mehra on 14/4/25.
//

import Foundation
import SwiftUI
import Firebase
import EventKit
import FirebaseFirestore

struct RootView: View {
    @StateObject private var auth = AuthManager.shared
    @State private var showSplash = true
    @State private var hasSyncedEvents = false
    @State private var isUnderMaintenance = false
    @State private var isEmailVerified = false 
    @State private var showVerificationSheet = false
    @State private var verificationMessage = ""
    
    var body: some View {
        ZStack {
            if showSplash {
                SplashScreenView()
                    .transition(.opacity)
                    .zIndex(2)
            } else if isUnderMaintenance {
                VStack(spacing: 20) {
                    Image(systemName: "wrench.and.screwdriver.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.orange)
                    Text("App Under Maintenance")
                        .font(.title)
                        .fontWeight(.semibold)
                    Text("We apologise for the inconvenience.\n Please check back later.")
                        .foregroundColor(.gray)
                    if auth.user?.email == "avyan_mehra@s2023.ssts.edu.sg" {
                    Button {
                        unlockApp()
                    } label: {
                        Text("Unlock App for Everyone")
                            .padding()
                            .foregroundColor(.white)
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                        
                    Button {
                        isUnderMaintenance = false
                    } label: {
                        Text("Bypass Maintenance")
                            .padding()
                            .foregroundColor(.white)
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    
                }
            }
                    .multilineTextAlignment(.center)
                    .padding()
                    .transition(.opacity)
                    .zIndex(2)
                
            } else {
                Group {
                    if let user = auth.user {
                        if isEmailVerified {
                            ContentView()
                                .onAppear {
                                    if !hasSyncedEvents {
                                        hasSyncedEvents = true
                                        syncTeacherCalendarEvents()
                                    }
                                }
                        } else {
                            LoginView()
                                .onAppear {
                                    checkEmailVerificationOnLaunch()
                                }
                                .sheet(isPresented: $showVerificationSheet) {
                                    VerificationView(verificationMessage: $verificationMessage, showVerificationSheet: $showVerificationSheet)
                                }
                        }
                    } else {
                        LoginView()
                    }
                }
                .transition(.opacity)
                .zIndex(0)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    showSplash = false
                }
            }
            listenForMaintenance()
            checkEmailVerificationOnLaunch()
        }
    }
    
    private func unlockApp() {
        let db = Firestore.firestore()
        db.collection("settings").document("maintanence").setData(["status": false], merge: true) { error in
            if let error = error {
                print("Failed to update status: \(error.localizedDescription)")
            } else {
                print("Maintenance mode disabled by superuser")
            }
        }
    }
    
    private func listenForMaintenance() {
        let db = Firestore.firestore()
        db.collection("settings").document("maintanence")
            .addSnapshotListener { snapshot, error in
                guard let doc = snapshot, error == nil else {
                    print("Error fetching maintenance status: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                if let status = doc["status"] as? Bool {
                    isUnderMaintenance = status
                    print(isUnderMaintenance ? "App is under maintenance." : "App is operational.")
                }
            }
    }
    
    private func syncTeacherCalendarEvents() {
        guard let user = auth.user else { return }
        let db = Firestore.firestore()
        
        db.collection("users").document(user.uid).getDocument { snapshot, error in
            guard let doc = snapshot, error == nil,
                  let className = doc["className"] as? String,
                  className == "Staff",
                  let email = doc["email"] as? String else {
                return
            }
            
            requestCalendarAccess { granted in
                guard granted else { return }
                
                let now = Date()
                let fourWeeksFromNow = Calendar.current.date(byAdding: .weekOfYear, value: 4, to: now)!
                let events = fetchEvents(from: now, to: fourWeeksFromNow)
                let timingsCollection = db.collection("timings")
                
                timingsCollection
                    .whereField("teacherEmail", isEqualTo: email)
                    .whereField("date", isLessThan: Timestamp(date: now))
                    .getDocuments { snapshot, error in
                        guard let docs = snapshot?.documents, error == nil else { return }
                        
                        for doc in docs {
                            timingsCollection.document(doc.documentID).delete()
                        }
                        for event in events {
                            let start = event.startDate
                            let duration = Int(event.endDate.timeIntervalSince(start ?? .now) / 60)
                            let docID = "\(email)_\(Int(start?.timeIntervalSince1970 ?? 0))"
                            
                            let data: [String: Any] = [
                                "teacherEmail": email,
                                "date": Timestamp(date: start ?? .now),
                                "duration": duration
                            ]
                            
                            timingsCollection.document(docID).setData(data, merge: true)
                        }
                    }
            }
        }
    }
    
    private func requestCalendarAccess(completion: @escaping (Bool) -> Void) {
        let store = EKEventStore()
        store.requestAccess(to: .event) { granted, _ in
            completion(granted)
        }
    }
    
    private func fetchEvents(from startDate: Date, to endDate: Date) -> [EKEvent] {
        let eventStore = EKEventStore()
        let calendars = eventStore.calendars(for: .event)
        
        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: calendars)
        let events = eventStore.events(matching: predicate)
        
        return events.sorted { $0.startDate < $1.startDate }
    }
    
    private func checkEmailVerificationOnLaunch() {
        if let currentUser = auth.user {
            AuthManager.shared.checkEmailVerified { verified in
                DispatchQueue.main.async {
                    isEmailVerified = verified
                    if !verified {
                        showVerificationSheet = true
                        verificationMessage = "Please verify your email before logging in."
                    }
                }
            }
        } else {
            isEmailVerified = false
        }
    }
}

#Preview {
    RootView()
}
