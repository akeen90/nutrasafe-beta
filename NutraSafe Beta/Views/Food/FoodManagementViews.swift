//
//  FoodManagementViews.swift
//  NutraSafe Beta
//
//  Phase 12B: Food Management & Movement Views
//  Components extracted from ContentView.swift (Lines: 9576-11302)
//  Includes food movement controls and photo capture functionality
//

import SwiftUI
import Foundation
import Vision
import AVFoundation

// MARK: - Database Photo Prompt View

struct DatabasePhotoPromptView: View {
    let foodName: String
    let brandName: String?
    let sourceType: FoodSourceType
    let onPhotosCompleted: (UIImage?, UIImage?, UIImage?) -> Void
    let onSkip: () -> Void
    
    @State private var ingredientsImage: UIImage?
    @State private var nutritionImage: UIImage?
    @State private var barcodeImage: UIImage?
    @State private var showingIngredientsCamera = false
    @State private var showingNutritionCamera = false
    @State private var showingBarcodeCamera = false
    @State private var currentPhotoType: PhotoType = .ingredients
    @Environment(\.dismiss) private var dismiss
    
    enum PhotoType {
        case ingredients, nutrition, barcode
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "camera.fill.badge.ellipsis")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Help Build Our Database!")
                        .font(.title.bold())
                        .multilineTextAlignment(.center)
                    
                    Text("Take optional photos to help us improve nutrition data for \"\(foodName)\"")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Ingredients Photo Section
                        PhotoCaptureSection(
                            title: "📝 Ingredients List",
                            description: "Get accurate allergen warnings & ingredient analysis",
                            image: ingredientsImage,
                            onTakePhoto: {
                                currentPhotoType = .ingredients
                                showingIngredientsCamera = true
                            },
                            onRemove: { ingredientsImage = nil }
                        )
                        
                        // Nutrition Label Section
                        PhotoCaptureSection(
                            title: "📊 Nutrition Label",
                            description: "Get precise calorie & macro tracking for your goals",
                            image: nutritionImage,
                            onTakePhoto: {
                                currentPhotoType = .nutrition
                                showingNutritionCamera = true
                            },
                            onRemove: { nutritionImage = nil }
                        )
                        
                        // Barcode Section (only show if not found via barcode)
                        if sourceType != .barcode {
                            PhotoCaptureSection(
                                title: "🏷️ Barcode",
                                description: "Enable faster scanning & product recognition next time",
                                image: barcodeImage,
                                onTakePhoto: {
                                    currentPhotoType = .barcode
                                    showingBarcodeCamera = true
                                },
                                onRemove: { barcodeImage = nil }
                            )
                        }
                    }
                    .padding()
                }
                
                // Bottom buttons
                VStack(spacing: 12) {
                    if ingredientsImage != nil || nutritionImage != nil || barcodeImage != nil {
                        Button(action: {
                            onPhotosCompleted(ingredientsImage, nutritionImage, barcodeImage)
                            dismiss()
                        }) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text(getSubmitButtonText())
                                    .font(.headline.weight(.semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(12)
                        }
                    }
                    
                    Button(action: {
                        onSkip()
                        dismiss()
                    }) {
                        Text("Just Add to Log")
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                    }
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onSkip()
                        dismiss()
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showingIngredientsCamera) {
            IngredientCameraView(
                foodName: foodName,
                onImageCaptured: { image in
                    ingredientsImage = image
                    showingIngredientsCamera = false
                },
                onDismiss: {
                    showingIngredientsCamera = false
                },
                photoType: .ingredients
            )
        }
        .fullScreenCover(isPresented: $showingNutritionCamera) {
            IngredientCameraView(
                foodName: foodName,
                onImageCaptured: { image in
                    nutritionImage = image
                    showingNutritionCamera = false
                },
                onDismiss: {
                    showingNutritionCamera = false
                },
                photoType: .nutrition
            )
        }
        .fullScreenCover(isPresented: $showingBarcodeCamera) {
            IngredientCameraView(
                foodName: foodName,
                onImageCaptured: { image in
                    barcodeImage = image
                    showingBarcodeCamera = false
                },
                onDismiss: {
                    showingBarcodeCamera = false
                },
                photoType: .barcode
            )
        }
    }
    
    private func getSubmitButtonText() -> String {
        let hasIngredients = ingredientsImage != nil
        let hasNutrition = nutritionImage != nil
        let hasBarcode = barcodeImage != nil
        
        if hasIngredients && hasNutrition && hasBarcode {
            return "Submit All Photos & Add to Log"
        } else if hasIngredients && hasNutrition {
            return "Submit Ingredients & Nutrition & Add to Log"
        } else if hasIngredients && hasBarcode {
            return "Submit Ingredients & Barcode & Add to Log"
        } else if hasNutrition && hasBarcode {
            return "Submit Nutrition & Barcode & Add to Log"
        } else if hasIngredients {
            return "Submit Ingredients & Add to Log"
        } else if hasNutrition {
            return "Submit Nutrition & Add to Log"
        } else if hasBarcode {
            return "Submit Barcode & Add to Log"
        } else {
            return "Submit Photos & Add to Log"
        }
    }
    
    private func createImageFromText(_ text: String) -> UIImage? {
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16),
            .foregroundColor: UIColor.label,
            .backgroundColor: UIColor.systemBackground
        ]
        
        let attributedText = NSAttributedString(string: text, attributes: textAttributes)
        let size = attributedText.boundingRect(
            with: CGSize(width: 300, height: CGFloat.greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        ).size
        
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size.width + 24, height: size.height + 24))
        
        return renderer.image { context in
            UIColor.systemBackground.setFill()
            context.fill(CGRect(origin: .zero, size: renderer.format.bounds.size))
            
            attributedText.draw(in: CGRect(x: 10, y: 10, width: size.width, height: size.height))
        }
    }
}

