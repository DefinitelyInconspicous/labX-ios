//
//  Definitions.swift
//  labX-ios
//
//  Created by Avyan Mehra on 10/6/25.
//

import Foundation

struct consultation: Identifiable, Decodable, Encodable {
    var id = UUID()
    var teacher: staff
    var date: Date
    var comment: String
    var student: String
}

struct User: Identifiable, Codable {
    var id: String = UUID().uuidString
    var firstName: String
    var lastName: String
    var email: String
    var className: String
    var registerNumber: String
}

struct staff: Identifiable, Equatable, Hashable, Encodable, Decodable {
    var id = UUID()
    var name: String
    var email: String
}
