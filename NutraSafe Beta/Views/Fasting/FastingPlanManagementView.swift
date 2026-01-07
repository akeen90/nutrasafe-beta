import SwiftUI

struct FastingPlanManagementView: View {
    @ObservedObject var viewModel: FastingViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingCreatePlan = false
    @State private var planToEdit: FastingPlan?
    @State private var showingDeleteAlert = false
    @State private var planToDelete: FastingPlan?

    var body: some View {
        List {
            // Active Plan Section
            if let activePlan = viewModel.activePlan {
                Section(header: Text("Active Plan")) {
                    PlanRow(
                        plan: activePlan,
                        isActive: true,
                        onEdit: {
                            planToEdit = activePlan
                        },
                        onDelete: nil // Can't delete active plan
                    )
                }
            }

            // Other Plans Section
            if !viewModel.allPlans.filter({ !($0.active) }).isEmpty {
                Section(header: Text("Other Plans")) {
                    ForEach(viewModel.allPlans.filter { !$0.active }) { plan in
                        PlanRow(
                            plan: plan,
                            isActive: false,
                            onEdit: {
                                planToEdit = plan
                            },
                            onDelete: {
                                planToDelete = plan
                                showingDeleteAlert = true
                            },
                            onSetActive: {
                                Task {
                                    await viewModel.setActivePlan(plan)
                                }
                            }
                        )
                    }
                }
            }

            // Create New Plan Button
            Section {
                Button {
                    showingCreatePlan = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.blue)
                        Text("Create New Plan")
                            .fontWeight(.medium)
                    }
                }
            }
        }
        .navigationTitle("Fasting Plans")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showingCreatePlan) {
            FastingPlanCreationView(viewModel: viewModel)
        }
        .fullScreenCover(item: $planToEdit) { plan in
            FastingPlanEditView(viewModel: viewModel, plan: plan)
        }
        .alert("Delete Plan", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let plan = planToDelete {
                    Task {
                        await viewModel.deletePlan(plan)
                        planToDelete = nil
                    }
                }
            }
        } message: {
            Text("Are you sure you want to delete this fasting plan? This action cannot be undone.")
        }
        .task {
            await viewModel.loadAllPlans()
        }
    }
}

struct PlanRow: View {
    let plan: FastingPlan
    let isActive: Bool
    let onEdit: () -> Void
    let onDelete: (() -> Void)?
    var onSetActive: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(plan.name)
                        .font(.headline)
                        .foregroundColor(.primary)

                    HStack(spacing: 12) {
                        Label(plan.durationDisplay, systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        if !plan.daysOfWeek.isEmpty {
                            Label("\(plan.daysOfWeek.count) days/week", systemImage: "calendar")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    HStack(spacing: 6) {
                        Image(systemName: iconForPhilosophy(plan.allowedDrinks))
                            .font(.caption2)
                            .foregroundColor(colorForPhilosophy(plan.allowedDrinks))

                        Text(plan.allowedDrinks.displayName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                if isActive {
                    Text("ACTIVE")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green)
                        .cornerRadius(4)
                }
            }

            // Action Buttons
            HStack(spacing: 12) {
                Button {
                    onEdit()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "pencil")
                        Text("Edit")
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
                .buttonStyle(.plain)

                if let setActive = onSetActive {
                    Button {
                        setActive()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle")
                            Text("Set Active")
                        }
                        .font(.caption)
                        .foregroundColor(.green)
                    }
                    .buttonStyle(.plain)
                }

                if let delete = onDelete {
                    Spacer()

                    Button {
                        delete()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "trash")
                            Text("Delete")
                        }
                        .font(.caption)
                        .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 4)
        }
        .padding(.vertical, 4)
    }

    private func iconForPhilosophy(_ philosophy: AllowedDrinksPhilosophy) -> String {
        switch philosophy {
        case .strict: return "drop.fill"
        case .practical: return "leaf.fill"
        case .lenient: return "heart.fill"
        }
    }

