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
    @Published var quotaStatus: QuotaStatus? = nil
    @Published var blackoutActive: Bool = false
    @Published var approvalPending: Bool = false
    @Published var approvalJustification: String = ""
    private let db = Firestore.firestore()
    
    // --- Quota Check ---
    func fetchQuota(forStudent email: String, completion: @escaping (QuotaStatus?) -> Void) {
        db.collection("quotas").document(email).getDocument { doc, error in
            guard let data = doc?.data(), error == nil else { completion(nil); return }
            let used = data["used"] as? Int ?? 0
            let limit = data["limit"] as? Int ?? 3
            completion(QuotaStatus(used: used, limit: limit))
        }
    }
    
    // --- Blackout Check ---
    func isBlackoutActive(date: Date, completion: @escaping (Bool) -> Void) {
        db.collection("blackoutPeriods")
            .whereField("start", isLessThanOrEqualTo: date)
            .whereField("end", isGreaterThanOrEqualTo: date)
            .getDocuments { snap, error in
                completion((snap?.documents.count ?? 0) > 0)
            }
    }
    
    // --- Approval Gating ---
    func submitApprovalRequest(for consult: consultation, justification: String, completion: @escaping (Bool) -> Void) {
        let approval: [String: Any] = [
            "consultId": consult.id,
            "student": consult.student,
            "teacher": consult.teacher.email,
            "justification": justification,
            "status": "pending",
            "timestamp": Timestamp()
        ]
        db.collection("approvals").addDocument(data: approval) { error in
            completion(error == nil)
        }
    }
    
    // --- Prep Upload Enforcement ---
    func canSubmitConsult(prepMaterialUrls: [String]?) -> Bool {
        return (prepMaterialUrls?.isEmpty == false)
    }
    
    // --- Fetch Consultations (for Student) ---
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
                        id: document.documentID,
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
    
    // --- Fetch Consultations (for Teacher) ---
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
                        id: document.documentID,
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
    func addConsultation(_ consult: consultation, completion: ((Bool) -> Void)? = nil) {
        // Quota, blackout, prep checks should be done before calling this
        let auditTrailArray: [[String: Any]] = (consult.auditTrail ?? []).map { ["actorID": $0.actorID, "action": $0.action, "timestamp": Timestamp(date: $0.timestamp), "targetID": $0.targetID, "role": $0.role] }
        var data: [String: Any] = [
            "teacherName": consult.teacher.name,
            "teacherEmail": consult.teacher.email,
            "date": Timestamp(date: consult.date),
            "comment": consult.comment,
            "student": consult.student,
            "location": consult.location,
            "status": consult.status ?? "pending",
            "topic": consult.topic ?? "",
            "assignmentId": consult.assignmentId ?? "",
            "prepMaterialUrls": consult.prepMaterialUrls ?? [],
            "approvalStatus": consult.approvalStatus ?? "",
            "justification": consult.justification ?? "",
            "outcomeTags": consult.outcomeTags ?? [],
            "summary": consult.summary ?? "",
            "reflectionPrompt": consult.reflectionPrompt ?? "",
            "reflectionResponse": consult.reflectionResponse ?? "",
            "schoolId": consult.schoolId ?? "",
            "auditTrail": auditTrailArray
        ]
        db.collection("consultations").addDocument(data: data) { [weak self] error in
            completion?(error == nil)
            // Refresh quota for student after adding
            self?.fetchQuota(forStudent: consult.student) { quota in
                DispatchQueue.main.async {
                    self?.quotaStatus = quota
                }
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
    func deleteConsultation(_ consultation: consultation) {
        print("Deleting consultation: \(consultation.id)")
        db.collection("consultations").document(consultation.id).delete { [weak self] error in
            if let error = error {
                print("Error deleting consultation: \(error.localizedDescription)")
            } else {
                print("Successfully deleted consultation")
                // Refresh quota for student after deleting
                self?.fetchQuota(forStudent: consultation.student) { quota in
                    DispatchQueue.main.async {
                        self?.quotaStatus = quota
                    }
                }
            }
        }
    }
    // Fetch all quotas for staff dashboard
    func fetchAllQuotas(completion: @escaping ([String: QuotaStatus]) -> Void) {
        db.collection("quotas").getDocuments { snapshot, error in
            var result: [String: QuotaStatus] = [:]
            guard let docs = snapshot?.documents, error == nil else { completion(result); return }
            for doc in docs {
                let data = doc.data()
                let used = data["used"] as? Int ?? 0
                let limit = data["limit"] as? Int ?? 3
                result[doc.documentID] = QuotaStatus(used: used, limit: limit)
            }
            completion(result)
        }
    }
    func exportPortfolio(forUser email: String, completion: @escaping (String?) -> Void) {
        db.collection("consultations").whereField("student", isEqualTo: email).getDocuments { snapshot, error in
            guard let docs = snapshot?.documents, error == nil else { completion(nil); return }
            var csv = "Date,Teacher,Topic,Assignment,Location,OutcomeTags,Summary\n"
            for doc in docs {
                let data = doc.data()
                let date = (data["date"] as? Timestamp)?.dateValue().formatted(date: .abbreviated, time: .shortened) ?? ""
                let teacher = data["teacherName"] as? String ?? ""
                let topic = data["topic"] as? String ?? ""
                let assignment = data["assignmentId"] as? String ?? ""
                let location = data["location"] as? String ?? ""
                let outcomeTags = (data["outcomeTags"] as? [String])?.joined(separator: ";") ?? ""
                let summary = data["summary"] as? String ?? ""
                csv += "\(date),\(teacher),\(topic),\(assignment),\(location),\(outcomeTags),\(summary)\n"
            }
            completion(csv)
        }
    }
    func getHeatmapData(completion: @escaping ([String: Int]) -> Void) {
        db.collection("consultations").getDocuments { snapshot, error in
            guard let docs = snapshot?.documents, error == nil else { completion([:]); return }
            var heatmap: [String: Int] = [:]
            for doc in docs {
                let topic = doc.data()["topic"] as? String ?? "Unknown"
                heatmap[topic, default: 0] += 1
            }
            completion(heatmap)
        }
    }
    func logAudit(action: String, actorID: String, targetID: String, role: String) {
        let audit: [String: Any] = [
            "actorID": actorID,
            "action": action,
            "targetID": targetID,
            "timestamp": Timestamp(),
            "role": role
        ]
        db.collection("auditLogs").addDocument(data: audit)
    }
    // Set quota for a student
    func setQuota(forStudent email: String, limit: Int, completion: @escaping (Bool) -> Void) {
        db.collection("quotas").document(email).setData(["limit": limit], merge: true) { error in
            completion(error == nil)
        }
    }
    // --- Blackout Period Management ---
    struct BlackoutPeriod: Identifiable {
        var id: String
        var start: Date
        var end: Date
    }
    func fetchBlackoutPeriods(completion: @escaping ([BlackoutPeriod]) -> Void) {
        db.collection("blackoutPeriods").getDocuments { snapshot, error in
            guard let docs = snapshot?.documents, error == nil else { completion([]); return }
            let periods = docs.compactMap { doc -> BlackoutPeriod? in
                let data = doc.data()
                guard let start = (data["start"] as? Timestamp)?.dateValue(),
                      let end = (data["end"] as? Timestamp)?.dateValue() else { return nil }
                return BlackoutPeriod(id: doc.documentID, start: start, end: end)
            }
            completion(periods)
        }
    }
    func addBlackoutPeriod(start: Date, end: Date, completion: @escaping (Bool) -> Void) {
        let data: [String: Any] = ["start": Timestamp(date: start), "end": Timestamp(date: end)]
        db.collection("blackoutPeriods").addDocument(data: data) { error in
            completion(error == nil)
        }
    }
    func removeBlackoutPeriod(id: String, completion: @escaping (Bool) -> Void) {
        db.collection("blackoutPeriods").document(id).delete { error in
            completion(error == nil)
        }
    }
}

struct QuotaStatus {
    var used: Int
    var limit: Int
}