// MARK: - Photo Capture Section

struct PhotoCaptureSection: View {
    let title: String
    let description: String
    let image: UIImage?
    let onTakePhoto: () -> Void
    let onRemove: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if image != nil {
                    Button(action: onRemove) {
                        Image(systemName: "trash.circle.fill")
                            .font(.title2)
                            .foregroundColor(.red)
                    }
                }
            }
            
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 200)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.green, lineWidth: 2)
                    )
            } else {
                Button(action: onTakePhoto) {
                    VStack(spacing: 8) {
                        Image(systemName: "camera.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                        
                        Text("Tap to Take Photo")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 120)
                    .background(Color.blue.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.blue.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [5]))
                    )
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Enhanced Photo Capture Section

struct EnhancedPhotoCaptureSection: View {
    let title: String
    let description: String
    let image: UIImage?
    let onTakePhoto: () -> Void
    let onLiveScan: () -> Void
    let onRemove: () -> Void
    let showLiveScanOption: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if image != nil {
                    Button(action: onRemove) {
                        Image(systemName: "trash.circle.fill")
                            .font(.title2)
                            .foregroundColor(.red)
                    }
                }
            }
            
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 200)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.green, lineWidth: 2)
                    )
            } else {
                if showLiveScanOption {
                    HStack(spacing: 12) {
                        // Traditional Photo Button
                        Button(action: onTakePhoto) {
                            VStack(spacing: 8) {
                                Image(systemName: "camera.fill")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                                
                                Text("Take Photo")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 120)
                            .background(Color.blue.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.blue.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [5]))
                            )
                            .cornerRadius(8)
                        }
                        
                        // Live Scan Button
                        Button(action: onLiveScan) {
                            VStack(spacing: 8) {
                                Image(systemName: "text.viewfinder")
                                    .font(.title2)
                                    .foregroundColor(.purple)
                                
                                Text("Live Scan")
                                    .font(.subheadline)
                                    .foregroundColor(.purple)
                                
                                Text("NEW")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.purple)
                                    .cornerRadius(4)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 120)
                            .background(Color.purple.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.purple.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [5]))
                            )
                            .cornerRadius(8)
                        }
                    }
                } else {
                    Button(action: onTakePhoto) {
                        VStack(spacing: 8) {
                            Image(systemName: "camera.fill")
                                .font(.title2)
                                .foregroundColor(.blue)
                            
                            Text("Tap to Take Photo")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 120)
                        .background(Color.blue.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.blue.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [5]))
                        )
                        .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Move Food Sheet

