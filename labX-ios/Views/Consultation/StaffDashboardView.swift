//
//  StaffDashboardView.swift
//  labX-ios
//
//  Created by Avyan Mehra on 5/9/25.
//

import SwiftUI

struct StaffDashboardView: View {
    @StateObject private var consultationManager = ConsultationManager()
    @State private var quotas: [String: QuotaStatus] = [:]
    @State private var heatmap: [String: Int] = [:]
    @State private var isLoading = true
    @State private var showQuotaDetails = false
    @State private var selectedStudent: String = ""
    @State private var portfolioCSV: String? = nil
    @State private var showPortfolioExport = false
    @State private var quotaEdits: [String: String] = [:]
    @State private var blackoutPeriods: [ConsultationManager.BlackoutPeriod] = []
    @State private var newBlackoutStart: Date = Date()
    @State private var newBlackoutEnd: Date = Date().addingTimeInterval(3600)
    @State private var showBlackoutError = false
    @State private var blackoutErrorMessage = ""

    var totalConsultations: Int { consultationManager.consultations.count }
    var upcomingConsultations: Int { consultationManager.consultations.filter { $0.date > Date() }.count }
    var pastConsultations: Int { consultationManager.consultations.filter { $0.date <= Date() }.count }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Staff Dashboard")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.top)

                    // Summary Section
                    HStack(spacing: 12) {
                        DashboardStatCard(title: "Total Consults", value: "\(totalConsultations)", color: .blue)
                        DashboardStatCard(title: "Upcoming", value: "\(upcomingConsultations)", color: .green)
                        DashboardStatCard(title: "Past", value: "\(pastConsultations)", color: .orange)
                    }
                    .padding(.horizontal)

                    // Portfolio Export Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Export Student Portfolio")
                            .font(.headline)

