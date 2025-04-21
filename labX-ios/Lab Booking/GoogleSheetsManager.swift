//
//  GoogleSheetsManager.swift
//  labX-ios
//
//  Created by Avyan Mehra on 15/4/25.
//


import Foundation
import GoogleAPIClientForREST
import GTMSessionFetcher

class GoogleSheetsManager {
    private let service = GTLRSheetsService()
    
    init(credentials: Data) {
        let auth = try? GTMFetcherAuthorization(from: credentials)
        service.authorizer = auth
    }

    func writeBooking(to sheetTitle: String, booking: Booking, forDate date: Date) {
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"

        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEEE"

        let displayDate = dateFormatter.string(from: date)
        let dayOfWeek = dayFormatter.string(from: date)

        let timeSlots = booking.selectedTimeSlots
        guard let firstSlot = timeSlots.first,
              let lastSlot = timeSlots.last else { return }

        // Example: write to cells B4:B6
        let range = "\(sheetTitle)!\(calculateCellRange(for: timeSlots, date: date))"

        let value = "\(booking.teacher.name)\n\(booking.subject)"
        let valueRange = GTLRSheets_ValueRange()
        valueRange.range = range
        valueRange.values = Array(repeating: [value], count: timeSlots.count)

        let query = GTLRSheetsQuery_SpreadsheetsValuesUpdate
            .query(withObject: valueRange, spreadsheetId: "YOUR_SHEET_ID", range: range)
        query.valueInputOption = "RAW"

        service.executeQuery(query) { (_, result, error) in
            if let error = error {
                print("Error updating sheet: \(error)")
                return
            }

            // Merge cells
            let startRow = timeSlotsStartRow(time: firstSlot)
            let endRow = timeSlotsStartRow(time: lastSlot)
            let request = GTLRSheets_Request()
            request.mergeCells = GTLRSheets_MergeCellsRequest()
            request.mergeCells?.range = GTLRSheets_GridRange()
            request.mergeCells?.range?.sheetId = getSheetId(for: sheetTitle)
            request.mergeCells?.range?.startRowIndex = startRow
            request.mergeCells?.range?.endRowIndex = endRow + 1
            request.mergeCells?.range?.startColumnIndex = 1
            request.mergeCells?.range?.endColumnIndex = 2
            request.mergeCells?.mergeType = "MERGE_ALL"

            let batchUpdate = GTLRSheets_BatchUpdateSpreadsheetRequest()
            batchUpdate.requests = [request]
            let batchQuery = GTLRSheetsQuery_SpreadsheetsBatchUpdate
                .query(withObject: batchUpdate, spreadsheetId: "YOUR_SHEET_ID")
            service.executeQuery(batchQuery)
        }
    }

    private func timeSlotsStartRow(time: String) -> Int {
        // 8:00 AM is row 2, so offset by 20 mins
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        let base = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date())!
        let selected = formatter.date(from: time)!
        let diff = Calendar.current.dateComponents([.minute], from: base, to: selected).minute ?? 0
        return 2 + (diff / 20)
    }

    private func calculateCellRange(for timeSlots: [String], date: Date) -> String {
        // This assumes time slots start from row 2 and column B is the booking column
        let startRow = timeSlotsStartRow(time: timeSlots.first!)
        let endRow = timeSlotsStartRow(time: timeSlots.last!)
        return "B\(startRow):B\(endRow)"
    }

    private func getSheetId(for sheetTitle: String) -> Int {
        // TODO: Fetch this via Sheets API or hardcode the IDs
        return 0
    }
}