struct MoveFoodSheet: View {
    let selectedCount: Int
    let currentDate: Date
    @Binding var moveToDate: Date
    @Binding var moveToMeal: String
    let onMove: () -> Void
    let onCancel: () -> Void
    
    private let mealOptions = ["Breakfast", "Lunch", "Dinner", "Snacks"]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Move \(selectedCount) food item\(selectedCount > 1 ? "s" : "")")
                        .font(.headline)
                        .padding(.horizontal, 24)
                    
                    // Date Selector with day and date display
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Select Date")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .padding(.horizontal, 24)
                        
                        DatePicker(
                            "",
                            selection: $moveToDate,
                            displayedComponents: .date
                        )
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .padding(.horizontal, 24)
                    }
                    
                    // Meal Selector
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Select Meal")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .padding(.horizontal, 24)
                        
                        Picker("Meal", selection: $moveToMeal) {
                            ForEach(mealOptions, id: \.self) { meal in
                                Text(meal).tag(meal)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, 24)
                    }
                }
                .padding(.vertical, 24)
                
                Spacer()
                
                // Action buttons
                HStack(spacing: 16) {
                    Button("Cancel") {
                        onCancel()
                    }
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    Button("Move") {
                        onMove()
                    }
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
            .navigationTitle("Move Food Items")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
            }
        }
    }
}

// MARK: - Move Food Bottom Sheet

struct MoveFoodBottomSheet: View {
    let selectedCount: Int
    let currentDate: Date
    @Binding var moveToDate: Date
    @Binding var moveToMeal: String
    let onMove: () -> Void
    let onCancel: () -> Void
    
    private let mealOptions = ["Breakfast", "Lunch", "Dinner", "Snacks"]
    
    var body: some View {
        VStack(spacing: 0) {
            // Drag indicator (custom for better visibility)
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(.systemGray3))
                .frame(width: 40, height: 6)
                .padding(.top, 12)
                .padding(.bottom, 8)
            
            // Header with food count badge
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Move Food")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.right.circle.fill")
                                .foregroundColor(.blue)
                                .font(.system(size: 16))
                            
                            Text("\(selectedCount) item\(selectedCount > 1 ? "s" : "") selected")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    // Selected count badge
                    Text("\(selectedCount)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 28, height: 28)
                        .background(Color.blue)
                        .clipShape(Circle())
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                
                // Subtle divider
                Rectangle()
                    .fill(Color(.systemGray5))
                    .frame(height: 1)
                    .padding(.horizontal, 20)
            }
            
            // Date Selector in ScrollView
            ScrollView {
                VStack(spacing: 16) {
                    // Date Selector Card
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(.blue)
                                .font(.system(size: 18))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Select Date")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Text(formatDateWithDayName(moveToDate))
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                                    .fontWeight(.medium)
                            }
                            
                            Spacer()
                        }
                        
                        // iOS-style date picker roller
                        VStack(spacing: 8) {
                            Text("Select date")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            DateRollerPicker(selection: $moveToDate)
                                .frame(height: 120)
                        }
                        
