//
//  ConsultCreate.swift
//  labX-ios
//
//  Created by Avyan Mehra on 14/4/25.
//

import SwiftUI

struct ConsultCreate: View {
    @Binding var consultations: [consultation]
    @State var teachers: [String] = ["Mr Dhanwin", "Mr Suresh", "Mr Dhanvin", "Mr CHAYYYY"]
    @State var selectedTeacher: String = ""
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
                            Text(teacher).tag(teacher)
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
                    if selectedTeacher.isEmpty || comments.isEmpty || selectedDate < .now {
                        showAlert = true
                        
                    } else {
                        let newConsult = consultation(teacher: selectedTeacher, date: selectedDate, comment: comments)
                        consultations.append(newConsult)
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
        }
    }
}

#Preview {
    ConsultCreate(consultations: .constant([consultation(teacher: "Dr Dhanwin", date: .now, comment: "")]))
}
