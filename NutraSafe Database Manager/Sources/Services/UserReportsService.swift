//
//  UserReportsService.swift
//  NutraSafe Database Manager
//
//  Service for managing user-reported food issues via Cloud Functions
//

import Foundation
import SwiftUI

@MainActor
class UserReportsService: ObservableObject {
    @Published var reports: [UserReport] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var pendingCount: Int = 0

    private let baseURL = "https://us-central1-nutrasafe-705c7.cloudfunctions.net"

    // MARK: - Fetch Reports

    func fetchReports(status: UserReport.ReportStatus? = nil) async {
        isLoading = true
        errorMessage = nil

        do {
            var urlString = "\(baseURL)/getUserReports"
            if let status = status {
                urlString += "?status=\(status.rawValue)"
            }

            guard let url = URL(string: urlString) else {
                throw URLError(.badURL)
            }

            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.timeoutInterval = 30

            print("📡 Fetching user reports from: \(urlString)")

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw URLError(.badServerResponse)
            }

            print("📡 Response status: \(httpResponse.statusCode)")

            if httpResponse.statusCode != 200 {
                if let errorText = String(data: data, encoding: .utf8) {
                    print("❌ Error response: \(errorText)")
                }
                throw URLError(.badServerResponse)
            }

            // Parse the response
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

            guard let success = json?["success"] as? Bool, success,
                  let reportsArray = json?["reports"] as? [[String: Any]] else {
                throw NSError(domain: "UserReports", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])
            }

            // Parse reports
            reports = reportsArray.compactMap { parseReport(from: $0) }
            pendingCount = json?["pendingCount"] as? Int ?? reports.filter { $0.status == .pending }.count

            print("✅ Fetched \(reports.count) reports, \(pendingCount) pending")

        } catch {
            errorMessage = "Failed to fetch reports: \(error.localizedDescription)"
            print("❌ Error fetching reports: \(error)")
        }

        isLoading = false
    }

    // MARK: - Update Report Status

    func updateReportStatus(reportId: String, status: UserReport.ReportStatus, notes: String? = nil) async -> Bool {
        do {
            guard let url = URL(string: "\(baseURL)/updateUserReport") else {
                return false
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            var body: [String: Any] = [
                "reportId": reportId,
                "status": status.rawValue
            ]
            if let notes = notes {
                body["notes"] = notes
            }

            request.httpBody = try JSONSerialization.data(withJSONObject: body)

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return false
            }

            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            guard let success = json?["success"] as? Bool, success else {
                return false
            }

            // Update local state
            if let index = reports.firstIndex(where: { $0.id == reportId }) {
                reports[index].status = status
                if let notes = notes {
                    reports[index].notes = notes
                }
            }

            pendingCount = reports.filter { $0.status == .pending }.count
            return true

        } catch {
            print("❌ Error updating report status: \(error)")
            return false
        }
    }

    // MARK: - Delete Report

    func deleteReport(reportId: String) async -> Bool {
        do {
            guard let url = URL(string: "\(baseURL)/deleteUserReport") else {
                return false
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            let body: [String: Any] = ["reportId": reportId]
            request.httpBody = try JSONSerialization.data(withJSONObject: body)

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return false
            }

            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            guard let success = json?["success"] as? Bool, success else {
                return false
            }

            reports.removeAll { $0.id == reportId }
            pendingCount = reports.filter { $0.status == .pending }.count
            return true

        } catch {
            print("❌ Error deleting report: \(error)")
            return false
        }
    }

    // MARK: - Private Helpers

    private func parseReport(from dict: [String: Any]) -> UserReport? {
        guard let id = dict["id"] as? String,
              let foodName = dict["foodName"] as? String else {
            return nil
        }

        // Parse reportedAt
        let reportedAt: Date
        if let timestamp = dict["reportedAt"] as? String {
            reportedAt = ISO8601DateFormatter().date(from: timestamp) ?? Date()
        } else {
            reportedAt = Date()
        }

        // Parse reportedBy
        let reportedByDict = dict["reportedBy"] as? [String: Any]
        let reportedBy = UserReport.ReportedBy(
            userId: reportedByDict?["userId"] as? String ?? "anonymous",
            userEmail: reportedByDict?["userEmail"] as? String ?? "anonymous"
        )

        // Parse status
        let statusString = dict["status"] as? String ?? "pending"
        let status = UserReport.ReportStatus(rawValue: statusString) ?? .pending

        // Parse food data if available
        var food: UserReport.ReportedFood?
        if let foodDict = dict["food"] as? [String: Any] {
            print("📦 Parsing food data from report '\(foodName)':")
            print("   - Raw calories: \(foodDict["calories"] ?? "nil") (type: \(type(of: foodDict["calories"])))")
            print("   - Raw protein: \(foodDict["protein"] ?? "nil")")
            print("   - Raw ingredients: \(foodDict["ingredients"] ?? "nil")")

            food = UserReport.ReportedFood(
                id: foodDict["id"] as? String ?? "",
                name: foodDict["name"] as? String ?? "",
                brand: foodDict["brand"] as? String,
                barcode: foodDict["barcode"] as? String,
                calories: (foodDict["calories"] as? NSNumber)?.doubleValue ?? 0,
                protein: (foodDict["protein"] as? NSNumber)?.doubleValue ?? 0,
                carbs: (foodDict["carbs"] as? NSNumber)?.doubleValue ?? 0,
                fat: (foodDict["fat"] as? NSNumber)?.doubleValue ?? 0,
                fiber: (foodDict["fiber"] as? NSNumber)?.doubleValue ?? 0,
                sugar: (foodDict["sugar"] as? NSNumber)?.doubleValue ?? 0,
                sodium: (foodDict["sodium"] as? NSNumber)?.doubleValue ?? 0,
                servingDescription: foodDict["servingDescription"] as? String,
                servingSizeG: (foodDict["servingSizeG"] as? NSNumber)?.doubleValue,
                ingredients: foodDict["ingredients"] as? [String],
                processingScore: (foodDict["processingScore"] as? NSNumber)?.intValue,
                processingGrade: foodDict["processingGrade"] as? String,
                processingLabel: foodDict["processingLabel"] as? String,
                isVerified: foodDict["isVerified"] as? Bool ?? false
            )

            print("   - Parsed calories: \(food?.calories ?? 0)")
            print("   - Parsed protein: \(food?.protein ?? 0)")
        } else {
            print("⚠️ No food dict found in report for: \(foodName)")
        }

        return UserReport(
            id: id,
            reportedAt: reportedAt,
            reportedBy: reportedBy,
            status: status,
            foodId: dict["foodId"] as? String,
            foodName: foodName,
            brandName: dict["brandName"] as? String,
            barcode: dict["barcode"] as? String,
            food: food,
            resolvedAt: (dict["resolvedAt"] as? String).flatMap { ISO8601DateFormatter().date(from: $0) },
            resolvedBy: dict["resolvedBy"] as? String,
            notes: dict["notes"] as? String
        )
    }
}