                        // Enhanced date picker
                        HStack {
                            Image(systemName: "calendar.badge.clock")
                                .foregroundColor(.secondary)
                                .font(.system(size: 16))
                            
                            DatePicker("", selection: $moveToDate, displayedComponents: .date)
                                .datePickerStyle(.compact)
                                .labelsHidden()
                                .scaleEffect(0.9)
                            
                            Spacer()
                        }
                        .padding(.top, 8)
                    }
                    .padding(.all, 24)
                    .background(Color.adaptiveCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(.systemGray5), lineWidth: 1)
                    )
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 16)
            }
            
            // Fixed Meal Selector (always visible)
            VStack(spacing: 16) {
                Rectangle()
                    .fill(Color(.systemGray6))
                    .frame(height: 1)
                
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "fork.knife")
                            .foregroundColor(.green)
                            .font(.system(size: 18))
                        
                        Text("Select Meal")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                    
                    Picker("Meal", selection: $moveToMeal) {
                        ForEach(mealOptions, id: \.self) { meal in
                            Text(meal)
                                .font(.system(size: 14, weight: .medium))
                                .tag(meal)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .padding(.horizontal, 20)
            }
            
            // Enhanced action buttons with better styling
            VStack(spacing: 12) {
                Rectangle()
                    .fill(Color(.systemGray6))
                    .frame(height: 1)
                
                HStack(spacing: 14) {
                    Button(action: onCancel) {
                        HStack(spacing: 8) {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .medium))
                            Text("Cancel")
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(.systemGray6))
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color(.systemGray4), lineWidth: 0.5)
                        )
                    }
                    
                    Button(action: onMove) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.right")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Move Items")
                                .font(.headline.weight(.semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.9)]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .cornerRadius(14)
                        .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 34) // Safe area padding
            }
            .background(Color(.systemGray6).opacity(0.3))
        }
    }
    
    private func formatDateWithDayName(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDate(date, inSameDayAs: now) {
            return "Today"
        } else if calendar.isDate(date, inSameDayAs: calendar.date(byAdding: .day, value: -1, to: now) ?? now) {
            return "Yesterday"
        } else if calendar.isDate(date, inSameDayAs: calendar.date(byAdding: .day, value: 1, to: now) ?? now) {
            return "Tomorrow"
        } else {
            let daysDiff = calendar.dateComponents([.day], from: date, to: now).day ?? 0
            if abs(daysDiff) <= 6 {
                // Show day name for current week - PERFORMANCE: Use cached static formatter
                return DateHelper.fullDayOfWeekFormatter.string(from: date)
            } else {
                // Show full date for older entries - PERFORMANCE: Use cached static formatter
                return DateHelper.dayMonthShortFormatter.string(from: date)
            }
        }
    }

    private func getRollerDateOptions() -> [(name: String, date: Date)] {
        let calendar = Calendar.current
        let today = Date()
        var options: [(name: String, date: Date)] = []
        
        // Generate dates from 30 days ago to 7 days in future, starting from today
        for i in (-30...7) {
            if let date = calendar.date(byAdding: .day, value: i, to: today) {
                let name = formatDateContextual(date)
                options.append((name, date))
            }
        }
        
        return options
    }
    
    private func formatDateContextual(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDate(date, inSameDayAs: now) {
            return "Today"
        } else if calendar.isDate(date, inSameDayAs: calendar.date(byAdding: .day, value: -1, to: now) ?? now) {
            return "Yesterday"
        } else if calendar.isDate(date, inSameDayAs: calendar.date(byAdding: .day, value: 1, to: now) ?? now) {
            return "Tomorrow"
        } else {
            let daysDiff = calendar.dateComponents([.day], from: date, to: now).day ?? 0
            if abs(daysDiff) <= 6 {
                // PERFORMANCE: Use cached static formatter
                return DateHelper.fullDayOfWeekFormatter.string(from: date)
            } else {
                // PERFORMANCE: Use cached static formatter
                return DateHelper.dayMonthShortFormatter.string(from: date)
            }
        }
    }

    private func formatDateShort(_ date: Date) -> String {
        // PERFORMANCE: Use cached static formatter
        DateHelper.compactDayMonthFormatter.string(from: date)
    }
}

// MARK: - iOS-style Date Roller Picker

struct DateRollerPicker: View {
    @Binding var selection: Date
    @State private var dragOffset: CGFloat = 0
    @State private var currentIndex: Int = 0
    
    private let itemHeight: CGFloat = 40
    private var dates: [Date] {
        let calendar = Calendar.current
        let today = Date()
        var dateArray: [Date] = []
        
        // Generate dates chronologically: past to future
        // Users can scroll up for older dates, down for newer dates
        
        // Add past dates (90 days ago to yesterday) - for adding old entries
        for i in (1...90).reversed() {
            if let pastDate = calendar.date(byAdding: .day, value: -i, to: today) {
                dateArray.append(pastDate)
            }
        }
        
        // Add today (this will be the initial selection)
        dateArray.append(today)
        
        // Add future dates (1-14 days ahead) for planning ahead
        for i in 1...14 {
            if let futureDate = calendar.date(byAdding: .day, value: i, to: today) {
                dateArray.append(futureDate)
            }
        }
        
        return dateArray
    }
    
