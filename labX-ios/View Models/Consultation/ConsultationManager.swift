//
//  ConsultationManager.swift
//  labX-ios
//
//  Created by Avyan Mehra on 23/6/25.
//

import FirebaseAuth
import FirebaseFirestore
import Foundation

class ConsultationManager: ObservableObject {
    @Published var consultations: [consultation] = []
    private let db = Firestore.firestore()
    
    func fetchConsultations(forUser email: String) {
        print("Fetching consultations for student: \(email)")
        db.collection("consultations")
            .whereField("student", isEqualTo: email)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    print("Error fetching student consultations: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("No documents found for student: \(email)")
                    return
                }
                
                print("Found \(documents.count) consultations for student: \(email)")
                
                self?.consultations = documents.compactMap { document in
                    let data = document.data()
                    guard let teacherName = data["teacherName"] as? String,
                          let teacherEmail = data["teacherEmail"] as? String,
                          let date = (data["date"] as? Timestamp)?.dateValue(),
                          let location = data["location"] as? String,
                          let comment = data["comment"] as? String,
                          let student = data["student"] as? String else {
                        print("Failed to parse consultation data: \(data)")
                        return nil
                    }
                    
                    let teacher = staff(name: teacherName, email: teacherEmail)
                    return consultation(
                        id: UUID(uuidString: document.documentID) ?? UUID(),
                        teacher: teacher,
                        date: date,
                        comment: comment,
                        student: student,
                        status: data["status"] as? String,
                        location: location
                    )
                }
            }
    }
    
    func fetchTeacherConsultations(forTeacher email: String) {
        print("Fetching consultations for teacher: \(email)")
        db.collection("consultations")
            .whereField("teacherEmail", isEqualTo: email)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    print("Error fetching teacher consultations: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("No documents found for teacher: \(email)")
                    return
                }
                
                print("Found \(documents.count) consultations for teacher: \(email)")
                
                self?.consultations = documents.compactMap { document in
                    let data = document.data()
                    print("Consultation data: \(data)")
                    
                    guard let teacherName = data["teacherName"] as? String,
                          let teacherEmail = data["teacherEmail"] as? String,
                          let date = (data["date"] as? Timestamp)?.dateValue(),
                          let location = data["location"] as? String,
                          let comment = data["comment"] as? String,
                          let student = data["student"] as? String else {
                        print("Failed to parse consultation data: \(data)")
                        return nil
                    }
                    
                    let teacher = staff(name: teacherName, email: teacherEmail)
                    return consultation(
                        id: UUID(uuidString: document.documentID) ?? UUID(),
                        teacher: teacher,
                        date: date,
                        comment: comment,
                        student: student,
                        status: data["status"] as? String,
                        location: location
                    )
                }
            }
    }
    
    func addConsultation(_ consultation: consultation) {
        print("Adding consultation for teacher: \(consultation.teacher.email)")
        let data: [String: Any] = [
            "teacherName": consultation.teacher.name,
            "teacherEmail": consultation.teacher.email,
            "date": Timestamp(date: consultation.date),
            "comment": consultation.comment,
            "student": consultation.student,
            "location": consultation.location,
            "status": consultation.status ?? "pending"
        ]
        
        db.collection("consultations").document(consultation.id.uuidString).setData(data) { error in
            if let error = error {
                print("Error adding consultation: \(error.localizedDescription)")
            } else {
                print("Successfully added consultation")
            }
        }
    }
    
    func deleteConsultation(_ consultation: consultation) {
        print("Deleting consultation: \(consultation.id)")
        db.collection("consultations").document(consultation.id.uuidString).delete { error in
            if let error = error {
                print("Error deleting consultation: \(error.localizedDescription)")
            } else {
                print("Successfully deleted consultation")
            }
        }
    }
    
    func rescheduleConsultation(_ consultationId: String, newDate: Date, newLocation: String, reason: String, rescheduledBy: String) async -> Bool {
        print("Rescheduling consultation: \(consultationId)")
        
        let data: [String: Any] = [
            "date": Timestamp(date: newDate),
            "location": newLocation,
            "status": "rescheduled",
            "rescheduleReason": reason,
            "rescheduledBy": rescheduledBy,
            "rescheduledAt": Timestamp()
        ]
        
        return await withCheckedContinuation { continuation in
            db.collection("consultations").document(consultationId).updateData(data) { error in
                if let error = error {
                    print("Error rescheduling consultation: \(error.localizedDescription)")
                    continuation.resume(returning: false)
                } else {
                    print("Successfully rescheduled consultation")
                    continuation.resume(returning: true)
                }
            }
        }
    }
}
