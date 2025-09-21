import SwiftUI
import Foundation

struct ExerciseSelectorView: View {
    @Binding var selectedExercise: String
    @Binding var searchText: String
    let filteredExercises: [String]
    let presetExercises: [String]
    @Binding var isCustomExercise: Bool
    
    @Environment(\.dismiss) private var dismiss
    @State private var customExerciseName = ""
    @State private var showingCustomInput = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                    
                    Spacer()
                    
                    Text("Select Exercise")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button("Done") {
                        if showingCustomInput && !customExerciseName.isEmpty {
                            selectedExercise = customExerciseName
                            isCustomExercise = true
                        }
                        dismiss()
                    }
                    .foregroundColor(.blue)
                    .fontWeight(.semibold)
                    .disabled(showingCustomInput && customExerciseName.isEmpty)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .background(.ultraThinMaterial)
                
                // Search Bar
                HStack {
                    TextField(StringConstants.searchFoodsPlaceholder, text: $searchText)
                        .textFieldStyle(.roundedBorder)
                    
                    Button("Custom") {
                        showingCustomInput.toggle()
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.blue)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(showingCustomInput ? .blue.opacity(0.05) : .clear)
                            .stroke(.blue, lineWidth: 1)
                    )
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                
                // Custom Exercise Input
                if showingCustomInput {
                    VStack(spacing: 8) {
                        TextField("Enter custom exercise name", text: $customExerciseName)
                            .textFieldStyle(.roundedBorder)
                        
                        Text("Create your own exercise")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
                
                // Exercise List
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(filteredExercises, id: \.self) { exercise in
                            Button(action: {
                                selectedExercise = exercise
                                isCustomExercise = false
                                dismiss()
                            }) {
                                HStack {
                                    Text(exercise)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    if selectedExercise == exercise {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.blue)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(selectedExercise == exercise ? .blue.opacity(0.05) : Color(.systemGray6))
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}