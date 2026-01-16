import SwiftUI

struct FastingEducationView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showingSources = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "graduationcap.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)

                        Text("Understanding Fasting")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)

                        Text("Learn about different fasting approaches and what happens during your fast")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top)

                    // Philosophy Information (Display Only)
                    VStack(spacing: 16) {
                        Text("Allowed Drinks Philosophy")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Text("Choose your approach when creating or editing a fasting plan")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        ForEach(AllowedDrinksPhilosophy.allCases, id: \.self) { mode in
                            PhilosophyInfoCard(mode: mode)
                        }
                    }
                    
                    // Phase Timeline Education
                    PhaseTimelineEducation()

                    // Scientific Sources Button
                    Button(action: {
                        showingSources = true
                    }) {
                        HStack {
                            Image(systemName: "doc.text.fill")
                                .foregroundColor(.blue)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("View Scientific Sources")
                                    .font(.headline)
                                    .foregroundColor(.primary)

                                Text("All claims backed by peer-reviewed research")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .cardBackground(cornerRadius: 12)
                    }
                    .buttonStyle(.plain)

                    // Tips and Guidelines
                    TipsSection()

                    // Getting Started
                    GettingStartedSection()
                }
                .padding()
            }
            .navigationTitle("Fasting Education")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .fullScreenCover(isPresented: $showingSources) {
                FastingCitationsView()
            }
        }
    }
}

// Display-only info card for education view
struct PhilosophyInfoCard: View {
    let mode: AllowedDrinksPhilosophy

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                // Icon based on mode
                Image(systemName: iconForMode)
                    .font(.title2)
                    .foregroundColor(colorForMode)
                    .frame(width: 30, height: 30)

                VStack(alignment: .leading, spacing: 4) {
                    Text(mode.displayName)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    Text(mode.tone)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                }

                Spacer()
            }

            // Description
            Text(mode.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Allowed items
            VStack(alignment: .leading, spacing: 6) {
                Text("Allowed:")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                ForEach(allowedItems, id: \.self) { item in
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark")
                            .font(.caption)
                            .foregroundColor(.green)
                            .frame(width: 12)

                        Text(item)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.top, 4)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(colorForMode.opacity(0.05))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(colorForMode.opacity(0.2), lineWidth: 1)
        )
    }

    private var iconForMode: String {
        switch mode {
        case .strict:
            return "drop.fill"
        case .practical:
            return "leaf.fill"
        case .lenient:
            return "heart.fill"
        }
    }

    private var colorForMode: Color {
        switch mode {
        case .strict:
            return .blue
        case .practical:
            return .green
        case .lenient:
            return .pink
        }
    }

    private var allowedItems: [String] {
        switch mode {
        case .strict:
            return [
                "Water (still or sparkling)",
                "Plain black coffee",
                "Plain tea (black, green, herbal)",
                "Electrolyte supplements",
                "Salt water"
            ]
        case .practical:
            return [
                "All strict items",
                "Sugar-free drinks",
                "Diet sodas (occasionally)",
                "Zero-calorie flavoured water",
                "Black coffee with zero-cal sweeteners"
            ]
        case .lenient:
            return [
                "All practical items",
                "Coffee with splash of milk (<30 cal)",
                "Tea with honey (<30 cal)",
                "Bone broth (<30 cal)",
                "Small amounts of creamer"
            ]
        }
    }
}

// Selectable card for plan creation/editing
struct PhilosophyCard: View {
    let mode: AllowedDrinksPhilosophy
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    // Icon based on mode
                    Image(systemName: iconForMode)
                        .font(.title2)
                        .foregroundColor(colorForMode)
                        .frame(width: 30, height: 30)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(mode.displayName)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)

                        Text(mode.tone)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                    }

                    Spacer()

                    // Selection indicator
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(colorForMode)
                    }
                }

                // Description
                Text(mode.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Allowed items
                VStack(alignment: .leading, spacing: 6) {
                    Text("Allowed:")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)

                    ForEach(allowedItems, id: \.self) { item in
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark")
                                .font(.caption)
                                .foregroundColor(.green)
                                .frame(width: 12)

                            Text(item)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.top, 4)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(backgroundColor)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(borderColor, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var iconForMode: String {
        switch mode {
        case .strict:
            return "drop.fill"
        case .practical:
            return "leaf.fill"
        case .lenient:
            return "heart.fill"
        }
    }
    
    private var colorForMode: Color {
        switch mode {
        case .strict:
            return .blue
        case .practical:
            return .green
        case .lenient:
            return .pink
        }
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return colorForMode.opacity(0.1)
        } else {
            return Color.gray.opacity(0.05)
        }
    }
    
    private var borderColor: Color {
        if isSelected {
            return colorForMode.opacity(0.5)
        } else {
            return Color.gray.opacity(0.2)
        }
    }
    
    private var allowedItems: [String] {
        switch mode {
        case .strict:
            return [
                "Water (still or sparkling)",
                "Plain black coffee",
                "Plain tea (black, green, herbal)",
                "Electrolyte supplements",
                "Salt water"
            ]
        case .practical:
            return [
                "All strict items",
                "Sugar-free drinks",
                "Diet sodas (occasionally)",
                "Zero-calorie flavored water",
                "Black coffee with zero-cal sweeteners"
            ]
        case .lenient:
            return [
                "All practical items",
                "Coffee with splash of milk (<30 cal)",
                "Tea with honey (<30 cal)",
                "Bone broth (<30 cal)",
                "Small amounts of creamer"
            ]
        }
    }
}