                        Picker("Select Student", selection: $selectedStudent) {
                            Text("Select...").tag("")
                            ForEach(quotas.keys.sorted(), id: \.self) { email in
                                Text(email).tag(email)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .padding(.horizontal)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray5)))

                        Button {
                            if !selectedStudent.isEmpty {
                                consultationManager.exportPortfolio(forUser: selectedStudent) { csv in
                                    portfolioCSV = csv
                                    showPortfolioExport = true
                                }
                            }
                        } label: {
                            Text("Export Portfolio")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(selectedStudent.isEmpty ? Color.gray : Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .disabled(selectedStudent.isEmpty)

                        if let csv = portfolioCSV, showPortfolioExport {
                            ScrollView(.vertical) {
                                Text(csv)
                                    .font(.caption2)
                                    .padding(6)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color(.systemGray5))
                                    .cornerRadius(8)
                            }
                            .frame(height: 120)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)

                    // Quota Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Student Quotas")
                            .font(.headline)
                        if quotas.isEmpty {
                            Text("Loading quotas...")
                                .foregroundColor(.gray)
                        } else {
                            ForEach(quotas.sorted(by: { $0.key < $1.key }), id: \.key) { email, quota in
                                HStack(spacing: 8) {
                                    Text(email)
                                        .font(.caption)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.7)
                                    Spacer()
                                    Text("\(quota.used)/")
                                        .font(.caption)
                                    TextField("Limit", text: Binding(
                                        get: { quotaEdits[email] ?? "\(quota.limit)" },
                                        set: { quotaEdits[email] = $0 }
                                    ))
                                    .frame(width: 50)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .keyboardType(.numberPad)

                                    Button("Set") {
                                        if let newLimit = Int(quotaEdits[email] ?? "") {
                                            consultationManager.setQuota(forStudent: email, limit: newLimit) { success in
                                                if success {
                                                    quotas[email]?.limit = newLimit
                                                }
                                            }
                                        }
                                    }
                                    .font(.caption2)
                                }
                                .padding(.vertical, 2)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)

                    // Blackout Periods Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Blackout Periods")
                            .font(.headline)

                        if blackoutPeriods.isEmpty {
                            Text("No blackout periods set.")
                                .foregroundColor(.gray)
                        } else {
                            ForEach(blackoutPeriods) { period in
                                HStack {
                                    Text("\(period.start.formatted(date: .abbreviated, time: .shortened)) - \(period.end.formatted(date: .abbreviated, time: .shortened))")
                                        .font(.caption2)
                                    Spacer()
                                    Button("Remove") {
                                        consultationManager.removeBlackoutPeriod(id: period.id) { success in
                                            if success {
                                                blackoutPeriods.removeAll { $0.id == period.id }
                                            }
                                        }
                                    }
                                    .font(.caption2)
                                    .foregroundColor(.red)
                                }
                            }
                        }

                        HStack {
                            DatePicker("", selection: $newBlackoutStart, displayedComponents: [.date, .hourAndMinute])
                                .labelsHidden()
                            DatePicker("", selection: $newBlackoutEnd, displayedComponents: [.date, .hourAndMinute])
                                .labelsHidden()
                            Button("Add") {
                                if newBlackoutEnd > newBlackoutStart {
                                    consultationManager.addBlackoutPeriod(start: newBlackoutStart, end: newBlackoutEnd) { success in
                                        if success {
                                            consultationManager.fetchBlackoutPeriods { periods in
                                                blackoutPeriods = periods
                                            }
                                        } else {
                                            blackoutErrorMessage = "Failed to add blackout period."
                                            showBlackoutError = true
                                        }
                                    }
                                } else {
                                    blackoutErrorMessage = "End must be after start."
                                    showBlackoutError = true
                                }
                            }
                            .font(.caption2)
                            .padding(6)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(6)
                        }
                        .padding(.top, 4)
                        .alert(isPresented: $showBlackoutError) {
                            Alert(title: Text("Error"), message: Text(blackoutErrorMessage), dismissButton: .default(Text("OK")))
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)

                    // Heatmap Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Topic Heatmap")
                            .font(.headline)

                        if heatmap.isEmpty {
                            Text("Loading heatmap...")
                                .foregroundColor(.gray)
                        } else {
                            ForEach(heatmap.sorted(by: { $0.value > $1.value }), id: \.key) { topic, count in
                                HStack {
                                    Text(topic)
                                        .font(.caption2)
                                    Spacer()
                                    Text("\(count)")
                                        .font(.caption2)
                                        .foregroundColor(.blue)
                                }
                                .padding(.vertical, 2)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                .padding(.bottom, 40)
            }
            .navigationTitle("Staff Dashboard")
            .onAppear {
                isLoading = true
                consultationManager.fetchTeacherConsultations(forTeacher: "")
                consultationManager.fetchAllQuotas { quotas = $0 }
                consultationManager.getHeatmapData { heatmap = $0 }
                consultationManager.fetchBlackoutPeriods { blackoutPeriods = $0 }
                isLoading = false
            }
            .sheet(isPresented: $showQuotaDetails) {
                QuotaDetailsView(quotas: quotas)
            }
        }
    }
}

// MARK: - Supporting Views
struct DashboardStatCard: View {
    let title: String
    let value: String
    let color: Color
    var body: some View {
        VStack {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(width: 100, height: 70)
        .background(Color(.systemGray5))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct QuotaDetailsView: View {
    let quotas: [String: QuotaStatus]
    var body: some View {
        NavigationStack {
            List {
                ForEach(quotas.sorted(by: { $0.key < $1.key }), id: \.key) { email, quota in
                    HStack {
                        Text(email)
                        Spacer()
                        Text("\(quota.used)/\(quota.limit)")
                            .foregroundColor(quota.used < quota.limit ? .green : .red)
                    }
                }
            }
            .navigationTitle("Quota Details")
        }
    }
}


#Preview {
    StaffDashboardView()
}
