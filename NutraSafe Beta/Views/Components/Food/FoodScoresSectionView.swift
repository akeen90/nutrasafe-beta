import SwiftUI

struct FoodScoresSectionView: View {
    let ns: ProcessingScorer.NutraSafeProcessingGradeResult?
    let sugarScore: SugarContentScore?
    @Binding var showingInfo: Bool
    @Binding var showingSugarInfo: Bool

    private func color(for grade: String) -> Color {
        switch grade {
        case "A+", "A": return .green
        case "B": return .yellow
        case "C", "D": return .orange
        case "F": return .red
        default: return .gray
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            if let ns = ns {
                Button(action: { showingInfo = true }) {
                    VStack(spacing: 6) {
                        Text("NUTRASAFE GRADE")
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundColor(.secondary)
                            .tracking(0.5)
                        Text(ns.grade)
                            .font(.system(size: 24, weight: .black, design: .rounded))
                            .foregroundColor(color(for: ns.grade))
                        Text(ns.label)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 100)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(color(for: ns.grade).opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(color(for: ns.grade).opacity(0.2), lineWidth: 1)
                        )
                )
            }
            if let s = sugarScore, s.grade != .unknown {
                Button(action: { showingSugarInfo = true }) {
                    VStack(spacing: 6) {
                        Text("SUGAR SCORE")
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundColor(.secondary)
                            .tracking(0.5)
                        Text(s.grade.rawValue)
                            .font(.system(size: 24, weight: .black, design: .rounded))
                            .foregroundColor(s.color)
                        Text(description(for: s.grade))
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 100)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(s.color.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(s.color.opacity(0.2), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .contentShape(Rectangle())
            }
        }
    }

    private func description(for grade: SugarGrade) -> String {
        switch grade {
        case .excellent, .veryGood: return "Low Sugar"
        case .good: return "Moderate Sugar"
        case .moderate: return "High Sugar"
        case .high, .veryHigh: return "Very High Sugar"
        case .unknown: return "Unknown"
        }
    }
}
