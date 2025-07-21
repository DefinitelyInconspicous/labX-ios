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
    
    var body: some View {
        ZStack {
            if showSplash {
                SplashScreenView()
                    .transition(.opacity)
                    .zIndex(1)
            } else {
                Group {
                    if auth.user != nil {
                        ContentView()
                            .onAppear {
                                if !hasSyncedEvents {
                                    hasSyncedEvents = true
                                    syncTeacherCalendarEvents()
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
                print(events)
                // Step 1: Delete past events
                timingsCollection
                    .whereField("teacherEmail", isEqualTo: email)
                    .whereField("date", isLessThan: Timestamp(date: now))
                    .getDocuments { snapshot, error in
                        guard let docs = snapshot?.documents, error == nil else { return }
                        
                        for doc in docs {
                            timingsCollection.document(doc.documentID).delete()
                        }
                        
                        // Step 2: Upload future events
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
    
}


