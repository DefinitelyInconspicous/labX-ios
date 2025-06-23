//
//  GoogleServiceAccount.swift
//  labX-ios
//
//  Created by Avyan Mehra on 19/6/25.
//


struct GoogleServiceAccount: Codable {
    let type: String
    let project_id: String
    let private_key_id: String
    let private_key: String
    let client_email: String
    let client_id: String
    let auth_uri: String
    let token_uri: String
    let auth_provider_x509_cert_url: String
    let client_x509_cert_url: String
}