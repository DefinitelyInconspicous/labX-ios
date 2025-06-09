//
//  ContentView.swift
//  labX-ios
//
//  Created by Avyan Mehra on 17/3/25.
//

import SwiftUI
import Forever

struct consultation: Identifiable, Decodable, Encodable {
    var id = UUID()
    var teacher: staff
    var date: Date
    var comment: String
}

struct ContentView: View {
    @Forever("consultations") var consultations: [consultation] = []
    @State private var createConsult: Bool = false
    @StateObject private var userManager = UserManager()
    @State public var key = "AIzaSyBEu_-xF1kGjRyPVAWIGo7sGTlWakPbYuo"
    
    
    
    
    
    var body: some View {
        TabView {
            NavigationStack {
                if let user = userManager.user, user.className == "Staff", user.registerNumber == "Staff" {
                    let staffId = UUID(uuidString: user.id) ?? UUID()
                    StaffConsultationsView(
                        staff: staff(id: staffId, name: user.firstName + " " + user.lastName, email: user.email),
                        consultations: $consultations
                    )
                } else {
                    NavigationStack {
                        VStack {
                            if consultations.isEmpty {
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
                                    ForEach(consultations) { consultation in
                                        NavigationLink {
                                            DetailView(consultation: consultation, consultations: $consultations)
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
                                if let user = userManager.user {
                                    NavigationLink(destination: ProfileView(user: user)) {
                                        Image(systemName: "person.crop.circle")
                                            .imageScale(.large)
                                    }
                                }
                            }
                            
                            
                        }
                        .sheet(isPresented: $createConsult) {
                            ConsultCreate(consultations: $consultations)
                        }
                    }
                    .onAppear {
                        userManager.fetchUser()
                    }
                }
            }
            .onAppear {
                userManager.fetchUser()
            }
        }
    }
    

func deleteConsultation(at offsets: IndexSet) {
    consultations.remove(atOffsets: offsets)
}
}


#Preview {
    ContentView()
}
