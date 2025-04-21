//
//  GoogleSheetsManager.swift
//  labX-ios
//
//  Created by Avyan Mehra on 15/4/25.
//


import Foundation

class GoogleSheetsManager {
    private let spreadsheetId = "1gMv-uKGjmyHFMrrdx01Hd7G1f-IaT1xvL9KLQYdM2zI"
    private let bearerToken = "YOUR_BEARER_TOKEN" // Replace with actual token
    private let baseURL = "https://sheets.googleapis.com/v4/spreadsheets"

    func writeBooking(to sheetName: String, booking: Booking, forDate date: Date) {
        let timeSlots = booking.selectedTimeSlots.sorted()
        guard let firstSlot = timeSlots.first,
              let lastSlot = timeSlots.last else { return }

        let startRow = timeSlotsStartRow(firstSlot)
        let endRow = timeSlotsStartRow(lastSlot)

        let cellRange = "\(sheetName)!B\(startRow):B\(endRow)"
        let value = "\(booking.teacher.name)\n\(booking.subject)"

        let payload: [String: Any] = [
            "range": cellRange,
            "majorDimension": "COLUMNS",
            "values": [[value]]
        ]

        guard let url = URL(string: "\(baseURL)/\(spreadsheetId)/values/\(cellRange)?valueInputOption=RAW"),
              let body = try? JSONSerialization.data(withJSONObject: payload) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.addValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Booking failed: \(error)")
                return
            }

            print("Booking saved to sheet successfully.")
        }.resume()
    }

    private func timeSlotsStartRow(_ time: String) -> Int {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        let base = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date())!
        guard let selected = formatter.date(from: time) else { return 2 }
        let diff = Calendar.current.dateComponents([.minute], from: base, to: selected).minute ?? 0
        return 2 + (diff / 20)
    }
}
