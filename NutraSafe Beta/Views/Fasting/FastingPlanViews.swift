import SwiftUI

struct FastingPlanCreationView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var viewModel: FastingViewModel

    @State private var selectedDuration = FastingPlanDuration.sixteenHours
    @State private var customDurationHours = 16
    @State private var selectedDays: Set<String> = []
    @State private var preferredStartTime = Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var selectedDrinksPhilosophy = AllowedDrinksPhilosophy.practical
    @State private var reminderEnabled = true
    @State private var reminderMinutes = 30
    @State private var hasLoadedExistingPlan = false
    @State private var showDeleteConfirmation = false

    let allDays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    let reminderOptions = [5, 15, 30, 60, 120]

    private var isEditing: Bool {
        viewModel.activePlan != nil
    }

    private var canSave: Bool {
        !selectedDays.isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Fasting Duration Card
                    fastingDurationCard

                    // Days of Week Card
                    daysOfWeekCard

                    // Start Time Card
                    startTimeCard

                    // Drinks Philosophy Card
                    drinksPhilosophyCard

                    // Reminders Card
                    remindersCard

                    // Delete Plan Option (only when editing)
                    if isEditing {
                        deletePlanButton
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 100)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(isEditing ? "Edit Fasting Plan" : "Create Fasting Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                saveButton
            }
            .onAppear {
                loadExistingPlan()
            }
            .alert("Delete Fasting Plan?", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    Task {
                        if let plan = viewModel.activePlan {
                            await viewModel.deletePlan(plan)
                        }
                        dismiss()
                    }
                }
            } message: {
                Text("This will permanently delete your fasting plan. Your fasting history will be preserved.")
            }
        }
    }

    // MARK: - Fasting Duration Card
    private var fastingDurationCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Fasting Duration", systemImage: "clock.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.secondary)

            VStack(spacing: 0) {
                ForEach(FastingPlanDuration.allCases, id: \.self) { duration in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedDuration = duration
                        }
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(duration.displayName)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.primary)
                                Text(duration.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if selectedDuration == duration {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 22))
                                    .foregroundColor(.green)
                            } else {
                                Circle()
                                    .strokeBorder(Color.gray.opacity(0.3), lineWidth: 1.5)
                                    .frame(width: 22, height: 22)
                            }
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(selectedDuration == duration ? Color.green.opacity(0.08) : Color.clear)
                    }
                    .buttonStyle(.plain)

                    if duration != FastingPlanDuration.allCases.last {
                        Divider()
                            .padding(.leading, 16)
                    }
                }

                // Custom hours stepper
                if selectedDuration == .custom {
                    Divider()
                        .padding(.leading, 16)
                    HStack {
                        Text("Custom Duration")
                            .font(.system(size: 16, weight: .medium))
                        Spacer()
                        Stepper("\(customDurationHours)h", value: $customDurationHours, in: 1...72)
                            .labelsHidden()
                        Text("\(customDurationHours) hours")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.green)
                            .frame(width: 80, alignment: .trailing)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorScheme == .dark ? Color(.systemGray6) : .white)
            )
        }
    }

    // MARK: - Days of Week Card
    private var daysOfWeekCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Fasting Days", systemImage: "calendar")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.secondary)
                Spacer()
                Button(selectedDays.count == 7 ? "Clear All" : "Select All") {
                    withAnimation {
                        if selectedDays.count == 7 {
                            selectedDays.removeAll()
                        } else {
                            selectedDays = Set(allDays)
                        }
                    }
                }
                .font(.caption.weight(.medium))
                .foregroundColor(.blue)
            }

            HStack(spacing: 8) {
                ForEach(allDays, id: \.self) { day in
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            if selectedDays.contains(day) {
                                selectedDays.remove(day)
                            } else {
                                selectedDays.insert(day)
                            }
                        }
                    } label: {
                        Text(String(day.prefix(1)))
                            .font(.system(size: 14, weight: .semibold))
                            .frame(width: 40, height: 40)
                            .background(
                                Circle()
                                    .fill(selectedDays.contains(day) ? Color.green : Color.gray.opacity(0.15))
                            )
                            .foregroundColor(selectedDays.contains(day) ? .white : .primary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorScheme == .dark ? Color(.systemGray6) : .white)
            )

            if selectedDays.isEmpty {
                Text("Select at least one day to create your plan")
                    .font(.caption)
                    .foregroundColor(.orange)
            } else {
                Text("\(selectedDays.count) day\(selectedDays.count == 1 ? "" : "s") per week")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Start Time Card
    private var startTimeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Start Time", systemImage: "clock.badge.checkmark")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.secondary)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Daily Fast Begins")
                        .font(.system(size: 16, weight: .medium))
                    Text("Your fast will start at this time each day")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                DatePicker("", selection: $preferredStartTime, displayedComponents: .hourAndMinute)
                    .labelsHidden()
                    .tint(.green)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorScheme == .dark ? Color(.systemGray6) : .white)
            )
        }
    }

    // MARK: - Drinks Philosophy Card
    private var drinksPhilosophyCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("What's Allowed During Fast", systemImage: "drop.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.secondary)

            VStack(spacing: 0) {
                ForEach(AllowedDrinksPhilosophy.allCases, id: \.self) { philosophy in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedDrinksPhilosophy = philosophy
                        }
                    } label: {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: philosophyIcon(philosophy))
                                .font(.system(size: 20))
                                .foregroundColor(philosophyColor(philosophy))
                                .frame(width: 28)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(philosophy.displayName)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.primary)
                                Text(philosophy.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            Spacer()

                            if selectedDrinksPhilosophy == philosophy {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 22))
                                    .foregroundColor(.green)
                            } else {
                                Circle()
                                    .strokeBorder(Color.gray.opacity(0.3), lineWidth: 1.5)
                                    .frame(width: 22, height: 22)
                            }
                        }
                        .padding(.vertical, 14)
                        .padding(.horizontal, 16)
                        .background(selectedDrinksPhilosophy == philosophy ? philosophyColor(philosophy).opacity(0.08) : Color.clear)
                    }
                    .buttonStyle(.plain)

                    if philosophy != AllowedDrinksPhilosophy.allCases.last {
                        Divider()
                            .padding(.leading, 56)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorScheme == .dark ? Color(.systemGray6) : .white)
            )

            // Explanation text
            Text(philosophyExplanation(selectedDrinksPhilosophy))
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)
        }
    }

    private func philosophyIcon(_ philosophy: AllowedDrinksPhilosophy) -> String {
        switch philosophy {
        case .strict: return "leaf.fill"
        case .practical: return "cup.and.saucer.fill"
        }
    }

    private func philosophyColor(_ philosophy: AllowedDrinksPhilosophy) -> Color {
        switch philosophy {
        case .strict: return .green
        case .practical: return .blue
        }
    }

    private func philosophyExplanation(_ philosophy: AllowedDrinksPhilosophy) -> String {
        switch philosophy {
        case .strict:
            return "Most strict approach - only zero-calorie drinks with no artificial sweeteners. Best for autophagy and metabolic benefits."
        case .practical:
            return "Allows sugar-free drinks like Diet Coke or Coke Zero. Won't prompt to end fast for these items."
        }
    }

    // MARK: - Reminders Card
    private var remindersCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Reminders", systemImage: "bell.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.secondary)

            VStack(spacing: 0) {
                Toggle(isOn: $reminderEnabled) {
                    HStack {
                        Text("Enable Reminders")
                            .font(.system(size: 16, weight: .medium))
                    }
                }
                .tint(.green)
                .padding(.vertical, 12)
                .padding(.horizontal, 16)

                if reminderEnabled {
                    Divider()
                        .padding(.leading, 16)

                    HStack {
                        Text("Remind me before fast ends")
                            .font(.system(size: 16, weight: .medium))
                        Spacer()
                        Menu {
                            ForEach(reminderOptions, id: \.self) { minutes in
                                Button {
                                    reminderMinutes = minutes
                                } label: {
                                    HStack {
                                        Text(formatReminderTime(minutes))
                                        if reminderMinutes == minutes {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text(formatReminderTime(reminderMinutes))
                                    .font(.system(size: 16, weight: .medium))
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.system(size: 12))
                            }
                            .foregroundColor(.green)
                        }
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorScheme == .dark ? Color(.systemGray6) : .white)
            )
        }
    }

    private func formatReminderTime(_ minutes: Int) -> String {
        if minutes >= 60 {
            return "\(minutes / 60) hour\(minutes >= 120 ? "s" : "")"
        }
        return "\(minutes) min"
    }

    // MARK: - Delete Plan Button
    private var deletePlanButton: some View {
        Button {
            showDeleteConfirmation = true
        } label: {
            HStack {
                Image(systemName: "trash")
                Text("Delete Fasting Plan")
            }
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.red)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.red.opacity(0.1))
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Save Button
    private var saveButton: some View {
        VStack(spacing: 0) {
            Divider()
            Button(action: createPlan) {
                Text(isEditing ? "Update Plan" : "Create Plan")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(canSave ? Color.green : Color.gray)
                    )
            }
            .disabled(!canSave)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(colorScheme == .dark ? Color(.systemBackground) : .white)
        }
    }

    // MARK: - Logic
    private func loadExistingPlan() {
        guard !hasLoadedExistingPlan, let plan = viewModel.activePlan else { return }
        hasLoadedExistingPlan = true

        selectedDays = Set(plan.daysOfWeek)
        preferredStartTime = plan.preferredStartTime
        selectedDrinksPhilosophy = plan.allowedDrinks
        reminderEnabled = plan.reminderEnabled
        reminderMinutes = plan.reminderMinutesBeforeEnd

        switch plan.durationHours {
        case 12: selectedDuration = .twelveHours
        case 16: selectedDuration = .sixteenHours
        case 18: selectedDuration = .eighteenHours
        case 20: selectedDuration = .twentyHours
        case 24: selectedDuration = .twentyFourHours
        default:
            selectedDuration = .custom
            customDurationHours = plan.durationHours
        }
    }

    private func createPlan() {
        let durationHours = selectedDuration == .custom ? customDurationHours : selectedDuration.hours
        let sortedDays = allDays.filter { selectedDays.contains($0) }

        let finalName: String
        switch durationHours {
        case 12: finalName = "12:12 Fasting Plan"
        case 16: finalName = "16:8 Fasting Plan"
        case 18: finalName = "18:6 Fasting Plan"
        case 20: finalName = "20:4 Fasting Plan"
        case 24: finalName = "OMAD Plan"
        default: finalName = "\(durationHours)-Hour Fast"
        }

        Task {
            await viewModel.createFastingPlan(
                name: finalName,
                durationHours: durationHours,
                daysOfWeek: sortedDays,
                preferredStartTime: preferredStartTime,
                allowedDrinks: selectedDrinksPhilosophy,
                reminderEnabled: reminderEnabled,
                reminderMinutesBeforeEnd: reminderMinutes
            )
            dismiss()
        }
    }
}

