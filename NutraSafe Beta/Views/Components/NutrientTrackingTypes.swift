import SwiftUI

// MARK: - Supporting Types for Nutrient Tracking

struct RhythmDay {
    let date: Date
    let level: SourceLevel
}

struct NutrientItem {
    let id: String
    let name: String
}

struct CoverageRow: Identifiable, Hashable {
    let id: String
    let name: String
    let status: CoverageStatus
    let segments: [Segment]

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: CoverageRow, rhs: CoverageRow) -> Bool {
        lhs.id == rhs.id
    }
}

struct Segment: Identifiable, Hashable {
    let id = UUID()
    let date: Date
    let level: SourceLevel?
    let foods: [String]?

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Segment, rhs: Segment) -> Bool {
        lhs.id == rhs.id
    }
}

enum SourceLevel: String, Comparable {
    case none = "None"
    case trace = "Low"
    case moderate = "Moderate"
    case strong = "Strong"

    static func < (lhs: SourceLevel, rhs: SourceLevel) -> Bool {
        rank(lhs) < rank(rhs)
    }

    private static func rank(_ level: SourceLevel) -> Int {
        switch level {
        case .none: return 0
        case .trace: return 1
        case .moderate: return 2
        case .strong: return 3
        }
    }

    var color: Color {
        switch self {
        case .strong: return Color(hex: "#3FD17C")
        case .moderate: return Color(hex: "#FFA93A")
        case .trace: return Color(hex: "#57A5FF")
        case .none: return Color(hex: "#CFCFCF")
        }
    }
}

enum CoverageStatus: String {
    case consistent = "Good"
    case occasional = "Variable"
    case missing = "Low"

    var color: Color {
        switch self {
        case .consistent: return Color(hex: "#3FD17C")
        case .occasional: return Color(hex: "#FFA93A")
        case .missing: return Color(hex: "#57A5FF")
        }
    }

    var description: String {
        switch self {
        case .consistent: return "Good coverage this week"
        case .occasional: return "Varies day to day"
        case .missing: return "Could be improved"
        }
    }
}