    private func colorForPhilosophy(_ philosophy: AllowedDrinksPhilosophy) -> Color {
        switch philosophy {
        case .strict: return .blue
        case .practical: return .green
        case .lenient: return .pink
        }
    }
}

struct FastingPlanEditView: View {
    @ObservedObject var viewModel: FastingViewModel
    let plan: FastingPlan
    @Environment(\.dismiss) private var dismiss

    @State private var selectedDuration: FastingPlanDuration
    @State private var customDurationHours: Int
    @State private var selectedDays: Set<String>
    @State private var allowedDrinks: AllowedDrinksPhilosophy
    @State private var reminderEnabled: Bool
    @State private var reminderMinutes: Int

    init(viewModel: FastingViewModel, plan: FastingPlan) {
        self.viewModel = viewModel
        self.plan = plan

        // Determine duration type
        if let duration = FastingPlanDuration.allCases.first(where: { $0.hours == plan.durationHours }) {
            _selectedDuration = State(initialValue: duration)
            _customDurationHours = State(initialValue: 16)
        } else {
            _selectedDuration = State(initialValue: .custom)
            _customDurationHours = State(initialValue: plan.durationHours)
        }

        _selectedDays = State(initialValue: Set(plan.daysOfWeek))
        _allowedDrinks = State(initialValue: plan.allowedDrinks)
        _reminderEnabled = State(initialValue: plan.reminderEnabled)
        _reminderMinutes = State(initialValue: plan.reminderMinutesBeforeEnd)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Plan Details")) {
                    Picker("Fasting Duration", selection: $selectedDuration) {
                        ForEach(FastingPlanDuration.allCases, id: \.self) { duration in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(duration.displayName)
                                    .font(.headline)
                                Text(duration.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .tag(duration)
                        }
                    }
                    .pickerStyle(.inline)

                    if selectedDuration == .custom {
                        Stepper("Custom Duration: \(customDurationHours)h", value: $customDurationHours, in: 1...72)
                    }
                }

                Section(header: Text("Active Days")) {
                    ForEach(Calendar.current.shortWeekdaySymbols, id: \.self) { day in
                        Toggle(day, isOn: Binding(
                            get: { selectedDays.contains(day) },
                            set: { isSelected in
                                if isSelected {
                                    selectedDays.insert(day)
                                } else {
                                    selectedDays.remove(day)
                                }
                            }
                        ))
                    }
                }

                Section(header: Text("Allowed Drinks")) {
                    Picker("Philosophy", selection: $allowedDrinks) {
                        ForEach(AllowedDrinksPhilosophy.allCases, id: \.self) { philosophy in
                            Text(philosophy.displayName).tag(philosophy)
                        }
                    }
                    .pickerStyle(.segmented)

                    Text(allowedDrinks.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section(header: Text("Reminders")) {
                    Toggle("Enable Reminders", isOn: $reminderEnabled)

                    if reminderEnabled {
                        Stepper("Notify \(reminderMinutes) min before end", value: $reminderMinutes, in: 5...120, step: 5)
                    }
                }

                Section {
                    Button {
                        Task {
                            await savePlan()
                        }
                    } label: {
                        HStack {
                            Spacer()
                            Text("Save Changes")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(selectedDays.isEmpty)
                }
            }
            .navigationTitle("Edit Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func savePlan() async {
        var updatedPlan = plan
        updatedPlan.durationHours = selectedDuration == .custom ? customDurationHours : selectedDuration.hours
        updatedPlan.daysOfWeek = Array(selectedDays)
        updatedPlan.allowedDrinks = allowedDrinks
        updatedPlan.reminderEnabled = reminderEnabled
        updatedPlan.reminderMinutesBeforeEnd = reminderMinutes

        await viewModel.updatePlan(updatedPlan)
        dismiss()
    }
}

#Preview {
    NavigationStack {
        FastingPlanManagementView(viewModel: FastingViewModel.preview)
    }
}
