//
//  ConsultCreate.swift
//  labX-ios
//
//  Created by Avyan Mehra on 14/4/25.
//

import SwiftUI
import Forever

var teachers: [staff] = [
    staff(name: "Mr Mehra", email: "amspy2468@gmail.com"),
    staff(name: "labX Admin", email: "labX.serve@gmail.com"),
    staff(name: "Mr CHAYYYY", email: "chay_yu_hung@s2021.ssts.edu.sg"),
    staff(name: "Mr Suresh", email: "sairam_suresh@s2021.ssts.edu.sg")]

struct ConsultCreate: View {
    @Binding var consultations: [consultation]
    @StateObject private var consultationManager = ConsultationManager()
    @StateObject private var userManager = UserManager()
    
    @State var selectedTeacher: staff = staff(name: "", email: "")
    @State var selectedDate: Date = Date()
    @State var showAlert = false
    @State var comments: String = ""
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Select Teacher")) {
                    Picker("Teacher", selection: $selectedTeacher) {
                        ForEach(teachers, id: \.self) { teacher in
                            Text(teacher.name).tag(teacher)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section(header: Text("Select Date")) {
                    DatePicker("Date", selection: $selectedDate, displayedComponents: [.date, .hourAndMinute])
                }
                Section(header: Text("Comments")) {
                    TextField("I would like to catch up on...", text: $comments)
                }
                
                Button {
                    if selectedTeacher == staff(name: "", email: "") || comments.isEmpty || selectedDate < .now {
                        showAlert = true
                    } else if let user = userManager.user {
                        let newConsult = consultation(
                            teacher: selectedTeacher,
                            date: selectedDate,
                            comment: comments,
                            student: user.email
                        )
                        consultationManager.addConsultation(newConsult)
                        dismiss()
                    }
                } label: {
                    Text("Create Consultation")
                        .frame(width: 300, height: 50)
                }
                .buttonStyle(.borderedProminent)
            }
            .navigationTitle("Create Consultation")
            .navigationBarTitleDisplayMode(.inline)
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Missing Info"), message: Text("Please ensure you have selected a teacher, added a comment and selected a valid date"), dismissButton: .default(Text("OK")))
            }
            .onAppear {
                userManager.fetchUser()
            }
        }
    }
}

func sendNoti(teacher: staff, date: Date, comment: String, user : User) {
    let message = "\(user.firstName) from \(user.className) requested a new consultation with \(teacher.name) on \(date)"
    
}

#Preview {
    ConsultCreate(consultations: .constant([consultation(teacher: staff(name: "", email: ""), date: .now, comment: "", student: "")]))
}
