import SwiftUI
import Charts

struct FastingInsightsView: View {
    @ObservedObject var viewModel: FastingViewModel
    @State private var selectedTimeRange = TimeRange.week
    @State private var showingAllSessions = false
    
    enum TimeRange: String, CaseIterable {
        case week = "7 Days"
        case month = "30 Days"
        case all = "All Time"
        
        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            case .all: return Int.max
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header with time range selector
                    VStack(spacing: 16) {
                        HStack {
                            Text("Fasting Insights")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            
                            Spacer()
                            
                            Picker("Time Range", selection: $selectedTimeRange) {
                                ForEach(TimeRange.allCases, id: \.self) { range in
                                    Text(range.rawValue).tag(range)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                        
                        Text("Progress compounds. Consistency > perfection.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    // Key Metrics
                    if let analytics = viewModel.analytics {
                        KeyMetricsSection(analytics: analytics, timeRange: selectedTimeRange)
                    }
                    
                    // Progress Chart
                    if !filteredSessions.isEmpty {
                        ProgressChartSection(sessions: filteredSessions)
                    }
                    
                    // Phase Distribution
                    if let analytics = viewModel.analytics {
                        PhaseDistributionSection(analytics: analytics)
                    }
                    
                    // Consistency Analysis
                    if let analytics = viewModel.analytics {
                        ConsistencySection(analytics: analytics)
                    }
                    
                    // Recent Sessions
                    if !recentSessions.isEmpty {
                        RecentSessionsSection(sessions: recentSessions) {
                            showingAllSessions = true
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingAllSessions) {
                AllSessionsView(viewModel: viewModel)
                    .presentationDragIndicator(.visible)
                    .presentationBackground(Color(.systemBackground))
            }
        }
    }
    
    private var filteredSessions: [FastingSession] {
        let calendar = Calendar.current
        let now = Date()
        
        if selectedTimeRange == .all {
            return viewModel.recentSessions
        }
        
        guard let startDate = calendar.date(byAdding: .day, value: -selectedTimeRange.days, to: now) else {
            return []
        }
        
        return viewModel.recentSessions.filter { $0.startTime >= startDate }
    }
    
    private var recentSessions: [FastingSession] {
        Array(filteredSessions.prefix(5))
    }
}

struct KeyMetricsSection: View {
    let analytics: FastingAnalytics
    let timeRange: FastingInsightsView.TimeRange
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(.blue)
                Text("Key Metrics")
                    .font(.headline)
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                MetricCard(
                    title: "Total Fasts",
                    value: "\(analytics.totalFastsCompleted)",
                    subtitle: timeRange.rawValue,
                    icon: "checkmark.circle",
                    color: .green
                )
                
                MetricCard(
                    title: "Success Rate",
                    value: String(format: "%.0f%%", analytics.averageCompletionPercentage),
                    subtitle: "Average",
                    icon: "percent",
                    color: .blue
                )
                
                MetricCard(
                    title: "Avg Duration",
                    value: analytics.averageDurationFormatted,
                    subtitle: "vs Goal",
                    icon: "clock.fill",
                    color: .purple
                )
                
                MetricCard(
                    title: "Longest Fast",
                    value: analytics.longestFastFormatted,
                    subtitle: "Record",
                    icon: "trophy.fill",
                    color: .orange
                )
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.blue.opacity(0.05))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.blue.opacity(0.2), lineWidth: 1)
        )
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .opacity(0.8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

struct ProgressChartSection: View {
    let sessions: [FastingSession]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            headerView

            if sessions.count > 1 {
                progressChart
            } else {
                emptyDataView
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.purple.opacity(0.05))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.purple.opacity(0.2), lineWidth: 1)
        )
    }

    private var headerView: some View {
        HStack {
            Image(systemName: "chart.xyaxis.line")
                .foregroundColor(.purple)
            Text("Progress Over Time")
                .font(.headline)
        }
    }

