import SwiftUI

struct FastingPlanCreationView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: FastingViewModel

    @State private var selectedDuration = FastingPlanDuration.sixteenHours
    @State private var customDurationHours = 16
    @State private var selectedDays: Set<String> = []
    @State private var preferredStartTime = Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: Date()) ?? Date() // Default to 8:00 PM
    @State private var selectedDrinksPhilosophy = AllowedDrinksPhilosophy.practical
    @State private var reminderEnabled = true
    @State private var reminderMinutes = 30
    @State private var hasLoadedExistingPlan = false

    let allDays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    let reminderOptions = [5, 15, 30, 60, 120]

    /// Whether we're editing an existing plan
    private var isEditing: Bool {
        viewModel.activePlan != nil
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
                        Stepper("Custom Hours: \(customDurationHours)", value: $customDurationHours, in: 1...72)
                    }
                }
                
                Section(header: Text("Days of Week")) {
                    ForEach(allDays, id: \.self) { day in
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

                Section {
                    DatePicker("Start Time", selection: $preferredStartTime, displayedComponents: .hourAndMinute)
                } header: {
                    Text("Scheduled Start Time")
                } footer: {
                    Text("Your fast will automatically start at this time on selected days")
                }

                Section(header: Text("Allowed Drinks Philosophy")) {
                    Picker("Philosophy", selection: $selectedDrinksPhilosophy) {
                        ForEach(AllowedDrinksPhilosophy.allCases, id: \.self) { philosophy in
                            VStack(alignment: .leading) {
                                Text(philosophy.displayName)
                                    .font(.headline)
                                Text(philosophy.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .tag(philosophy)
                        }
                    }
                    .pickerStyle(.inline)
                }
                
                Section(header: Text("Reminders")) {
                    Toggle("Enable Reminders", isOn: $reminderEnabled)
                    
                    if reminderEnabled {
                        Picker("Remind me before end", selection: $reminderMinutes) {
                            ForEach(reminderOptions, id: \.self) { minutes in
                                Text("\(minutes) minutes").tag(minutes)
                            }
                        }
                    }
                }
                
                if !selectedDays.isEmpty {
                    Section {
                        Button(action: createPlan) {
                            HStack {
                                Spacer()
                                Text(isEditing ? "Update Plan" : "Create Plan")
                                    .fontWeight(.semibold)
                                Spacer()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Fasting Plan" : "Create Fasting Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadExistingPlan()
            }
        }
    }

    private func loadExistingPlan() {
        guard !hasLoadedExistingPlan, let plan = viewModel.activePlan else { return }
        hasLoadedExistingPlan = true

        // Load existing plan settings
        selectedDays = Set(plan.daysOfWeek)
        preferredStartTime = plan.preferredStartTime
        selectedDrinksPhilosophy = plan.allowedDrinks
        reminderEnabled = plan.reminderEnabled
        reminderMinutes = plan.reminderMinutesBeforeEnd

        // Map hours to duration enum
        switch plan.durationHours {
        case 12:
            selectedDuration = .twelveHours
        case 16:
            selectedDuration = .sixteenHours
        case 18:
            selectedDuration = .eighteenHours
        case 20:
            selectedDuration = .twentyHours
        case 24:
            selectedDuration = .twentyFourHours
        default:
            selectedDuration = .custom
            customDurationHours = plan.durationHours
        }

    }
    
    private func createPlan() {
        let durationHours = selectedDuration == .custom ? customDurationHours : selectedDuration.hours
        let sortedDays = allDays.filter { selectedDays.contains($0) }

        // Auto-generate name based on duration
        let finalName: String
        if durationHours == 16 {
            finalName = "16:8 Fasting Plan"
        } else if durationHours == 12 {
            finalName = "12:12 Fasting Plan"
        } else if durationHours == 18 {
            finalName = "18:6 Fasting Plan"
        } else if durationHours == 20 {
            finalName = "20:4 Fasting Plan"
        } else if durationHours == 24 {
            finalName = "OMAD Plan"
        } else {
            finalName = "\(durationHours)-Hour Fast"
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
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
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
            .fullScreenCover(isPresented: $showingCreatePlan) {
                FastingPlanCreationView(viewModel: viewModel)
            }
            .alert("Delete Plan", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    if let plan = planToDelete {
                        Task {
                            await viewModel.deletePlan(plan)
                        }
                    }
                }
            } message: {
                Text("Are you sure you want to delete this fasting plan? This action cannot be undone.")
            }
        }
    }
}

struct ActivePlanCard: View {
    let plan: FastingPlan
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(plan.displayName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(plan.durationDisplay)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title2)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.secondary)
                    Text("Days: \(plan.daysOfWeek.joined(separator: ", "))")
                        .font(.subheadline)
                }
                
                HStack {
                    Image(systemName: "drop.fill")
                        .foregroundColor(.secondary)
                    Text(plan.allowedDrinks.displayName)
                        .font(.subheadline)
                }
                
                if plan.reminderEnabled {
                    HStack {
                        Image(systemName: "bell.fill")
                            .foregroundColor(.secondary)
                        Text("Reminds \(plan.reminderMinutesBeforeEnd) min before end")
                            .font(.subheadline)
                    }
                }
            }
            
            if let nextDate = plan.nextScheduledDate {
                HStack {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundColor(.blue)
                    Text("Next scheduled: \(nextDate.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .cardBackground(cornerRadius: 12)
    }
}

struct PlanRow: View {
    let plan: FastingPlan
    let isActive: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(plan.displayName)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                HStack {
                    Text(plan.durationDisplay)
                        .font(.subheadline)
                    
                    if !plan.daysOfWeek.isEmpty {
                        Text("•")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("\(plan.daysOfWeek.count) days")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Text(plan.allowedDrinks.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isActive {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    NavigationStack {
        FastingPlanCreationView(viewModel: FastingViewModel.preview)
    }
}

#Preview {
    NavigationStack {
        FastingPlanManagementView(viewModel: FastingViewModel.preview)
    }
}