struct PhaseTimelineEducation: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "timeline.selection")
                    .foregroundColor(.purple)
                Text("Fasting Timeline")
                    .font(.headline)
            }
            
            Text("Your body goes through different phases during fasting. These are approximate timelines:")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
            
            LazyVStack(spacing: 12) {
                ForEach(FastingPhase.allCases, id: \.self) { phase in
                    PhaseEducationRow(phase: phase)
                }
            }
            
            Text("Remember: Everyone's body is different. These timelines are general guidelines, not strict rules.")
                .font(.caption)
                .foregroundColor(.secondary)
                .italic()
                .padding(.top, 8)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardBackground(cornerRadius: 16)
    }
}

struct PhaseEducationRow: View {
    let phase: FastingPhase
    
    var body: some View {
        HStack(spacing: 12) {
            // Time indicator
            VStack(spacing: 2) {
                Text("\(phase.timeRange.lowerBound)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("hours")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(width: 40)
            .padding(8)
            .background(Color.purple.opacity(0.1))
            .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(phase.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(phase.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct TipsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.orange)
                Text("Helpful Tips")
                    .font(.headline)
            }
            
            LazyVStack(spacing: 12) {
                ForEach(tips, id: \.self) { tip in
                    TipRow(tip: tip)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardBackground(cornerRadius: 16)
    }

    private var tips: [Tip] {
        [
            Tip(
                icon: "drop.fill",
                title: "Stay Hydrated",
                description: "Drink plenty of water throughout your fast. Hydration helps reduce hunger and supports your body's natural processes."
            ),
            Tip(
                icon: "timer",
                title: "Start Slow",
                description: "If you're new to fasting, begin with shorter durations (12-14 hours) and gradually increase as your body adapts."
            ),
            Tip(
                icon: "heart.fill",
                title: "Listen to Your Body",
                description: "Pay attention to how you feel. If you experience severe discomfort, dizziness, or other concerning symptoms, break your fast."
            ),
            Tip(
                icon: "calendar.badge.clock",
                title: "Be Consistent",
                description: "Regular fasting is more beneficial than occasional long fasts. Aim for consistency rather than perfection."
            ),
            Tip(
                icon: "leaf.fill",
                title: "Break Gently",
                description: "When ending your fast, start with small, easily digestible foods. Avoid heavy meals immediately after fasting."
            )
        ]
    }
}

struct TipRow: View {
    let tip: Tip
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: tip.icon)
                .font(.title3)
                .foregroundColor(.orange)
                .frame(width: 30)
                .padding(.top, 2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(tip.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(tip.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
        }
        .padding(.vertical, 4)
    }
}

struct GettingStartedSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "flag.checkered")
                    .foregroundColor(.green)
                Text("Ready to Start?")
                    .font(.headline)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Remember: Fasting is a personal journey. What works for others may not work for you.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("Start with a plan that feels manageable, and adjust as you learn what your body needs.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("Progress compounds. Consistency > perfection.")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.green)
                    .italic()
            }
            
            HStack(spacing: 16) {
                ForEach(motivationalMessages, id: \.self) { message in
                    Text("\(message)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .italic()
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(12)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(12)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardBackground(cornerRadius: 16)
    }

    private var motivationalMessages: [String] {
        [
            "Every hour counts",
            "Trust the process",
            "Breathe and stay present",
            "Your body is adapting beautifully"
        ]
    }
}

struct Tip: Hashable {
    let icon: String
    let title: String
    let description: String
}

struct FirstUseEducationOverlay: View {
    @Binding var isPresented: Bool
    @State private var selectedMode: AllowedDrinksPhilosophy = .practical
    
    var body: some View {
        if isPresented {
            ZStack {
                Color.black.opacity(0.7)
                    .ignoresSafeArea()
                    .onTapGesture {
                        isPresented = false
                    }
                
                VStack(spacing: 20) {
                    VStack(spacing: 16) {
                        Image(systemName: "graduationcap.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                        
                        Text("Welcome to Fasting!")
                            .font(.title2)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        Text("Let's set up your preferred approach to drinks during fasting.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    VStack(spacing: 12) {
                        ForEach(AllowedDrinksPhilosophy.allCases, id: \.self) { mode in
                            PhilosophyCard(
                                mode: mode,
                                isSelected: selectedMode == mode,
                                action: {
                                    selectedMode = mode
                                }
                            )
                        }
                    }
                    
                    Button {
                        isPresented = false
                    } label: {
                        Text("Get Started")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .padding(.top, 8)
                }
                .padding()
                .background(Color.adaptiveCard)
                .cornerRadius(20)
                .padding()
                .shadow(radius: 20)
            }
        }
    }
}

#Preview {
    NavigationStack {
        FastingEducationView()
    }
}

#Preview {
    FirstUseEducationOverlay(isPresented: .constant(true))
}