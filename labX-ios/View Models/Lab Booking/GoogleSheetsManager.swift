import Foundation
import SwiftJWT

class GoogleSheetsManager {
    let sheetId: String
    let serviceAccountFileName: String
    
    struct GoogleJWTClaims: Claims {
        let iss: String
        let scope: String
        let aud: String
        let iat: Date
        let exp: Date
    }
    
    init(sheetId: String, serviceAccountFileName: String) {
        self.sheetId = sheetId
        self.serviceAccountFileName = serviceAccountFileName
    }
    
    private func loadServiceAccount() throws -> GoogleServiceAccount {
        // Debug: Print all files in the bundle and in subdirectory
        if let resourcePath = Bundle.main.resourcePath {
            let files = try? FileManager.default.contentsOfDirectory(atPath: resourcePath)
            print("[DEBUG] Bundle files: \(files ?? [])")
            let labBookingPath = (resourcePath as NSString).appendingPathComponent("Lab Booking")
            let labBookingFiles = try? FileManager.default.contentsOfDirectory(atPath: labBookingPath)
            print("[DEBUG] Lab Booking folder files: \(labBookingFiles ?? [])")
        }
        
        print("[DEBUG] Looking for service account file: \(serviceAccountFileName).json")
        
        if let url = Bundle.main.url(forResource: serviceAccountFileName, withExtension: "json", subdirectory: "Lab Booking") {
            print("[DEBUG] Found service account in Lab Booking subdirectory: \(url)")
            let data = try Data(contentsOf: url)
            print("[DEBUG] Service account file size: \(data.count) bytes")
            let account = try JSONDecoder().decode(GoogleServiceAccount.self, from: data)
            print("[DEBUG] Service account decoded successfully")
            return account
        }
        if let url = Bundle.main.url(forResource: serviceAccountFileName, withExtension: "json") {
            print("[DEBUG] Loaded service account JSON from root of bundle: \(url)")
            let data = try Data(contentsOf: url)
            print("[DEBUG] Service account file size: \(data.count) bytes")
            let account = try JSONDecoder().decode(GoogleServiceAccount.self, from: data)
            print("[DEBUG] Service account decoded successfully")
            return account
        }
        print("[DEBUG] Service account file not found in any location")
        throw NSError(domain: "GoogleSheetsManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Service account JSON not found in bundle or 'Lab Booking' subdirectory"])
    }
    
    private func getAccessToken(completion: @escaping (Result<String, Error>) -> Void) {
        DispatchQueue.global().async {
            do {
                print("[DEBUG] Loading service account...")
                let account = try self.loadServiceAccount()
                print("[DEBUG] Service account loaded successfully")
                print("[DEBUG] Client email: \(account.client_email)")
                print("[DEBUG] Token URI: \(account.token_uri)")
                
                let now = Date()
                let claims = GoogleJWTClaims(
                    iss: account.client_email,
                    scope: "https://www.googleapis.com/auth/spreadsheets",
                    aud: account.token_uri,
                    iat: now,
                    exp: now.addingTimeInterval(3600)
                )
                print("[DEBUG] JWT claims created")
                
                var jwt = JWT(claims: claims)
                print("[DEBUG] Converting private key...")
                let privateKey = try self.pemKeyToData(account.private_key)
                print("[DEBUG] Private key converted successfully")
                
                let signer = JWTSigner.rs256(privateKey: privateKey)
                print("[DEBUG] JWT signer created")
                
                let signedJWT = try jwt.sign(using: signer)
                print("[DEBUG] JWT signed successfully")
                
                // Exchange JWT for access token
                var request = URLRequest(url: URL(string: account.token_uri)!)
                request.httpMethod = "POST"
                let body = "grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=\(signedJWT)"
                request.httpBody = body.data(using: .utf8)
                request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
                
                print("[DEBUG] Making token request to: \(account.token_uri)")
                
                let task = URLSession.shared.dataTask(with: request) { data, response, error in
                    if let error = error {
                        print("[DEBUG] Network error: \(error.localizedDescription)")
                        completion(.failure(error))
                        return
                    }
                    
                    // Debug HTTP response
                    if let httpResponse = response as? HTTPURLResponse {
                        print("[DEBUG] HTTP Status Code: \(httpResponse.statusCode)")
                        print("[DEBUG] HTTP Headers: \(httpResponse.allHeaderFields)")
                    }
                    
                    guard let data = data else {
                        print("[DEBUG] No data received from token endpoint")
                        completion(.failure(NSError(domain: "GoogleSheetsManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "No data received from token endpoint"])))
                        return
                    }
                    
                    // Debug raw response
                    let responseString = String(data: data, encoding: .utf8) ?? "nil"
                    print("[DEBUG] Raw token response: \(responseString)")
                    
                    // Try to parse JSON
                    guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                        print("[DEBUG] Failed to parse JSON from token response")
                        completion(.failure(NSError(domain: "GoogleSheetsManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to parse JSON from token response"])))
                        return
                    }
                    
                    print("[DEBUG] Parsed JSON: \(json)")
                    
                    // Check for error in response
                    if let error = json["error"] as? String {
                        print("[DEBUG] Token endpoint returned error: \(error)")
                        let errorDescription = json["error_description"] as? String ?? "Unknown error"
                        completion(.failure(NSError(domain: "GoogleSheetsManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "Token error: \(error) - \(errorDescription)"])))
                        return
                    }
                    
                    guard let accessToken = json["access_token"] as? String else {
                        print("[DEBUG] No access_token found in response. Available keys: \(json.keys)")
                        completion(.failure(NSError(domain: "GoogleSheetsManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to parse access token from response"])))
                        return
                    }
                    
                    print("[DEBUG] Successfully obtained access token")
                    completion(.success(accessToken))
                }
                task.resume()
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    // Helper to convert PEM string to Data
    private func pemKeyToData(_ pem: String) throws -> Data {
        print("[DEBUG] Converting PEM key...")
        print("[DEBUG] PEM key length: \(pem.count)")
        print("[DEBUG] PEM key starts with: \(String(pem.prefix(50)))")
        
        let lines = pem.components(separatedBy: "\n").filter { !$0.contains("BEGIN") && !$0.contains("END") && !$0.isEmpty }
        print("[DEBUG] Filtered lines count: \(lines.count)")
        
        let base64 = lines.joined()
        print("[DEBUG] Base64 length: \(base64.count)")
        
        guard let data = Data(base64Encoded: base64) else {
            print("[DEBUG] Failed to decode base64 from PEM key")
            throw NSError(domain: "GoogleSheetsManager", code: 3, userInfo: [NSLocalizedDescriptionKey: "Invalid private key format"])
        }
        
        print("[DEBUG] Successfully converted PEM to Data, size: \(data.count) bytes")
        return data
    }
    
    func updateSheet(date: Date, timeSlots: [Date], teacherName: String, comment: String, sheetName: String, completion: @escaping (Result<Void, Error>) -> Void) {
        getAccessToken { result in
            switch result {
            case .success(let token):
                self.getSheetIdByName(token: token, sheetName: sheetName) { sheetIdResult in
                    switch sheetIdResult {
                    case .success(let sheetGid):
                        self.updateSheetWithToken(token: token, date: date, timeSlots: timeSlots, teacherName: teacherName, comment: comment, sheetId: sheetGid, sheetName: sheetName, completion: completion)
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func getSheetIdByName(token: String, sheetName: String, completion: @escaping (Result<Int, Error>) -> Void) {
        let url = URL(string: "https://sheets.googleapis.com/v4/spreadsheets/\(sheetId)?fields=sheets.properties")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let sheets = json["sheets"] as? [[String: Any]] else {
                completion(.failure(NSError(domain: "GoogleSheetsManager", code: 8, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch sheet list"])))
                return
            }
            for sheet in sheets {
                if let props = sheet["properties"] as? [String: Any],
                   let title = props["title"] as? String,
                   let gid = props["sheetId"] as? Int, title == sheetName {
                    completion(.success(gid))
                    return
                }
            }
            completion(.failure(NSError(domain: "GoogleSheetsManager", code: 9, userInfo: [NSLocalizedDescriptionKey: "Sheet/tab not found: \(sheetName)"])))
        }
        task.resume()
    }
    
    private func updateSheetWithToken(token: String, date: Date, timeSlots: [Date], teacherName: String, comment: String, sheetId: Int, sheetName: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let quotedSheetName = "'\(sheetName)'"
        let headerRange = "1:1"
        let url = URL(string: "https://sheets.googleapis.com/v4/spreadsheets/\(self.sheetId)/values/\(quotedSheetName)!\(headerRange)?majorDimension=ROWS")!
        print("[DEBUG] Using spreadsheetId for values API: \(self.sheetId)")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"
        let bookingDateString = dateFormatter.string(from: date)
        
        let fetchHeaderTask = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let values = json["values"] as? [[String]],
                  let headerRow = values.first else {
                completion(.failure(NSError(domain: "GoogleSheetsManager", code: 4, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch header row"])))
                return
            }
            guard let colIndex = headerRow.firstIndex(where: { $0 == bookingDateString }) else {
                completion(.failure(NSError(domain: "GoogleSheetsManager", code: 5, userInfo: [NSLocalizedDescriptionKey: "Date column not found in sheet"])))
                return
            }
            self.fetchTimeRows(token: token, timeSlots: timeSlots, colIndex: colIndex, teacherName: teacherName, comment: comment, tabId: sheetId, sheetName: sheetName, quotedSheetName: quotedSheetName, completion: completion)
        }
        fetchHeaderTask.resume()
    }
    
    private func fetchTimeRows(token: String, timeSlots: [Date], colIndex: Int, teacherName: String, comment: String, tabId: Int, sheetName: String, quotedSheetName: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let timeRange = "A2:A100"
        let url = URL(string: "https://sheets.googleapis.com/v4/spreadsheets/\(self.sheetId)/values/\(quotedSheetName)!\(timeRange)?majorDimension=COLUMNS")!
        print("[DEBUG] sheetName: \(sheetName), quotedSheetName: \(quotedSheetName)")
        print("[DEBUG] Fetching time column with URL: \(url.absoluteString)")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm:ss"
        let slotStrings = timeSlots.map { timeFormatter.string(from: $0) }
        
        let fetchTimeTask = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else {
                print("[DEBUG] No data received from Sheets API")
                completion(.failure(NSError(domain: "GoogleSheetsManager", code: 6, userInfo: [NSLocalizedDescriptionKey: "No data received from Sheets API"])))
                return
            }
            let responseString = String(data: data, encoding: .utf8) ?? "nil"
            print("[DEBUG] Raw time column response: \(responseString)")
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let values = json["values"] as? [[String]],
                  let timeColumn = values.first else {
                print("[DEBUG] Failed to parse time column JSON")
                completion(.failure(NSError(domain: "GoogleSheetsManager", code: 6, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch time column"])))
                return
            }
            print("[DEBUG] Parsed values: \(values)")
            let trimmedTimeColumn = timeColumn.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            let rowIndices = slotStrings.compactMap { slot in
                trimmedTimeColumn.firstIndex(of: slot.trimmingCharacters(in: .whitespacesAndNewlines))
            }
            guard let minRow = rowIndices.min(), let maxRow = rowIndices.max() else {
                completion(.failure(NSError(domain: "GoogleSheetsManager", code: 7, userInfo: [NSLocalizedDescriptionKey: "Time slot(s) not found in sheet"])))
                return
            }
            self.mergeAndWriteCells(token: token, colIndex: colIndex, minRow: minRow, maxRow: maxRow, teacherName: teacherName, comment: comment, tabId: tabId, sheetName: sheetName, quotedSheetName: quotedSheetName, completion: completion)
        }
        fetchTimeTask.resume()
    }
    
    private func mergeAndWriteCells(token: String, colIndex: Int, minRow: Int, maxRow: Int, teacherName: String, comment: String, tabId: Int, sheetName: String, quotedSheetName: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let colLetter = String(UnicodeScalar(65 + colIndex)!)
        let startRow = minRow + 2
        let endRow = maxRow + 2
        let range = "\(quotedSheetName)!\(colLetter)\(startRow):\(colLetter)\(endRow)"
        let value = "\(teacherName) - \(comment)"

        let mergeUrl = URL(string: "https://sheets.googleapis.com/v4/spreadsheets/\(self.sheetId):batchUpdate")!
        var mergeRequest = URLRequest(url: mergeUrl)
        mergeRequest.httpMethod = "POST"
        mergeRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        mergeRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let mergeBody: [String: Any] = [
            "requests": [
                [
                    "mergeCells": [
                        "range": [
                            "sheetId": tabId,
                            "startRowIndex": startRow - 1,
                            "endRowIndex": endRow,
                            "startColumnIndex": colIndex,
                            "endColumnIndex": colIndex + 1
                        ],
                        "mergeType": "MERGE_ALL"
                    ]
                ],
                [
                    "repeatCell": [
                        "range": [
                            "sheetId": tabId,
                            "startRowIndex": startRow - 1,
                            "endRowIndex": endRow,
                            "startColumnIndex": colIndex,
                            "endColumnIndex": colIndex + 1
                        ],
                        "cell": [
                            "userEnteredFormat": [
                                "backgroundColor": [
                                    "red": 1.0,
                                    "green": 0.8,
                                    "blue": 0.6
                                ],
                                "textFormat": [
                                    "fontSize": 15
                                ],
                                "wrapStrategy": "WRAP"
                            ]
                        ],
                        "fields": "userEnteredFormat(backgroundColor,textFormat,wrapStrategy)"
                    ]
                ]
            ]
        ]
        mergeRequest.httpBody = try? JSONSerialization.data(withJSONObject: mergeBody)
        let mergeTask = URLSession.shared.dataTask(with: mergeRequest) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            self.writeValue(token: token, range: range, value: value, completion: completion)
        }
        mergeTask.resume()
    }
    
    private func writeValue(token: String, range: String, value: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let url = URL(string: "https://sheets.googleapis.com/v4/spreadsheets/\(self.sheetId)/values/\(range)?valueInputOption=USER_ENTERED")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = [
            "range": range,
            "majorDimension": "COLUMNS",
            "values": [[value]]
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            completion(.success(()))
        }
        task.resume()
    }
    
    // Helper to escape sheet name for range
    private func sheetNameEscape(sheetId: Int, range: String) -> String {
        // This is a workaround: Google Sheets API allows using 'SheetName!A1:B2' for ranges
        // But for API calls, you can use the sheetId in batchUpdate, and for values API, you use 'SheetName!A1:B2'
        // Here, we need to map sheetId back to sheetName if needed, or pass sheetName as parameter
        // For now, assume the caller has the sheetName and can build 'SheetName!A1:B2'
        return range // Placeholder, will update in next step
    }
} 
