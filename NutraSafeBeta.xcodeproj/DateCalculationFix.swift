import Foundation

// MARK: - Date Calculation Utilities
// Fix for inconsistent "days left" calculations across list and detail views

extension Calendar {
    /// Calculate days between two dates consistently
    /// This ensures both list and detail views use the same calculation method
    func daysBetween(_ startDate: Date, and endDate: Date) -> Int {
        let startOfStartDate = self.startOfDay(for: startDate)
        let startOfEndDate = self.startOfDay(for: endDate)
        
        let components = self.dateComponents([.day], from: startOfStartDate, to: startOfEndDate)
        return components.day ?? 0
    }
}

// MARK: - Centralized Date Calculator
class ItemDateCalculator {
    static let shared = ItemDateCalculator()
    private init() {}
    
    /// Calculate days remaining until expiry
    /// Use this method consistently in both list and detail views
    func daysUntilExpiry(from currentDate: Date = Date(), to expiryDate: Date) -> Int {
        let calendar = Calendar.current
        return calendar.daysBetween(currentDate, and: expiryDate)
    }
    
    /// Format days remaining as user-friendly text
    func formatDaysRemaining(_ days: Int) -> String {
        switch days {
        case ..<0:
            return "Expired \(abs(days)) day\(abs(days) == 1 ? "" : "s") ago"
        case 0:
            return "Expires today"
        case 1:
            return "1 day left"
        default:
            return "\(days) days left"
        }
    }
    
    /// Get expiry status for UI styling
    func getExpiryStatus(daysRemaining: Int) -> ExpiryStatus {
        switch daysRemaining {
        case ..<0:
            return .expired
        case 0...2:
            return .expiringSoon
        case 3...7:
            return .expiringSoon
        default:
            return .fresh
        }
    }
}

enum ExpiryStatus {
    case expired
    case expiringSoon  
    case expiring
    case fresh
    
    var color: Color {
        switch self {
        case .expired:
            return .red
        case .expiringSoon:
            return .orange
        case .expiring:
            return .yellow
        case .fresh:
            return .green
        }
    }
}

// MARK: - Example Usage in Views

/*
// In your List View:
struct ItemListView: View {
    let items: [Item]
    
    var body: some View {
        List(items) { item in
            HStack {
                Text(item.name)
                Spacer()
                // Use centralized calculator
                Text(ItemDateCalculator.shared.formatDaysRemaining(
                    ItemDateCalculator.shared.daysUntilExpiry(to: item.expiryDate)
                ))
                .foregroundColor(ItemDateCalculator.shared.getExpiryStatus(
                    daysRemaining: ItemDateCalculator.shared.daysUntilExpiry(to: item.expiryDate)
                ).color)
            }
        }
    }
}

// In your Detail View:
struct ItemDetailView: View {
    let item: Item
    
    var body: some View {
        VStack {
            Text(item.name)
            
            // Use the SAME centralized calculator
            let daysRemaining = ItemDateCalculator.shared.daysUntilExpiry(to: item.expiryDate)
            Text(ItemDateCalculator.shared.formatDaysRemaining(daysRemaining))
                .foregroundColor(ItemDateCalculator.shared.getExpiryStatus(daysRemaining: daysRemaining).color)
        }
    }
}
*/

// MARK: - Migration Helper
// If you have existing date calculation code, use this to find and replace inconsistencies

extension Date {
    /// DEPRECATED: Don't use this method - use ItemDateCalculator.shared.daysUntilExpiry instead
    @available(*, deprecated, message: "Use ItemDateCalculator.shared.daysUntilExpiry for consistent calculations")
    func daysUntil(_ date: Date) -> Int {
        // This may have been causing the inconsistency
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: self, to: date)
        return components.day ?? 0
    }
}