// MARK: - Supporting Views (kept for compatibility)
struct FastingPlanManagementView: View {
    @ObservedObject var viewModel: FastingViewModel
    @State private var showingCreatePlan = false
    @State private var planToDelete: FastingPlan?
    @State private var showingDeleteConfirmation = false

    var body: some View {
        NavigationStack {
            List {
                if let activePlan = viewModel.activePlan {
                    Section(header: Text("Active Plan")) {
                        ActivePlanCard(plan: activePlan)
                    }
                }

                if !viewModel.allPlans.isEmpty {
                    Section(header: Text("All Plans")) {
                        ForEach(viewModel.allPlans) { plan in
                            PlanRow(plan: plan, isActive: plan.id == viewModel.activePlan?.id)
                                .swipeActions(edge: .trailing) {
                                    if !plan.active {
                                        Button(role: .destructive) {
                                            planToDelete = plan
                                            showingDeleteConfirmation = true
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                }
                                .swipeActions(edge: .leading) {
                                    if !plan.active {
                                        Button {
                                            Task {
                                                await viewModel.setActivePlan(plan)
                                            }
                                        } label: {
                                            Label("Activate", systemImage: "checkmark.circle")
                                        }
                                        .tint(.green)
                                    }
                                }
                        }
                    }
                }

                if viewModel.allPlans.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "clock.badge.exclamationmark")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)

                        Text("No Fasting Plans")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text("Create your first fasting plan to get started with structured fasting.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                }
            }
            .navigationTitle("Fasting Plans")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingCreatePlan = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreatePlan) {
                FastingPlanCreationView(viewModel: viewModel)
            }
            .alert("Delete Plan", isPresented: $showingDeleteConfirmation, presenting: planToDelete) { plan in
                Button("Delete", role: .destructive) {
                    Task {
                        await viewModel.deletePlan(plan)
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: { plan in
                Text("Are you sure you want to delete '\(plan.name)'?")
            }
        }
    }
}

struct ActivePlanCard: View {
    let plan: FastingPlan

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(plan.name)
                    .font(.headline)
                Spacer()
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }

            HStack {
                Label("\(plan.durationHours)h fast", systemImage: "clock")
                Spacer()
                Label(plan.daysOfWeek.joined(separator: ", "), systemImage: "calendar")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct PlanRow: View {
    let plan: FastingPlan
    let isActive: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(plan.name)
                    .font(.headline)
                Text("\(plan.durationHours)h • \(plan.daysOfWeek.count) days/week")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            if isActive {
                Text("Active")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.15))
                    .cornerRadius(8)
            }
        }
        .padding(.vertical, 4)
    }
}