    private var progressChart: some View {
        Chart {
            ForEach(Array(sessions.enumerated()), id: \.element.id) { index, session in
                LineMark(
                    x: .value("Date", session.startTime),
                    y: .value("Duration (hours)", session.actualDurationHours)
                )
                .foregroundStyle(Color.blue)
                .symbol(Circle())
                .symbolSize(50)

                AreaMark(
                    x: .value("Date", session.startTime),
                    y: .value("Duration (hours)", session.actualDurationHours)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.blue.opacity(0.3), Color.blue.opacity(0.1)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
        }
        .frame(height: 200)
        .chartYScale(domain: 0...maxDuration)
        .chartXAxis {
            AxisMarks { value in
                if let date = value.as(Date.self) {
                    AxisValueLabel {
                        Text(date.formatted(.dateTime.month(.abbreviated).day()))
                            .font(.caption)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks { value in
                if let hours = value.as(Double.self) {
                    AxisValueLabel {
                        Text("\(Int(hours))h")
                            .font(.caption)
                    }
                }
            }
        }
    }

    private var emptyDataView: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 50))
                .foregroundColor(.secondary)

            Text("Not Enough Data")
                .font(.headline)

            Text("Complete a few more fasting sessions to see your progress chart.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
    }

    private var maxDuration: Double {
        let max = sessions.map { $0.actualDurationHours }.max() ?? 24
        return max * 1.1 // Add 10% padding
    }
}

struct PhaseDistributionSection: View {
    let analytics: FastingAnalytics

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            headerView

            if !analytics.phaseDistribution.isEmpty {
                phaseChart
            } else {
                emptyPhaseView
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.05))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.orange.opacity(0.2), lineWidth: 1)
        )
    }

    private var headerView: some View {
        HStack {
            Image(systemName: "timeline.selection")
                .foregroundColor(.orange)
            Text("Phase Distribution")
                .font(.headline)
        }
    }

    private var phaseChart: some View {
        Chart {
            ForEach(Array(analytics.phaseDistribution.sorted(by: { $0.key.timeRange.lowerBound < $1.key.timeRange.lowerBound })), id: \.key) { phase, count in
                BarMark(
                    x: .value("Count", count),
                    y: .value("Phase", phase.displayName)
                )
                .foregroundStyle(by: .value("Phase", phase.displayName))
                .annotation(position: .trailing) {
                    Text("\(count)")
                        .font(.caption)
                }
            }
        }
        .frame(height: 200)
        .chartLegend(position: .bottom, spacing: 8)
        .chartXAxis {
            AxisMarks { value in
                if let count = value.as(Int.self) {
                    AxisValueLabel {
                        Text("\(count)")
                            .font(.caption)
                    }
                }
            }
        }
    }

    private var emptyPhaseView: some View {
        VStack(spacing: 12) {
            Image(systemName: "timeline.selection")
                .font(.system(size: 50))
                .foregroundColor(.secondary)

            Text("No Phase Data")
                .font(.headline)

            Text("Complete some fasting sessions to see which phases you reach most often.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
    }
}

struct ConsistencySection: View {
    let analytics: FastingAnalytics
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .foregroundColor(.green)
                Text("Consistency Analysis")
                    .font(.headline)
            }
            
            VStack(spacing: 16) {
                if let mostConsistentDay = analytics.mostConsistentDay {
                    ConsistencyMetric(
                        title: "Most Consistent Day",
                        value: mostConsistentDay,
                        icon: "calendar.circle.fill",
                        color: .green
                    )
                }
                
                ConsistencyMetric(
                    title: "Weekly Average",
                    value: String(format: "%.1f", weeklyAverage),
                    subtitle: "fasts per week",
                    icon: "chart.bar.fill",
                    color: .blue
                )
                
                ConsistencyMetric(
                    title: "Current Streak",
                    value: "\(currentStreak)",
                    subtitle: "completed sessions",
                    icon: "flame.fill",
                    color: .orange
                )
            }
            
            Text("Consistency builds habits. Every fast counts toward your goals.")
                .font(.caption)
                .foregroundColor(.secondary)
                .italic()
                .padding(.top, 8)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.green.opacity(0.05))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.green.opacity(0.2), lineWidth: 1)
        )
    }
    
    private var weeklyAverage: Double {
        let sessions = analytics.last30DaysSessions
        guard !sessions.isEmpty else { return 0 }
        return Double(sessions.count) / 4.3 // Roughly 4.3 weeks per month
    }
    
    private var currentStreak: Int {
        let sessions = analytics.last30DaysSessions
            .sorted { $0.startTime > $1.startTime }
        
        var streak = 0
        for session in sessions {
            if session.completionStatus == .completed || session.completionStatus == .overGoal {
                streak += 1
            } else {
                break
            }
        }
        return streak
    }
}

struct ConsistencyMetric: View {
    let title: String
    let value: String
    var subtitle: String? = nil
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.headline)
                    .fontWeight(.bold)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .opacity(0.8)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