    private var todayIndex: Int {
        // Find today's index in the dates array
        let calendar = Calendar.current
        let today = Date()
        return dates.firstIndex { calendar.isDate($0, inSameDayAs: today) } ?? 90 // Should be at index 90
    }
    
    var body: some View {
        GeometryReader { geometry in
            let visibleHeight = geometry.size.height
            let centerOffset = visibleHeight / 2 - itemHeight / 2
            
            ZStack {
                backgroundView
                selectionIndicatorView
                scrollContentView(centerOffset: centerOffset)
            }
        }
    }
    
    private var backgroundView: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color(.systemGray6))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.systemGray4), lineWidth: 0.5)
            )
    }
    
    private var selectionIndicatorView: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.adaptiveCard)
            .frame(height: itemHeight)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private func scrollContentView(centerOffset: CGFloat) -> some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    ForEach(Array(dates.enumerated()), id: \.offset) { index, date in
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                selection = date
                                currentIndex = index
                                proxy.scrollTo(index, anchor: .center)
                            }
                        }) {
                            HStack {
                                Spacer()
                                
                                VStack(spacing: 2) {
                                    Text(formatDateForRoller(date))
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.primary)
                                    
                                    Text(formatDateShortForRoller(date))
                                        .font(.system(size: 11, weight: .regular))
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                            }
                            .frame(height: itemHeight)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        .id(index)
                    }
                }
                .padding(.vertical, centerOffset)
            }
            .onAppear {
                // Start at the current selection date, not necessarily today
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    let calendar = Calendar.current
                    let targetIndex = dates.firstIndex { calendar.isDate($0, inSameDayAs: selection) } ?? todayIndex
                    proxy.scrollTo(targetIndex, anchor: .center)
                    currentIndex = targetIndex
                }
            }
        }
    }
    
    private func formatDateForRoller(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDate(date, inSameDayAs: now) {
            return "Today"
        } else if calendar.isDate(date, inSameDayAs: calendar.date(byAdding: .day, value: -1, to: now) ?? now) {
            return "Yesterday"
        } else if calendar.isDate(date, inSameDayAs: calendar.date(byAdding: .day, value: 1, to: now) ?? now) {
            return "Tomorrow"
        } else {
            let daysDiff = calendar.dateComponents([.day], from: date, to: now).day ?? 0
            if abs(daysDiff) <= 6 {
                // PERFORMANCE: Use cached static formatter
                return DateHelper.fullDayOfWeekFormatter.string(from: date)
            } else {
                // PERFORMANCE: Use cached static formatter
                return DateHelper.dayMonthLongFormatter.string(from: date)
            }
        }
    }

    private func formatDateShortForRoller(_ date: Date) -> String {
        // PERFORMANCE: Use cached static formatter
        DateHelper.compactDayMonthFormatter.string(from: date)
    }
}

// MARK: - Copy Food Bottom Sheet

struct CopyFoodBottomSheet: View {
    let selectedCount: Int
    let currentDate: Date
    @Binding var copyToDate: Date
    @Binding var copyToMeal: String
    let onCopy: () -> Void
    let onCancel: () -> Void

    private let mealOptions = ["Breakfast", "Lunch", "Dinner", "Snacks"]

