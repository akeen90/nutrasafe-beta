//
//  DietManagementRedesign.swift
//  NutraSafe Beta
//
//  Redesigned Diet Management and BMR Calculator with calm, supportive UX
//  Matches app philosophy: neutral, educational, user-led, non-judgemental
//

import SwiftUI

// MARK: - Redesigned Diet Management View

struct DietManagementRedesigned: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject var firebaseManager: FirebaseManager

    @Binding var macroGoals: [MacroGoal]
    @Binding var dietType: DietType?
    @Binding var customCarbLimit: Int
    let onSave: (DietType?) -> Void

    // Selected diet type
    @State private var selectedDiet: DietType?
    @State private var isCustomMode: Bool = false

    // Core macro percentages
    @State private var proteinPercent: Int
    @State private var carbsPercent: Int
    @State private var fatPercent: Int

    // Extra macro selection
    @State private var selectedExtraMacro: MacroType
    @State private var extraMacroTarget: String

    // Calorie goal settings
    @AppStorage("cachedCaloricGoal") private var cachedCaloricGoal: Int = 2000
    @AppStorage("cachedDietType") private var cachedDietType: String = "flexible"
    @State private var calorieGoal: Int = 2000
    @State private var showingBMRCalculator: Bool = false

    // BMR Calculator inputs
    @AppStorage("userSex") private var userSex: String = "female"
    @AppStorage("userAge") private var userAge: Int = 30
    @AppStorage("userHeightCm") private var userHeightCm: Double = 165
    @AppStorage("userWeightKg") private var userWeightKg: Double = 65
    @AppStorage("userActivityLevel") private var userActivityLevel: String = "moderate"

    // Info sections
    @State private var showingHowItWorks: Bool = false
    @State private var showingMacroInfo: Bool = false
    @State private var showingDietCustomization: Bool = false

    // Calorie editing
    @State private var isEditingCalories: Bool = false
    @State private var calorieText: String = ""
    @FocusState private var calorieFieldFocused: Bool

    private var palette: AppPalette {
        AppPalette.forCurrentUser(colorScheme: colorScheme)
    }

    init(macroGoals: Binding<[MacroGoal]>, dietType: Binding<DietType?>, customCarbLimit: Binding<Int>, onSave: @escaping (DietType?) -> Void) {
        self._macroGoals = macroGoals
        self._dietType = dietType
        self._customCarbLimit = customCarbLimit
        self.onSave = onSave

        let goals = macroGoals.wrappedValue
        let proteinGoal = goals.first(where: { $0.macroType == .protein })
        let carbsGoal = goals.first(where: { $0.macroType == .carbs })
        let fatGoal = goals.first(where: { $0.macroType == .fat })

        self._proteinPercent = State(initialValue: proteinGoal?.percentage ?? 30)
        self._carbsPercent = State(initialValue: carbsGoal?.percentage ?? 40)
        self._fatPercent = State(initialValue: fatGoal?.percentage ?? 30)

        let extraGoal = goals.first(where: { !$0.macroType.isCoreMacro })
        self._selectedExtraMacro = State(initialValue: extraGoal?.macroType ?? .fiber)
        self._extraMacroTarget = State(initialValue: String(Int(extraGoal?.directTarget ?? 30)))

        if let existingDiet = dietType.wrappedValue {
            self._selectedDiet = State(initialValue: existingDiet)
            self._isCustomMode = State(initialValue: false)
        } else {
            let p = proteinGoal?.percentage ?? 30
            let c = carbsGoal?.percentage ?? 40
            let f = fatGoal?.percentage ?? 30

            var matchedDiet: DietType?
            for diet in DietType.allCases {
                let ratios = diet.macroRatios
                if ratios.protein == p && ratios.carbs == c && ratios.fat == f {
                    matchedDiet = diet
                    break
                }
            }
            self._selectedDiet = State(initialValue: matchedDiet)
            self._isCustomMode = State(initialValue: matchedDiet == nil)
        }
    }

    private var totalPercent: Int {
        proteinPercent + carbsPercent + fatPercent
    }

    private var isValid: Bool {
        guard totalPercent == 100 else { return false }
        guard let target = Int(extraMacroTarget), target > 0 else { return false }
        return true
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: DesignTokens.Spacing.lg) {
                    // Welcome message
                    welcomeSection

                    // Calorie goal
                    calorieSection

                    // How it works (expandable)
                    howItWorksSection

                    // Diet style selection
                    dietStyleSection

                    // Selected diet info
                    if let diet = selectedDiet, !isCustomMode {
                        selectedDietCard(diet: diet)
                    }

                    // Macro breakdown
                    macroBreakdownSection

                    // Custom adjustments
                    if isCustomMode {
                        customMacroSection
                    }

                    // Extra macro tracking
                    extraMacroSection

                    // Macro info section
                    macroInfoSection

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, DesignTokens.Spacing.screenEdge)
                .padding(.top, DesignTokens.Spacing.md)
            }
            .scrollDismissesKeyboard(.interactively)
            .keyboardDismissButton()
            .scrollContentBackground(.hidden)
            .background(AppAnimatedBackground().ignoresSafeArea())
            .navigationTitle("Your Nutrition")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(palette.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(isValid ? palette.accent : palette.textTertiary)
                    .disabled(!isValid)
                }
            }
            .onAppear {
                calorieGoal = cachedCaloricGoal
            }
            .sheet(isPresented: $showingBMRCalculator) {
                BMRCalculatorRedesigned(
                    userSex: $userSex,
                    userAge: $userAge,
                    userHeightCm: $userHeightCm,
                    userWeightKg: $userWeightKg,
                    userActivityLevel: $userActivityLevel,
                    onCalculate: { calculatedGoal in
                        calorieGoal = calculatedGoal
                    }
                )
                .environmentObject(firebaseManager)
            }
        }
        .navigationViewStyle(.stack)
    }

    // MARK: - Welcome Section

    private var welcomeSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("Nourish your way")
                .font(DesignTokens.Typography.sectionTitle(20))
                .foregroundColor(palette.textPrimary)

            Text("These settings help you understand your food. They're starting points, not rules. Adjust based on how you feel.")
                .font(DesignTokens.Typography.body)
                .foregroundColor(palette.textSecondary)
                .lineSpacing(DesignTokens.Spacing.lineSpacing)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DesignTokens.Spacing.cardInternal)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.xl)
                .fill(palette.accent.opacity(0.08))
        )
    }

    // MARK: - Calorie Section

    private var calorieSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            HStack {
                Image(systemName: "flame")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(palette.accent)
                Text("Daily Energy")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(palette.textPrimary)
            }

            // Calorie display with tap-to-edit
            HStack(spacing: 12) {
                // Calorie value and unit
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    if isEditingCalories {
                        TextField("", text: $calorieText)
                            .keyboardType(.numberPad)
                            .font(.system(size: 38, weight: .bold, design: .rounded))
                            .foregroundColor(palette.accent)
                            .multilineTextAlignment(.leading)
                            .frame(width: 100)
                            .focused($calorieFieldFocused)
                            .onSubmit {
                                commitCalorieEdit()
                            }
                            .onChange(of: calorieFieldFocused) { _, focused in
                                if !focused {
                                    commitCalorieEdit()
                                }
                            }
                    } else {
                        Text("\(calorieGoal)")
                            .font(.system(size: 38, weight: .bold, design: .rounded))
                            .foregroundColor(palette.accent)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .onTapGesture {
                                calorieText = "\(calorieGoal)"
                                isEditingCalories = true
                                calorieFieldFocused = true
                            }
                    }

                    Text("kcal")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(palette.textSecondary)
                }

                Spacer()

                // Adjustment buttons - fixed width for alignment
                HStack(spacing: 8) {
                    Button {
                        if calorieGoal > 1000 {
                            calorieGoal -= 50
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(calorieGoal > 1000 ? palette.secondary : palette.textTertiary.opacity(0.5))
                    }
                    .disabled(calorieGoal <= 1000)
                    .frame(width: 32, height: 32)

                    Button {
                        if calorieGoal < 5000 {
                            calorieGoal += 50
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(calorieGoal < 5000 ? palette.accent : palette.textTertiary.opacity(0.5))
                    }
                    .disabled(calorieGoal >= 5000)
                    .frame(width: 32, height: 32)
                }
            }

            // Tap to edit hint
            if !isEditingCalories {
                Text("Tap the number to type directly")
                    .font(.system(size: 11))
                    .foregroundColor(palette.textTertiary)
            }

            Divider()
                .background(palette.textTertiary.opacity(0.2))

            // BMR Calculator button
            Button {
                showingBMRCalculator = true
            } label: {
                HStack {
                    Image(systemName: "function")
                        .font(.system(size: 16))
                    Text("Calculate based on my body")
                        .font(.system(size: 15, weight: .medium))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(palette.textTertiary)
                }
                .foregroundColor(palette.accent)
            }

            // Context note
            Text("This is a guide, not a limit. Listen to your hunger.")
                .font(DesignTokens.Typography.caption)
                .foregroundColor(palette.textTertiary)
                .italic()
        }
        .padding(DesignTokens.Spacing.cardInternal)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.xl)
                .fill(Color.nutraSafeCard)
        )
        .shadow(color: DesignTokens.Shadow.subtle.color, radius: DesignTokens.Shadow.subtle.radius, y: DesignTokens.Shadow.subtle.y)
    }

    private func commitCalorieEdit() {
        if let newValue = Int(calorieText), newValue >= 1000, newValue <= 5000 {
            calorieGoal = newValue
        }
        isEditingCalories = false
        calorieFieldFocused = false
    }

    /// Returns short names for extra macros to prevent truncation in segmented picker
    private func shortExtraMacroName(_ macro: MacroType) -> String {
        switch macro {
        case .fiber: return "Fiber"
        case .sugar: return "Sugar"
        case .saturatedFat: return "Sat Fat"
        case .salt: return "Salt"
        default: return macro.displayName
        }
    }

    // MARK: - How It Works Section

    private var howItWorksSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    showingHowItWorks.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: "questionmark.circle")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(palette.accent)

                    Text("How does this work?")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(palette.textPrimary)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(palette.textTertiary)
                        .rotationEffect(.degrees(showingHowItWorks ? 90 : 0))
                }
            }
            .buttonStyle(.plain)

            if showingHowItWorks {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                    Divider()
                        .background(palette.textTertiary.opacity(0.2))
                        .padding(.vertical, DesignTokens.Spacing.sm)

                    howItWorksItem(
                        icon: "flame",
                        title: "Daily calories",
                        description: "Your body needs energy. This number helps you see if you're in the ballpark."
                    )

                    howItWorksItem(
                        icon: "chart.pie",
                        title: "Macronutrients",
                        description: "Protein, carbs, and fat make up your calories. Different balances work for different people."
                    )

                    howItWorksItem(
                        icon: "leaf",
                        title: "Diet styles",
                        description: "Optional presets that adjust your macro balance. Choose one or create your own."
                    )

                    Text("None of this is strict. Your body knows what it needs. These are just tools for awareness.")
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(palette.textTertiary)
                        .italic()
                        .padding(.top, DesignTokens.Spacing.xs)
                }
            }
        }
        .padding(DesignTokens.Spacing.cardInternal)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.xl)
                .fill(Color.nutraSafeCard)
        )
        .clipped()
    }

    private func howItWorksItem(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: DesignTokens.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(palette.accent)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(palette.textPrimary)

                Text(description)
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(palette.textSecondary)
                    .lineSpacing(2)
            }
        }
    }

    // MARK: - Diet Style Section

    private var dietStyleSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            HStack {
                Image(systemName: "leaf.circle")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(palette.accent)
                Text("Eating Style")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(palette.textPrimary)
            }

            Text("Choose a style or create your own balance")
                .font(DesignTokens.Typography.caption)
                .foregroundColor(palette.textSecondary)

            // Diet grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(DietType.allCases, id: \.self) { diet in
                    DietStyleCard(
                        diet: diet,
                        isSelected: selectedDiet == diet && !isCustomMode,
                        palette: palette,
                        onTap: {
                            selectDiet(diet)
                        }
                    )
                }
            }

            // Custom option
            Button {
                withAnimation(.spring(response: 0.3)) {
                    isCustomMode = true
                    selectedDiet = nil
                }
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            } label: {
                HStack {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 16, weight: .medium))
                    Text("My Own Balance")
                        .font(.system(size: 15, weight: .medium))
                    Spacer()
                    if isCustomMode {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(palette.accent)
                    }
                }
                .foregroundColor(isCustomMode ? palette.accent : palette.textPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                        .fill(isCustomMode ? palette.accent.opacity(0.12) : Color.nutraSafeCard)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                        .stroke(isCustomMode ? palette.accent : Color.clear, lineWidth: 2)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(DesignTokens.Spacing.cardInternal)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.xl)
                .fill(Color.nutraSafeCard)
        )
        .shadow(color: DesignTokens.Shadow.subtle.color, radius: DesignTokens.Shadow.subtle.radius, y: DesignTokens.Shadow.subtle.y)
    }

    // MARK: - Selected Diet Card

    private func selectedDietCard(diet: DietType) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            HStack(spacing: 10) {
                Image(systemName: diet.icon)
                    .font(.system(size: 20))
                    .foregroundColor(diet.accentColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text(diet.displayName)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(palette.textPrimary)
                    Text(diet.shortDescription)
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(palette.textSecondary)
                }

                Spacer()
            }

            Text(diet.detailedDescription)
                .font(DesignTokens.Typography.caption)
                .foregroundColor(palette.textSecondary)
                .lineSpacing(2)

            if let sourceURL = diet.sourceURL {
                Link(destination: sourceURL) {
                    HStack(spacing: 4) {
                        Image(systemName: "link")
                            .font(.system(size: 11))
                        Text("Learn more")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(palette.accent.opacity(0.8))
                }
                .padding(.top, 4)
            }

            // Customization section
            Divider()
                .background(diet.accentColor.opacity(0.3))
                .padding(.vertical, 8)

            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    showingDietCustomization.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 14))
                        .foregroundColor(diet.accentColor)

                    Text("Adjust for your needs")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(palette.textPrimary)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(palette.textTertiary)
                        .rotationEffect(.degrees(showingDietCustomization ? 90 : 0))
                }
            }
            .buttonStyle(.plain)

            if showingDietCustomization {
                dietCustomizationControls(diet: diet)
            }
        }
        .padding(DesignTokens.Spacing.cardInternal)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.xl)
                .fill(diet.accentColor.opacity(0.08))
        )
        .clipped()
    }

    // MARK: - Diet Customization Controls

    private func dietCustomizationControls(diet: DietType) -> some View {
        let adjustments = dietAdjustmentOptions(for: diet)

        return VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text("Fine-tune your \(diet.displayName) approach")
                .font(.system(size: 13))
                .foregroundColor(palette.textSecondary)
                .padding(.top, 4)

            // Show adjustable macros based on diet type
            ForEach(adjustments, id: \.macro) { adjustment in
                dietMacroAdjuster(
                    macro: adjustment.macro,
                    label: adjustment.label,
                    minValue: adjustment.min,
                    maxValue: adjustment.max,
                    currentValue: currentValueFor(adjustment.macro),
                    accentColor: diet.accentColor,
                    onChange: { newValue in
                        adjustMacro(adjustment.macro, to: newValue, for: diet)
                    }
                )
            }

            // Reset to default button
            Button {
                withAnimation(.spring(response: 0.3)) {
                    let ratios = diet.macroRatios
                    proteinPercent = ratios.protein
                    carbsPercent = ratios.carbs
                    fatPercent = ratios.fat
                }
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            } label: {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 12))
                    Text("Reset to default")
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundColor(palette.textTertiary)
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
        .padding(.top, 8)
    }

    private func dietMacroAdjuster(
        macro: MacroType,
        label: String,
        minValue: Int,
        maxValue: Int,
        currentValue: Int,
        accentColor: Color,
        onChange: @escaping (Int) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Circle()
                    .fill(macro.color)
                    .frame(width: 10, height: 10)

                Text(label)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(palette.textPrimary)

                Spacer()

                Text("\(currentValue)%")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(accentColor)
            }

            HStack(spacing: 12) {
                Button {
                    if currentValue > minValue {
                        onChange(currentValue - 5)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(currentValue > minValue ? accentColor : palette.textTertiary.opacity(0.4))
                }
                .disabled(currentValue <= minValue)
                .buttonStyle(.plain)

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(palette.textTertiary.opacity(0.15))

                        RoundedRectangle(cornerRadius: 4)
                            .fill(accentColor)
                            .frame(width: geo.size.width * CGFloat(currentValue - minValue) / CGFloat(maxValue - minValue))
                    }
                }
                .frame(height: 8)

                Button {
                    if currentValue < maxValue {
                        onChange(currentValue + 5)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(currentValue < maxValue ? accentColor : palette.textTertiary.opacity(0.4))
                }
                .disabled(currentValue >= maxValue)
                .buttonStyle(.plain)
            }

            HStack {
                Text("\(minValue)%")
                    .font(.system(size: 10))
                    .foregroundColor(palette.textTertiary)
                Spacer()
                Text("\(maxValue)%")
                    .font(.system(size: 10))
                    .foregroundColor(palette.textTertiary)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                .fill(colorScheme == .dark ? Color.midnightCard : Color.white.opacity(0.6))
        )
    }

    // MARK: - Diet Adjustment Options

    private struct MacroAdjustment {
        let macro: MacroType
        let label: String
        let min: Int
        let max: Int
    }

    private func dietAdjustmentOptions(for diet: DietType) -> [MacroAdjustment] {
        switch diet {
        case .keto:
            // Keto: Can adjust carbs (very low), protein, and fat
            return [
                MacroAdjustment(macro: .carbs, label: "Carbs (keep very low)", min: 5, max: 10),
                MacroAdjustment(macro: .protein, label: "Protein", min: 15, max: 30),
                MacroAdjustment(macro: .fat, label: "Fat", min: 60, max: 80)
            ]
        case .lowCarb:
            // Low carb: Primary adjustment is carbs
            return [
                MacroAdjustment(macro: .carbs, label: "Carbs", min: 15, max: 35),
                MacroAdjustment(macro: .protein, label: "Protein", min: 25, max: 40),
                MacroAdjustment(macro: .fat, label: "Fat", min: 35, max: 55)
            ]
        case .highProtein:
            // High protein: Primary adjustment is protein level
            return [
                MacroAdjustment(macro: .protein, label: "Protein", min: 35, max: 50),
                MacroAdjustment(macro: .carbs, label: "Carbs", min: 25, max: 45),
                MacroAdjustment(macro: .fat, label: "Fat", min: 15, max: 35)
            ]
        case .highProteinMax:
            // Very high protein
            return [
                MacroAdjustment(macro: .protein, label: "Protein (very high)", min: 45, max: 55),
                MacroAdjustment(macro: .carbs, label: "Carbs", min: 20, max: 30),
                MacroAdjustment(macro: .fat, label: "Fat", min: 20, max: 30)
            ]
        case .flexible:
            // Flexible: All macros adjustable within balanced range
            return [
                MacroAdjustment(macro: .protein, label: "Protein", min: 20, max: 40),
                MacroAdjustment(macro: .carbs, label: "Carbs", min: 30, max: 50),
                MacroAdjustment(macro: .fat, label: "Fat", min: 20, max: 40)
            ]
        case .mediterranean:
            // Mediterranean: Higher carbs, moderate fat
            return [
                MacroAdjustment(macro: .carbs, label: "Carbs", min: 40, max: 55),
                MacroAdjustment(macro: .fat, label: "Fat (healthy fats)", min: 30, max: 40),
                MacroAdjustment(macro: .protein, label: "Protein", min: 15, max: 25)
            ]
        case .paleo:
            // Paleo: Moderate carbs, higher fat
            return [
                MacroAdjustment(macro: .carbs, label: "Carbs", min: 15, max: 30),
                MacroAdjustment(macro: .protein, label: "Protein", min: 25, max: 40),
                MacroAdjustment(macro: .fat, label: "Fat", min: 40, max: 60)
            ]
        }
    }

    private func currentValueFor(_ macro: MacroType) -> Int {
        switch macro {
        case .protein: return proteinPercent
        case .carbs: return carbsPercent
        case .fat: return fatPercent
        default: return 0
        }
    }

    private func adjustMacro(_ macro: MacroType, to newValue: Int, for diet: DietType) {
        // Calculate the difference
        let currentValue = currentValueFor(macro)
        let difference = newValue - currentValue

        // We need to adjust other macros to keep total at 100%
        // Strategy: Distribute the difference to other macros proportionally

        switch macro {
        case .protein:
            proteinPercent = newValue
            // Split the difference between carbs and fat
            let carbsShare = difference / 2
            let fatShare = difference - carbsShare
            carbsPercent = max(5, carbsPercent - carbsShare)
            fatPercent = max(5, fatPercent - fatShare)
        case .carbs:
            carbsPercent = newValue
            // Split the difference between protein and fat
            let proteinShare = difference / 2
            let fatShare = difference - proteinShare
            proteinPercent = max(5, proteinPercent - proteinShare)
            fatPercent = max(5, fatPercent - fatShare)
        case .fat:
            fatPercent = newValue
            // Split the difference between protein and carbs
            let proteinShare = difference / 2
            let carbsShare = difference - proteinShare
            proteinPercent = max(5, proteinPercent - proteinShare)
            carbsPercent = max(5, carbsPercent - carbsShare)
        default:
            break
        }

        // Ensure total is 100
        let total = proteinPercent + carbsPercent + fatPercent
        if total != 100 {
            // Adjust fat to balance
            fatPercent += (100 - total)
        }
    }

    // MARK: - Macro Breakdown Section

    private var macroBreakdownSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            HStack {
                Image(systemName: "chart.pie")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(palette.accent)
                Text("Your Macro Balance")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(palette.textPrimary)
            }

            // Visual breakdown bar
            GeometryReader { geo in
                HStack(spacing: 2) {
                    // Protein
                    Rectangle()
                        .fill(MacroType.protein.color)
                        .frame(width: geo.size.width * CGFloat(proteinPercent) / 100)
                        .cornerRadius(4, corners: [.topLeft, .bottomLeft])

                    // Carbs
                    Rectangle()
                        .fill(MacroType.carbs.color)
                        .frame(width: geo.size.width * CGFloat(carbsPercent) / 100)

                    // Fat
                    Rectangle()
                        .fill(MacroType.fat.color)
                        .frame(width: geo.size.width * CGFloat(fatPercent) / 100)
                        .cornerRadius(4, corners: [.topRight, .bottomRight])
                }
            }
            .frame(height: 12)
            .background(palette.textTertiary.opacity(0.1))
            .cornerRadius(6)

            // Legend with gram values
            HStack(spacing: DesignTokens.Spacing.md) {
                macroLegendItem(
                    macro: .protein,
                    percent: proteinPercent,
                    grams: Int(Double(calorieGoal) * Double(proteinPercent) / 100 / 4)
                )

                Spacer()

                macroLegendItem(
                    macro: .carbs,
                    percent: carbsPercent,
                    grams: Int(Double(calorieGoal) * Double(carbsPercent) / 100 / 4)
                )

                Spacer()

                macroLegendItem(
                    macro: .fat,
                    percent: fatPercent,
                    grams: Int(Double(calorieGoal) * Double(fatPercent) / 100 / 9)
                )
            }

            // Total validation
            if totalPercent != 100 {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 12))
                    Text("Total should be 100% (currently \(totalPercent)%)")
                        .font(DesignTokens.Typography.caption)
                }
                .foregroundColor(.orange)
                .padding(.top, 4)
            }
        }
        .padding(DesignTokens.Spacing.cardInternal)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.xl)
                .fill(Color.nutraSafeCard)
        )
        .shadow(color: DesignTokens.Shadow.subtle.color, radius: DesignTokens.Shadow.subtle.radius, y: DesignTokens.Shadow.subtle.y)
    }

    private func macroLegendItem(macro: MacroType, percent: Int, grams: Int) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Circle()
                    .fill(macro.color)
                    .frame(width: 8, height: 8)
                Text(macro.displayName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(palette.textSecondary)
            }

            Text("\(percent)%")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(palette.textPrimary)

            Text("\(grams)g")
                .font(.system(size: 11))
                .foregroundColor(palette.textTertiary)
        }
    }

    // MARK: - Custom Macro Section

    private var customMacroSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            HStack {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(palette.accent)
                Text("Adjust Your Balance")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(palette.textPrimary)
            }

            customMacroSlider(
                macro: .protein,
                value: $proteinPercent
            )

            Divider()
                .background(palette.textTertiary.opacity(0.2))

            customMacroSlider(
                macro: .carbs,
                value: $carbsPercent
            )

            Divider()
                .background(palette.textTertiary.opacity(0.2))

            customMacroSlider(
                macro: .fat,
                value: $fatPercent
            )
        }
        .padding(DesignTokens.Spacing.cardInternal)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.xl)
                .fill(Color.nutraSafeCard)
        )
        .shadow(color: DesignTokens.Shadow.subtle.color, radius: DesignTokens.Shadow.subtle.radius, y: DesignTokens.Shadow.subtle.y)
    }

    private func customMacroSlider(macro: MacroType, value: Binding<Int>) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            HStack {
                Circle()
                    .fill(macro.color)
                    .frame(width: 10, height: 10)

                Text(macro.displayName)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(palette.textPrimary)

                Spacer()

                Text("\(value.wrappedValue)%")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(macro.color)
            }

            Slider(value: Binding(
                get: { Double(value.wrappedValue) },
                set: { value.wrappedValue = Int($0) }
            ), in: 5...70, step: 5)
            .tint(macro.color)
        }
    }

    // MARK: - Extra Macro Section

    private var extraMacroSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            HStack {
                Image(systemName: "plus.circle")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(palette.accent)
                Text("Track Something Extra")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(palette.textPrimary)
            }

            Text("Optionally track an additional nutrient")
                .font(DesignTokens.Typography.caption)
                .foregroundColor(palette.textSecondary)

            // Picker with short names to prevent truncation
            Picker("Extra Macro", selection: $selectedExtraMacro) {
                ForEach(MacroType.extraMacros, id: \.self) { macro in
                    Text(shortExtraMacroName(macro)).tag(macro)
                }
            }
            .pickerStyle(.segmented)

            // Target input
            HStack {
                Text("Daily target:")
                    .font(.system(size: 15))
                    .foregroundColor(palette.textSecondary)

                TextField("30", text: $extraMacroTarget)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .frame(width: 60)
                    .padding(.vertical, 8)
                    .background(palette.textTertiary.opacity(0.1))
                    .cornerRadius(8)

                Text("g")
                    .font(.system(size: 15))
                    .foregroundColor(palette.textSecondary)
            }
        }
        .padding(DesignTokens.Spacing.cardInternal)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.xl)
                .fill(Color.nutraSafeCard)
        )
        .shadow(color: DesignTokens.Shadow.subtle.color, radius: DesignTokens.Shadow.subtle.radius, y: DesignTokens.Shadow.subtle.y)
    }

    // MARK: - Macro Info Section

    private var macroInfoSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    showingMacroInfo.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: "info.circle")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(palette.accent)

                    Text("What are macros anyway?")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(palette.textPrimary)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(palette.textTertiary)
                        .rotationEffect(.degrees(showingMacroInfo ? 90 : 0))
                }
            }
            .buttonStyle(.plain)

            if showingMacroInfo {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                    Divider()
                        .background(palette.textTertiary.opacity(0.2))
                        .padding(.vertical, DesignTokens.Spacing.sm)

                    macroInfoItem(
                        color: MacroType.protein.color,
                        name: "Protein",
                        calories: "4 kcal/g",
                        description: "Builds and repairs tissues. Found in meat, fish, eggs, beans, tofu."
                    )

                    macroInfoItem(
                        color: MacroType.carbs.color,
                        name: "Carbohydrates",
                        calories: "4 kcal/g",
                        description: "Your body's preferred energy source. Found in grains, fruits, vegetables."
                    )

                    macroInfoItem(
                        color: MacroType.fat.color,
                        name: "Fat",
                        calories: "9 kcal/g",
                        description: "Essential for hormones and nutrient absorption. Found in oils, nuts, avocados."
                    )

                    Text("All three are important. There's no universally \"best\" ratio - it depends on you.")
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(palette.textTertiary)
                        .italic()
                        .padding(.top, DesignTokens.Spacing.xs)
                }
            }
        }
        .padding(DesignTokens.Spacing.cardInternal)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.xl)
                .fill(Color.nutraSafeCard)
        )
        .clipped()
    }

    private func macroInfoItem(color: Color, name: String, calories: String, description: String) -> some View {
        HStack(alignment: .top, spacing: DesignTokens.Spacing.sm) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
                .padding(.top, 4)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(palette.textPrimary)

                    Text("(\(calories))")
                        .font(.system(size: 12))
                        .foregroundColor(palette.textTertiary)
                }

                Text(description)
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(palette.textSecondary)
                    .lineSpacing(2)
            }
        }
    }

    // MARK: - Actions

    private func selectDiet(_ diet: DietType) {
        withAnimation(.spring(response: 0.3)) {
            selectedDiet = diet
            isCustomMode = false

            let ratios = diet.macroRatios
            proteinPercent = ratios.protein
            carbsPercent = ratios.carbs
            fatPercent = ratios.fat
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func saveChanges() {
        let extraTarget = Int(extraMacroTarget) ?? 30
        let newMacroGoals = [
            MacroGoal(macroType: .protein, percentage: proteinPercent),
            MacroGoal(macroType: .carbs, percentage: carbsPercent),
            MacroGoal(macroType: .fat, percentage: fatPercent),
            MacroGoal(macroType: selectedExtraMacro, directTarget: Double(extraTarget))
        ]

        macroGoals = newMacroGoals
        dietType = selectedDiet
        cachedCaloricGoal = calorieGoal

        // Save diet type to UserDefaults cache
        if let diet = selectedDiet {
            cachedDietType = diet.rawValue
        }

        onSave(selectedDiet)
        dismiss()
    }
}

// MARK: - Diet Style Card

struct DietStyleCard: View {
    let diet: DietType
    let isSelected: Bool
    let palette: AppPalette
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: diet.icon)
                        .font(.system(size: 18))
                        .foregroundColor(isSelected ? diet.accentColor : palette.textSecondary)

                    Spacer()

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(diet.accentColor)
                    }
                }

                Text(diet.displayName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(isSelected ? diet.accentColor : palette.textPrimary)

                Text("P\(diet.macroRatios.protein) C\(diet.macroRatios.carbs) F\(diet.macroRatios.fat)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(palette.textTertiary)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                    .fill(isSelected ? diet.accentColor.opacity(0.12) : Color.nutraSafeCard)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                    .stroke(isSelected ? diet.accentColor : palette.textTertiary.opacity(0.1), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Redesigned BMR Calculator

struct BMRCalculatorRedesigned: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject var firebaseManager: FirebaseManager

    @Binding var userSex: String
    @Binding var userAge: Int
    @Binding var userHeightCm: Double
    @Binding var userWeightKg: Double
    @Binding var userActivityLevel: String

    let onCalculate: (Int) -> Void

    // Text input states
    @State private var ageText: String = ""
    @State private var heightText: String = ""
    @State private var weightText: String = ""
    @FocusState private var focusedField: BMRFieldType?

    enum BMRFieldType {
        case age, height, weight
    }

    // Activity level data
    private let activityLevels: [(id: String, label: String, description: String, multiplier: Double)] = [
        ("sedentary", "Mostly sitting", "Office work, little exercise", 1.2),
        ("light", "Lightly active", "Light exercise 1-3 days/week", 1.375),
        ("moderate", "Moderately active", "Moderate exercise 3-5 days/week", 1.55),
        ("active", "Very active", "Hard exercise 6-7 days/week", 1.725),
        ("extreme", "Athlete-level", "Physical job + daily training", 1.9)
    ]

    private var palette: AppPalette {
        AppPalette.forCurrentUser(colorScheme: colorScheme)
    }

    // Calculations
    private var calculatedBMR: Double {
        if userSex == "male" {
            return (10 * userWeightKg) + (6.25 * userHeightCm) - (5 * Double(userAge)) + 5
        } else {
            return (10 * userWeightKg) + (6.25 * userHeightCm) - (5 * Double(userAge)) - 161
        }
    }

    private var activityMultiplier: Double {
        activityLevels.first(where: { $0.id == userActivityLevel })?.multiplier ?? 1.55
    }

    private var calculatedTDEE: Int {
        Int(calculatedBMR * activityMultiplier)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: DesignTokens.Spacing.lg) {
                    // Welcome message
                    welcomeSection

                    // Sex selection
                    sexSelectionSection

                    // Details input
                    detailsSection

                    // Activity level
                    activitySection

                    // Results
                    resultsSection

                    // Goal options
                    goalOptionsSection

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, DesignTokens.Spacing.screenEdge)
                .padding(.top, DesignTokens.Spacing.md)
            }
            .scrollDismissesKeyboard(.interactively)
            .keyboardDismissButton()
            .scrollContentBackground(.hidden)
            .background(AppAnimatedBackground().ignoresSafeArea())
            .navigationTitle("Energy Calculator")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(palette.textSecondary)
                }
                ToolbarItem(placement: .keyboard) {
                    Button("Done") { focusedField = nil }
                }
            }
            .onAppear(perform: setupInitialValues)
        }
        .navigationViewStyle(.stack)
    }

    // MARK: - Welcome Section

    private var welcomeSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("Your personal estimate")
                .font(DesignTokens.Typography.sectionTitle(20))
                .foregroundColor(palette.textPrimary)

            Text("This calculates roughly how much energy your body uses each day. It's a starting point, not a target.")
                .font(DesignTokens.Typography.body)
                .foregroundColor(palette.textSecondary)
                .lineSpacing(DesignTokens.Spacing.lineSpacing)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DesignTokens.Spacing.cardInternal)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.xl)
                .fill(palette.accent.opacity(0.08))
        )
    }

    // MARK: - Sex Display (Read-only)

    private var sexSelectionSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text("Biological sex")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(palette.textPrimary)

            Text("Used for metabolism calculation (from your profile)")
                .font(DesignTokens.Typography.caption)
                .foregroundColor(palette.textTertiary)

            // Display current sex as read-only
            HStack(spacing: 12) {
                Image(systemName: userSex == "female" ? "figure.stand.dress" : "figure.stand")
                    .font(.system(size: 28))
                    .foregroundColor(userSex == "female" ? .pink : .blue)

                VStack(alignment: .leading, spacing: 2) {
                    Text(userSex == "female" ? "Female" : "Male")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(palette.textPrimary)
                    Text("Set in your profile")
                        .font(.system(size: 12))
                        .foregroundColor(palette.textTertiary)
                }

                Spacer()

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(userSex == "female" ? .pink : .blue)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                    .fill((userSex == "female" ? Color.pink : Color.blue).opacity(0.1))
            )
        }
        .padding(DesignTokens.Spacing.cardInternal)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.xl)
                .fill(Color.nutraSafeCard)
        )
        .shadow(color: DesignTokens.Shadow.subtle.color, radius: DesignTokens.Shadow.subtle.radius, y: DesignTokens.Shadow.subtle.y)
    }

    // MARK: - Details Section

    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text("Your details")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(palette.textPrimary)

            // Age
            detailRow(
                label: "Age",
                text: $ageText,
                unit: "years",
                field: .age,
                onDecrease: { if userAge > 15 { userAge -= 1; ageText = "\(userAge)" } },
                onIncrease: { if userAge < 100 { userAge += 1; ageText = "\(userAge)" } },
                canDecrease: userAge > 15,
                canIncrease: userAge < 100
            )

            Divider().background(palette.textTertiary.opacity(0.2))

            // Height
            detailRow(
                label: "Height",
                text: $heightText,
                unit: "cm",
                field: .height,
                onDecrease: { if userHeightCm > 100 { userHeightCm -= 1; heightText = "\(Int(userHeightCm))" } },
                onIncrease: { if userHeightCm < 250 { userHeightCm += 1; heightText = "\(Int(userHeightCm))" } },
                canDecrease: userHeightCm > 100,
                canIncrease: userHeightCm < 250
            )

            Divider().background(palette.textTertiary.opacity(0.2))

            // Weight
            detailRow(
                label: "Weight",
                text: $weightText,
                unit: "kg",
                field: .weight,
                onDecrease: { if userWeightKg > 30 { userWeightKg -= 0.5; weightText = String(format: "%.1f", userWeightKg) } },
                onIncrease: { if userWeightKg < 300 { userWeightKg += 0.5; weightText = String(format: "%.1f", userWeightKg) } },
                canDecrease: userWeightKg > 30,
                canIncrease: userWeightKg < 300
            )
        }
        .padding(DesignTokens.Spacing.cardInternal)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.xl)
                .fill(Color.nutraSafeCard)
        )
        .shadow(color: DesignTokens.Shadow.subtle.color, radius: DesignTokens.Shadow.subtle.radius, y: DesignTokens.Shadow.subtle.y)
    }

    private func detailRow(
        label: String,
        text: Binding<String>,
        unit: String,
        field: BMRFieldType,
        onDecrease: @escaping () -> Void,
        onIncrease: @escaping () -> Void,
        canDecrease: Bool,
        canIncrease: Bool
    ) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 15))
                .foregroundColor(palette.textSecondary)
                .frame(width: 55, alignment: .leading)

            Spacer()

            // Controls with fixed widths for alignment
            HStack(spacing: 8) {
                Button {
                    onDecrease()
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(canDecrease ? palette.secondary : palette.textTertiary.opacity(0.3))
                }
                .disabled(!canDecrease)
                .frame(width: 28, height: 28)

                // Value + unit in fixed width container
                HStack(spacing: 4) {
                    TextField("", text: text)
                        .keyboardType(field == .weight ? .decimalPad : .numberPad)
                        .multilineTextAlignment(.center)
                        .frame(width: 55)
                        .padding(.vertical, 8)
                        .background(palette.textTertiary.opacity(0.1))
                        .cornerRadius(8)
                        .focused($focusedField, equals: field)
                        .onChange(of: text.wrappedValue) { _, newValue in
                            updateValue(field: field, value: newValue)
                        }

                    Text(unit)
                        .font(.system(size: 13))
                        .foregroundColor(palette.textTertiary)
                        .frame(width: 38, alignment: .leading)
                }

                Button {
                    onIncrease()
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(canIncrease ? palette.accent : palette.textTertiary.opacity(0.3))
                }
                .disabled(!canIncrease)
                .frame(width: 28, height: 28)
            }
        }
    }

    // MARK: - Activity Section

    private var activitySection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text("How active are you?")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(palette.textPrimary)

            Text("Be honest - most people overestimate")
                .font(DesignTokens.Typography.caption)
                .foregroundColor(palette.textTertiary)

            ForEach(activityLevels, id: \.id) { activity in
                Button {
                    userActivityLevel = activity.id
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(activity.label)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(palette.textPrimary)
                            Text(activity.description)
                                .font(.system(size: 12))
                                .foregroundColor(palette.textSecondary)
                        }

                        Spacer()

                        if userActivityLevel == activity.id {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(palette.accent)
                        }
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                            .fill(userActivityLevel == activity.id ? palette.accent.opacity(0.1) : Color.clear)
                    )
                }
                .buttonStyle(.plain)

                if activity.id != activityLevels.last?.id {
                    Divider().background(palette.textTertiary.opacity(0.2))
                }
            }
        }
        .padding(DesignTokens.Spacing.cardInternal)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.xl)
                .fill(Color.nutraSafeCard)
        )
        .shadow(color: DesignTokens.Shadow.subtle.color, radius: DesignTokens.Shadow.subtle.radius, y: DesignTokens.Shadow.subtle.y)
    }

    // MARK: - Results Section

    private var resultsSection: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your BMR")
                        .font(.system(size: 13))
                        .foregroundColor(palette.textSecondary)
                    Text("\(Int(calculatedBMR)) kcal")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(palette.textPrimary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Daily energy")
                        .font(.system(size: 13))
                        .foregroundColor(palette.textSecondary)
                    Text("\(calculatedTDEE) kcal")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(palette.accent)
                }
            }

            Text("BMR is what you'd burn doing nothing all day. Your daily energy includes your activity level.")
                .font(DesignTokens.Typography.caption)
                .foregroundColor(palette.textTertiary)
                .multilineTextAlignment(.center)
        }
        .padding(DesignTokens.Spacing.cardInternal)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.xl)
                .fill(palette.accent.opacity(0.1))
        )
    }

    // MARK: - Goal Options Section

    private var goalOptionsSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text("Choose your approach")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(palette.textPrimary)

            Text("These are guidelines. Your body may need more or less.")
                .font(DesignTokens.Typography.caption)
                .foregroundColor(palette.textTertiary)

            // Maintenance
            goalOptionButton(
                title: "Maintain weight",
                subtitle: "Eat around your daily energy",
                calories: calculatedTDEE,
                color: palette.accent,
                isPrimary: true
            ) {
                onCalculate(calculatedTDEE)
                dismiss()
            }

            // Gentle deficit
            goalOptionButton(
                title: "Gentle deficit",
                subtitle: "Small reduction, sustainable pace",
                calories: calculatedTDEE - 250,
                color: SemanticColors.positive,
                isPrimary: false
            ) {
                onCalculate(calculatedTDEE - 250)
                dismiss()
            }

            // Moderate deficit
            goalOptionButton(
                title: "Moderate deficit",
                subtitle: "Common approach for gradual change",
                calories: calculatedTDEE - 500,
                color: SemanticColors.neutral,
                isPrimary: false
            ) {
                onCalculate(calculatedTDEE - 500)
                dismiss()
            }

            // NHS guidance note
            Text("NHS recommends gradual changes for sustainable results.")
                .font(.system(size: 11))
                .foregroundColor(palette.textTertiary)
                .italic()
                .padding(.top, 4)
        }
        .padding(DesignTokens.Spacing.cardInternal)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.xl)
                .fill(Color.nutraSafeCard)
        )
        .shadow(color: DesignTokens.Shadow.subtle.color, radius: DesignTokens.Shadow.subtle.radius, y: DesignTokens.Shadow.subtle.y)
    }

    private func goalOptionButton(
        title: String,
        subtitle: String,
        calories: Int,
        color: Color,
        isPrimary: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: {
            action()
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: isPrimary ? .semibold : .medium))
                        .foregroundColor(isPrimary ? .white : palette.textPrimary)
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(isPrimary ? .white.opacity(0.8) : palette.textSecondary)
                }

                Spacer()

                Text("\(calories) kcal")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isPrimary ? .white : color)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(isPrimary ? .white.opacity(0.7) : palette.textTertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                    .fill(isPrimary ? color : color.opacity(0.1))
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private func setupInitialValues() {
        // Sync gender from OnboardingManager
        let profileGender = OnboardingManager.shared.userGender
        if profileGender == .male {
            userSex = "male"
        } else if profileGender == .female {
            userSex = "female"
        }

        // Sync age from OnboardingManager
        if let profileAge = OnboardingManager.shared.userAge, profileAge >= 15 && profileAge <= 100 {
            userAge = profileAge
        }

        // Initialize text fields
        ageText = "\(userAge)"
        heightText = "\(Int(userHeightCm))"
        weightText = String(format: "%.1f", userWeightKg)

        // Load latest weight from Firebase
        loadLatestWeight()
    }

    private func loadLatestWeight() {
        Task {
            do {
                let entries = try await firebaseManager.getWeightHistory()
                if let latest = entries.first {
                    await MainActor.run {
                        userWeightKg = latest.weight
                        weightText = String(format: "%.1f", latest.weight)
                    }
                }

                let settings = try await firebaseManager.getUserSettings()
                if let height = settings.height, height > 0 {
                    await MainActor.run {
                        userHeightCm = height
                        heightText = "\(Int(height))"
                    }
                }
            } catch {
                // Silent fail - user can enter values manually
            }
        }
    }

    private func updateValue(field: BMRFieldType, value: String) {
        switch field {
        case .age:
            if let age = Int(value), age >= 15 && age <= 100 {
                userAge = age
            }
        case .height:
            if let height = Double(value), height >= 100 && height <= 250 {
                userHeightCm = height
            }
        case .weight:
            if let weight = Double(value), weight >= 30 && weight <= 300 {
                userWeightKg = weight
            }
        }
    }
}

// MARK: - Preview

#Preview {
    DietManagementRedesigned(
        macroGoals: .constant(MacroGoal.defaultMacros),
        dietType: .constant(.flexible),
        customCarbLimit: .constant(50),
        onSave: { _ in }
    )
    .environmentObject(FirebaseManager.shared)
}