struct RecentSessionsSection: View {
    let sessions: [FastingSession]
    let onViewAll: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundColor(.teal)
                Text("Recent Sessions")
                    .font(.headline)
                
                Spacer()
                
                if sessions.count > 5 {
                    Button("View All") {
                        onViewAll()
                    }
                    .font(.caption)
                }
            }
            
            LazyVStack(spacing: 8) {
                ForEach(sessions) { session in
                    SessionRow(session: session)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.teal.opacity(0.05))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.teal.opacity(0.2), lineWidth: 1)
        )
    }
}

struct SessionRow: View {
    let session: FastingSession
    
    var body: some View {
        HStack(spacing: 12) {
            // Status indicator
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(session.completionStatus.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text(session.startTime.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("\(session.actualDurationHours, specifier: "%.1f")h")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if session.targetDurationHours > 0 {
                        Text("of \(session.targetDurationHours)h")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        let progress = min(session.progressPercentage * 100, 100)
                        Text("• \(Int(progress))%")
                            .font(.caption)
                            .foregroundColor(progress >= 100 ? .green : .orange)
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    private var statusColor: Color {
        switch session.completionStatus {
        case .completed, .overGoal:
            return .green
        case .earlyEnd:
            return .orange
        case .failed:
            return .red
        case .skipped:
            return .gray
        case .active:
            return .blue
        }
    }
}

struct AllSessionsView: View {
    @ObservedObject var viewModel: FastingViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.recentSessions) { session in
                    NavigationLink {
                        SessionDetailView(session: session)
                    } label: {
                        SessionRow(session: session)
                    }
                }
            }
            .navigationTitle("All Sessions")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct SessionDetailView: View {
    let session: FastingSession
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Session Summary Card
                SessionSummaryCard(session: session)
                
                // Phase Details
                PhaseDetailsCard(session: session)
                
                // Notes Card
                if let notes = session.notes, !notes.isEmpty {
                    NotesCard(notes: notes)
                }
            }
            .padding()
        }
        .navigationTitle("Session Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct SessionSummaryCard: View {
    let session: FastingSession
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(statusColor)
                Text("Session Summary")
                    .font(.headline)
            }
            
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Status")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(session.completionStatus.displayName)
                            .font(.headline)
                            .foregroundColor(statusColor)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Duration")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(session.actualDurationHours, specifier: "%.1f")h")
                            .font(.headline)
                    }
                }
                
                Divider()
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Start Time")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(session.startTime.formatted(date: .abbreviated, time: .shortened))
                            .font(.subheadline)
                    }
                    
                    Spacer()
                    
                    if let endTime = session.endTime {
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("End Time")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(endTime.formatted(date: .abbreviated, time: .shortened))
                                .font(.subheadline)
                        }
                    }
                }
                
                if session.targetDurationHours > 0 {
                    Divider()
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Target Duration")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(session.targetDurationHours)h")
                                .font(.subheadline)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Progress")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(Int(session.progressPercentage * 100))%")
                                .font(.subheadline)
                                .foregroundColor(progressColor)
                        }
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(statusColor.opacity(0.1))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(statusColor.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var statusColor: Color {
        switch session.completionStatus {
        case .completed, .overGoal:
            return .green
        case .earlyEnd:
            return .orange
        case .failed:
            return .red
        case .skipped:
            return .gray
        case .active:
            return .blue
        }
    }
    
    private var progressColor: Color {
        session.progressPercentage >= 1.0 ? .green : .orange
    }
}

struct PhaseDetailsCard: View {
    let session: FastingSession
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "timeline.selection")
                    .foregroundColor(.purple)
                Text("Phases Reached")
                    .font(.headline)
            }
            
            if session.phasesReached.isEmpty {
                Text("No phases reached in this session")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(session.phasesReached, id: \.self) { phase in
                        PhaseReachedRow(phase: phase)
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.purple.opacity(0.05))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.purple.opacity(0.2), lineWidth: 1)
        )
    }
}

struct PhaseReachedRow: View {
    let phase: FastingPhase
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(phase.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(phase.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("\(phase.timeRange.lowerBound)h+")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct NotesCard: View {
    let notes: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "note.text")
                    .foregroundColor(.brown)
                Text("Notes")
                    .font(.headline)
            }
            
            Text(notes)
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.brown.opacity(0.05))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.brown.opacity(0.2), lineWidth: 1)
        )
    }
}

#Preview {
    NavigationStack {
        FastingInsightsView(viewModel: FastingViewModel.preview)
    }
}