    var body: some View {
        VStack(spacing: 0) {
            // Drag indicator (custom for better visibility)
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(.systemGray3))
                .frame(width: 40, height: 6)
                .padding(.top, 12)
                .padding(.bottom, 8)

            // Header with food count badge
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Copy Food")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)

                        HStack(spacing: 6) {
                            Image(systemName: "doc.on.doc.fill")
                                .foregroundColor(.blue)
                                .font(.system(size: 16))

                            Text("\(selectedCount) item\(selectedCount > 1 ? "s" : "") selected")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    // Selected count badge
                    Text("\(selectedCount)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 28, height: 28)
                        .background(Color.blue)
                        .clipShape(Circle())
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)

                // Subtle divider
                Rectangle()
                    .fill(Color(.systemGray5))
                    .frame(height: 1)
                    .padding(.horizontal, 20)
            }

            // Date Selector in ScrollView
            ScrollView {
                VStack(spacing: 16) {
                    // Date Selector Card
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(.blue)
                                .font(.system(size: 18))

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Select Date")
                                    .font(.headline)
                                    .foregroundColor(.primary)

                                Text(formatDateWithDayName(copyToDate))
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                                    .fontWeight(.medium)
                            }

                            Spacer()
                        }

                        // iOS-style date picker roller
                        VStack(spacing: 8) {
                            Text("Select date")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            DateRollerPicker(selection: $copyToDate)
                                .frame(height: 120)
                        }

                        // Enhanced date picker
                        HStack {
                            Image(systemName: "calendar.badge.clock")
                                .foregroundColor(.secondary)
                                .font(.system(size: 16))

                            DatePicker("", selection: $copyToDate, displayedComponents: .date)
                                .datePickerStyle(.compact)
                                .labelsHidden()
                                .scaleEffect(0.9)

                            Spacer()
                        }
                        .padding(.top, 8)
                    }
                    .padding(.all, 24)
                    .background(Color.adaptiveCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(.systemGray5), lineWidth: 1)
                    )
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 16)
            }

            // Fixed Meal Selector (always visible)
            VStack(spacing: 16) {
                Rectangle()
                    .fill(Color(.systemGray6))
                    .frame(height: 1)

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "fork.knife")
                            .foregroundColor(.green)
                            .font(.system(size: 18))

                        Text("Select Meal")
                            .font(.headline)
                            .foregroundColor(.primary)

                        Spacer()
                    }

                    Picker("Meal", selection: $copyToMeal) {
                        ForEach(mealOptions, id: \.self) { meal in
                            Text(meal)
                                .font(.system(size: 14, weight: .medium))
                                .tag(meal)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .padding(.horizontal, 20)
            }

            // Enhanced action buttons with better styling
            VStack(spacing: 12) {
                Rectangle()
                    .fill(Color(.systemGray6))
                    .frame(height: 1)

                HStack(spacing: 14) {
                    Button(action: onCancel) {
                        HStack(spacing: 8) {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .medium))
                            Text("Cancel")
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(.systemGray6))
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color(.systemGray4), lineWidth: 0.5)
                        )
                    }

                    Button(action: onCopy) {
                        HStack(spacing: 8) {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Copy Items")
                                .font(.headline.weight(.semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.9)]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .cornerRadius(14)
                        .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 34) // Safe area padding
            }
            .background(Color(.systemGray6).opacity(0.3))
        }
    }

    private func formatDateWithDayName(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()

        if calendar.isDate(date, inSameDayAs: now) {
            return "Today"
        } else if calendar.isDate(date, inSameDayAs: calendar.date(byAdding: .day, value: -1, to: now) ?? now) {
            return "Yesterday"
        } else if calendar.isDate(date, inSameDayAs: calendar.date(byAdding: .day, value: 1, to: now) ?? now) {
            return "Tomorrow"
        } else {
            let daysDiff = calendar.dateComponents([.day], from: date, to: now).day ?? 0
            if abs(daysDiff) <= 6 {
                // Show day name for current week - PERFORMANCE: Use cached static formatter
                return DateHelper.fullDayOfWeekFormatter.string(from: date)
            } else {
                // Show full date for older entries - PERFORMANCE: Use cached static formatter
                return DateHelper.dayMonthShortFormatter.string(from: date)
            }
        }
    }
}

// MARK: - Presentation Modifier for iOS compatibility

struct PresentationModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .presentationDetents([.fraction(0.65)]) // Show 65% of screen so diary is still visible behind
            .presentationDragIndicator(.visible)
            .presentationBackgroundInteraction(.enabled(upThrough: .fraction(0.65)))
    }
}