//
//  ReactionPDFExporter.swift
//  NutraSafe Beta
//
//  PDF export for reaction logs - for nutritionist review
//

import Foundation
import PDFKit
import UIKit
import FirebaseFirestore

class ReactionPDFExporter {

    // MARK: - Multi-Reaction Report Export (Last 5 Reactions)

    static func exportMultipleReactionsReport(reactions: [ReactionLogEntry], userName: String = "User", mealHistory: [FoodEntry] = [], allReactions: [ReactionLogEntry] = []) -> URL? {
        guard !reactions.isEmpty else { return nil }

        let pdfMetaData = [
            kCGPDFContextCreator: "NutraSafe",
            kCGPDFContextAuthor: userName,
            kCGPDFContextTitle: "Comprehensive Reaction Analysis Report"
        ]

        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]

        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792) // US Letter size
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

        let data = renderer.pdfData { context in
            context.beginPage()

            var yPosition: CGFloat = 50

            // Header
            yPosition = drawHeader(in: context, y: yPosition, pageWidth: pageRect.width)

            // User Info
            yPosition = drawUserInfo(in: context, y: yPosition, userName: userName)

            // SECTION 1: Most Recent Reaction
            // Safe access - guard at function start ensures array is non-empty
            guard let mostRecentReaction = reactions.first else { return }
            yPosition = drawSectionHeader(in: context, y: yPosition, title: "MOST RECENT REACTION", pageRect: pageRect)
            yPosition = drawReactionDetails(in: context, y: yPosition, entry: mostRecentReaction)

            if let analysis = mostRecentReaction.triggerAnalysis {
                yPosition = drawAnalysisSummary(in: context, y: yPosition, analysis: analysis)

                // Top Foods from most recent reaction
                if !analysis.topFoods.isEmpty {
                    yPosition = drawTopFoods(in: context, y: yPosition, foods: analysis.topFoods, pageHeight: pageRect.height)
                }

                // Top Ingredients from most recent reaction
                if !analysis.topIngredients.isEmpty {
                    yPosition = drawTopIngredients(in: context, y: yPosition, ingredients: analysis.topIngredients, pageHeight: pageRect.height)
                }
            }

            // SECTION 2: 7-Day Meal History
            if !mealHistory.isEmpty {
                yPosition = drawSectionHeader(in: context, y: yPosition, title: "7-DAY MEAL HISTORY", pageRect: pageRect)
                yPosition = drawMealHistory(in: context, y: yPosition, meals: mealHistory, pageRect: pageRect)
            }

            // SECTION 3: Previous Reactions (reactions 2-5)
            if reactions.count > 1 {
                let previousReactions = Array(reactions.dropFirst())
                yPosition = drawSectionHeader(in: context, y: yPosition, title: "PREVIOUS REACTIONS", pageRect: pageRect)
                yPosition = drawPreviousReactionsSummary(in: context, y: yPosition, reactions: previousReactions, pageRect: pageRect)
            }

            // SECTION 4: Pattern Analysis - Recognized Allergens
            yPosition = drawSectionHeader(in: context, y: yPosition, title: "PATTERN ANALYSIS - RECOGNIZED ALLERGENS", pageRect: pageRect)
            yPosition = drawAllergenPatternAnalysis(in: context, y: yPosition, reactions: allReactions, pageRect: pageRect)

            // SECTION 5: Pattern Analysis - Other Ingredients
            yPosition = drawSectionHeader(in: context, y: yPosition, title: "PATTERN ANALYSIS - OTHER INGREDIENTS", pageRect: pageRect)
            yPosition = drawOtherIngredientPatternAnalysis(in: context, y: yPosition, reactions: allReactions, pageRect: pageRect)

            // Footer
            drawFooter(in: context, pageRect: pageRect)
        }

        // Save to temporary file
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("ComprehensiveReactionReport_\(Date().timeIntervalSince1970).pdf")

        do {
            try data.write(to: tempURL)
            return tempURL
        } catch {
                        return nil
        }
    }

    static func exportReactionReport(entry: ReactionLogEntry, userName: String = "User", mealHistory: [FoodEntry] = [], allReactions: [ReactionLogEntry] = []) -> URL? {
        let pdfMetaData = [
            kCGPDFContextCreator: "NutraSafe",
            kCGPDFContextAuthor: userName,
            kCGPDFContextTitle: "Reaction Analysis Report"
        ]

        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]

        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792) // US Letter size
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

        let data = renderer.pdfData { context in
            context.beginPage()

            var yPosition: CGFloat = 50

            // Header
            yPosition = drawHeader(in: context, y: yPosition, pageWidth: pageRect.width)

            // User Info
            yPosition = drawUserInfo(in: context, y: yPosition, userName: userName)

            // Reaction Details
            yPosition = drawReactionDetails(in: context, y: yPosition, entry: entry)

            // Analysis Summary
            if let analysis = entry.triggerAnalysis {
                yPosition = drawAnalysisSummary(in: context, y: yPosition, analysis: analysis)

                // Top Foods
                if !analysis.topFoods.isEmpty {
                    yPosition = drawTopFoods(in: context, y: yPosition, foods: analysis.topFoods, pageHeight: pageRect.height)
                }

                // Top Ingredients
                if !analysis.topIngredients.isEmpty {
                    yPosition = drawTopIngredients(in: context, y: yPosition, ingredients: analysis.topIngredients, pageHeight: pageRect.height)
                }
            }

            // Other Reacted Foods (cross-reaction analysis)
            if !mealHistory.isEmpty && !allReactions.isEmpty {
                let crossReactionData = analyzeCrossReactions(currentEntry: entry, mealHistory: mealHistory, allReactions: allReactions)
                if !crossReactionData.isEmpty {
                    yPosition = drawCrossReactionAnalysis(in: context, y: yPosition, crossReactions: crossReactionData, pageRect: pageRect)
                }
            }

            // Pattern Analysis (Last 7 Reactions)
            if allReactions.count >= 2 {
                let patternData = analyzeReactionPatterns(reactions: allReactions)
                if !patternData.isEmpty {
                    yPosition = drawPatternAnalysis(in: context, y: yPosition, patterns: patternData, pageRect: pageRect)
                }
            }

            // Recent Reactions History (Last 7)
            if !allReactions.isEmpty {
                let recentReactions = Array(allReactions.prefix(7))
                yPosition = drawRecentReactionsHistory(in: context, y: yPosition, reactions: recentReactions, pageRect: pageRect)
            }

            // Meal History (7 Days Prior)
            if !mealHistory.isEmpty {
                yPosition = drawMealHistory(in: context, y: yPosition, meals: mealHistory, pageRect: pageRect)
            }

            // Footer
            drawFooter(in: context, pageRect: pageRect)
        }

        // Save to temporary file
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("ReactionReport_\(entry.id ?? UUID().uuidString).pdf")

        do {
            try data.write(to: tempURL)
            return tempURL
        } catch {
                        return nil
        }
    }

    // MARK: - Food Reaction Export (Simplified)

    static func exportFoodReactionReport(reaction: FoodReaction, userName: String = "User", mealHistory: [FoodEntry] = []) -> URL? {
        let pdfMetaData = [
            kCGPDFContextCreator: "NutraSafe",
            kCGPDFContextAuthor: userName,
            kCGPDFContextTitle: "Food Reaction Report"
        ]

        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]

        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792) // US Letter size
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

        let data = renderer.pdfData { context in
            context.beginPage()

            var yPosition: CGFloat = 50

            // Header
            yPosition = drawHeader(in: context, y: yPosition, pageWidth: pageRect.width)

            // User Info
            yPosition = drawUserInfo(in: context, y: yPosition, userName: userName)

            // Food Reaction Details
            yPosition = drawFoodReactionDetails(in: context, y: yPosition, reaction: reaction)

            // Meal History (7 Days Prior)
            if !mealHistory.isEmpty {
                yPosition = drawMealHistory(in: context, y: yPosition, meals: mealHistory, pageRect: pageRect)
            }

            // Footer
            drawFooter(in: context, pageRect: pageRect)
        }

        // Save to temporary file
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("FoodReaction_\(reaction.id.uuidString).pdf")

        do {
            try data.write(to: tempURL)
            return tempURL
        } catch {
                        return nil
        }
    }

    // MARK: - Multiple Food Reactions Export

    static func exportMultipleFoodReactions(reactions: [FoodReaction], mealHistory: [FoodEntry] = [], userName: String = "User") -> URL? {
        guard !reactions.isEmpty else { return nil }

        let pdfMetaData = [
            kCGPDFContextCreator: "NutraSafe",
            kCGPDFContextAuthor: userName,
            kCGPDFContextTitle: "Comprehensive Food Reactions Report"
        ]

        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]

        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792) // US Letter size
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

        let data = renderer.pdfData { context in
            context.beginPage()

            var yPosition: CGFloat = 50

            // Header
            yPosition = drawHeader(in: context, y: yPosition, pageWidth: pageRect.width)

            // User Info
            yPosition = drawUserInfo(in: context, y: yPosition, userName: userName)

            // SECTION 1: Latest Reaction at Top
            // Safe access - guard at function start ensures array is non-empty
            guard let latestReaction = reactions.first else { return }
            yPosition = drawSectionHeader(in: context, y: yPosition, title: "LATEST REACTION", pageRect: pageRect)
            yPosition = drawFoodReactionDetails(in: context, y: yPosition, reaction: latestReaction)

            // SECTION 2: 7-Day Meal History (if provided)
            if !mealHistory.isEmpty {
                yPosition = drawSectionHeader(in: context, y: yPosition, title: "7-DAY FOOD HISTORY", pageRect: pageRect)
                yPosition = drawMealHistory(in: context, y: yPosition, meals: mealHistory, pageRect: pageRect)
            }

            // SECTION 3: Past Reactions (up to 5 total, so reactions 2-5)
            if reactions.count > 1 {
                let pastReactions = Array(reactions.dropFirst().prefix(4)) // Take up to 4 more (5 total max)
                yPosition = drawSectionHeader(in: context, y: yPosition, title: "PAST REACTIONS", pageRect: pageRect)
                yPosition = drawPastFoodReactions(in: context, y: yPosition, reactions: pastReactions, pageRect: pageRect)
            }

            // SECTION 4: Pattern Analysis
            if reactions.count >= 3 {
                yPosition = drawSectionHeader(in: context, y: yPosition, title: "PATTERN ANALYSIS", pageRect: pageRect)
                yPosition = drawFoodReactionPatternAnalysis(in: context, y: yPosition, reactions: reactions, pageRect: pageRect)
            }

            // Footer
            drawFooter(in: context, pageRect: pageRect)
        }

        // Save to temporary file
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("ComprehensiveFoodReactionsReport_\(Date().timeIntervalSince1970).pdf")

        do {
            try data.write(to: tempURL)
            return tempURL
        } catch {
                        return nil
        }
    }

    // MARK: - Drawing Methods

    private static func drawHeader(in context: UIGraphicsPDFRendererContext, y: CGFloat, pageWidth: CGFloat) -> CGFloat {
        let title = "Food Reaction Analysis Report"
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 24),
            .foregroundColor: UIColor.black
        ]

        let titleSize = title.size(withAttributes: titleAttributes)
        let titleRect = CGRect(x: (pageWidth - titleSize.width) / 2, y: y, width: titleSize.width, height: titleSize.height)

        title.draw(in: titleRect, withAttributes: titleAttributes)

        return titleRect.maxY + 20
    }

    private static func drawUserInfo(in context: UIGraphicsPDFRendererContext, y: CGFloat, userName: String) -> CGFloat {
        var currentY = y

        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor.darkGray
        ]

        // Only show user name if provided and not default
        if !userName.isEmpty && userName != "User" {
            let userText = "User: \(userName)"
            userText.draw(at: CGPoint(x: 50, y: currentY), withAttributes: attributes)
            currentY += 20
        }

        let exportDate = "Export Date: \(Date().formatted(date: .long, time: .shortened))"
        exportDate.draw(at: CGPoint(x: 50, y: currentY), withAttributes: attributes)
        currentY += 30

        return currentY
    }

    private static func drawReactionDetails(in context: UIGraphicsPDFRendererContext, y: CGFloat, entry: ReactionLogEntry) -> CGFloat {
        var currentY = y

        // Section Header
        let headerAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 16),
            .foregroundColor: UIColor.black
        ]

        "Reaction Details".draw(at: CGPoint(x: 50, y: currentY), withAttributes: headerAttributes)
        currentY += 25

        // Details
        let detailsAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor.black
        ]

        let details = [
            "Type: \(entry.reactionType)",
            "Date: \(entry.reactionDate.formatted(date: .long, time: .omitted))",
            "Time: \(entry.reactionDate.formatted(date: .omitted, time: .shortened))",
            "Notes: \(entry.notes ?? "None")"
        ]

        for detail in details {
            detail.draw(at: CGPoint(x: 70, y: currentY), withAttributes: detailsAttributes)
            currentY += 18
        }

        currentY += 20
        return currentY
    }

    private static func drawFoodReactionDetails(in context: UIGraphicsPDFRendererContext, y: CGFloat, reaction: FoodReaction) -> CGFloat {
        var currentY = y

        // Section Header
        let headerAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 18),
            .foregroundColor: UIColor.black
        ]

        "Reaction Details".draw(at: CGPoint(x: 50, y: currentY), withAttributes: headerAttributes)
        currentY += 30

        // Modern inline label style
        let labelAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11, weight: .medium),
            .foregroundColor: UIColor.darkGray
        ]

        let valueAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 13, weight: .regular),
            .foregroundColor: UIColor.black
        ]

        let valueBoldAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14, weight: .semibold),
            .foregroundColor: UIColor.black
        ]

        let boxStartY = currentY

        // FIRST: Calculate height by measuring all content
        var contentHeight: CGFloat = 30 // Top padding

        // Food name
        contentHeight += 20

        // Brand if available
        if reaction.foodBrand != nil {
            contentHeight += 20
        }

        contentHeight += 5

        // Date/time
        contentHeight += 18

        // Severity
        contentHeight += 22

        // Symptoms
        if !reaction.symptoms.isEmpty {
            contentHeight += 16 // Label
            let symptomsText = reaction.symptoms.joined(separator: ", ")
            let symptomsSize = symptomsText.boundingRect(
                with: CGSize(width: 480, height: 1000),
                options: [.usesLineFragmentOrigin],
                attributes: valueAttributes,
                context: nil
            )
            contentHeight += symptomsSize.height + 8
        }

        contentHeight += 8

        // Suspected ingredients
        if !reaction.suspectedIngredients.isEmpty {
            contentHeight += 16 // Label
            // Show ALL ingredients, no truncation
            let ingredientsText = reaction.suspectedIngredients.joined(separator: ", ")
            let ingredientsSize = ingredientsText.boundingRect(
                with: CGSize(width: 480, height: 1000),
                options: [.usesLineFragmentOrigin],
                attributes: valueAttributes,
                context: nil
            )
            contentHeight += ingredientsSize.height + 8
        }

        contentHeight += 15 // Bottom padding

        // SECOND: Draw the background box FIRST
        let boxRect = CGRect(x: 50, y: boxStartY, width: 512, height: contentHeight)
        context.cgContext.setFillColor(UIColor(white: 0.97, alpha: 1.0).cgColor)
        context.cgContext.setStrokeColor(UIColor(white: 0.88, alpha: 1.0).cgColor)
        context.cgContext.setLineWidth(0.5)
        let roundedPath = UIBezierPath(roundedRect: boxRect, cornerRadius: 8)
        roundedPath.fill()
        roundedPath.stroke()

        // THIRD: Now draw all text content on top
        currentY += 15

        // Food Name (prominent)
        reaction.foodName.draw(at: CGPoint(x: 65, y: currentY), withAttributes: valueBoldAttributes)
        currentY += 20

        // Brand (if available) - inline
        if let brand = reaction.foodBrand {
            brand.draw(at: CGPoint(x: 65, y: currentY), withAttributes: valueAttributes)
            currentY += 20
        }

        currentY += 5

        // Date & Time - inline
        let date = reaction.timestamp.dateValue()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE, MMMM d, yyyy"
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"

        let dateTimeString = "\(dateFormatter.string(from: date)) at \(timeFormatter.string(from: date))"
        dateTimeString.draw(at: CGPoint(x: 65, y: currentY), withAttributes: valueAttributes)
        currentY += 18

        // Severity - inline
        let severityText = "Severity: \(severityString(for: reaction.severity))"
        severityText.draw(at: CGPoint(x: 65, y: currentY), withAttributes: valueAttributes)
        currentY += 22

        // Symptoms section
        if !reaction.symptoms.isEmpty {
            "SYMPTOMS".draw(at: CGPoint(x: 65, y: currentY), withAttributes: labelAttributes)
            currentY += 16

            let symptomsText = reaction.symptoms.joined(separator: ", ")
            let symptomsRect = CGRect(x: 65, y: currentY, width: 480, height: 1000)
            let symptomsSize = symptomsText.boundingRect(
                with: symptomsRect.size,
                options: [.usesLineFragmentOrigin],
                attributes: valueAttributes,
                context: nil
            )
            symptomsText.draw(in: symptomsRect, withAttributes: valueAttributes)
            currentY += symptomsSize.height + 8
        }

        currentY += 8

        // Suspected Ingredients section
        if !reaction.suspectedIngredients.isEmpty {
            "SUSPECTED INGREDIENTS".draw(at: CGPoint(x: 65, y: currentY), withAttributes: labelAttributes)
            currentY += 16

            // Show ALL ingredients, no truncation
            let ingredientsText = reaction.suspectedIngredients.joined(separator: ", ")

            let ingredientsRect = CGRect(x: 65, y: currentY, width: 480, height: 1000)
            let ingredientsSize = ingredientsText.boundingRect(
                with: ingredientsRect.size,
                options: [.usesLineFragmentOrigin],
                attributes: valueAttributes,
                context: nil
            )
            ingredientsText.draw(in: ingredientsRect, withAttributes: valueAttributes)
            currentY += ingredientsSize.height + 8
        }

        currentY += 15 // Bottom padding
        currentY += 25 // Space after box
        return currentY
    }

    private static func severityString(for severity: ReactionSeverity) -> String {
        switch severity {
        case .mild: return "Mild"
        case .moderate: return "Moderate"
        case .severe: return "Severe"
        }
    }

    private static func drawAnalysisSummary(in context: UIGraphicsPDFRendererContext, y: CGFloat, analysis: TriggerAnalysis) -> CGFloat {
        var currentY = y

        // Section Header
        let headerAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 16),
            .foregroundColor: UIColor.black
        ]

        "Analysis Summary".draw(at: CGPoint(x: 50, y: currentY), withAttributes: headerAttributes)
        currentY += 25

        // Summary
        let summaryAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor.black
        ]

        let summary = [
            "Time Range: \(analysis.timeRangeStart.formatted(date: .abbreviated, time: .shortened)) to \(analysis.timeRangeEnd.formatted(date: .abbreviated, time: .shortened))",
            "Meals Analyzed: \(analysis.mealCount)",
            "Total Foods Reviewed: \(analysis.totalFoodsAnalyzed)",
            "Possible Trigger Foods Identified: \(analysis.topFoods.count)",
            "Possible Trigger Ingredients Identified: \(analysis.topIngredients.count)"
        ]

        for line in summary {
            line.draw(at: CGPoint(x: 70, y: currentY), withAttributes: summaryAttributes)
            currentY += 18
        }

        currentY += 20
        return currentY
    }

    private static func drawTopFoods(in context: UIGraphicsPDFRendererContext, y: CGFloat, foods: [WeightedFoodScore], pageHeight: CGFloat) -> CGFloat {
        var currentY = y

        // Check if we need a new page
        if currentY > pageHeight - 200 {
            context.beginPage()
            currentY = 50
        }

        // Section Header
        let headerAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 16),
            .foregroundColor: UIColor.black
        ]

        "Top Possible Trigger Foods".draw(at: CGPoint(x: 50, y: currentY), withAttributes: headerAttributes)
        currentY += 25

        // Table Header
        let tableHeaderAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 11),
            .foregroundColor: UIColor.darkGray
        ]

        "Food Name".draw(at: CGPoint(x: 70, y: currentY), withAttributes: tableHeaderAttributes)
        "Occurrences".draw(at: CGPoint(x: 300, y: currentY), withAttributes: tableHeaderAttributes)
        "Pattern %".draw(at: CGPoint(x: 450, y: currentY), withAttributes: tableHeaderAttributes)
        currentY += 20

        // Foods
        let foodAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10),
            .foregroundColor: UIColor.black
        ]

        for food in foods.prefix(10) {
            if currentY > pageHeight - 100 {
                context.beginPage()
                currentY = 50
            }

            food.foodName.draw(at: CGPoint(x: 70, y: currentY), withAttributes: foodAttributes)
            "\(food.occurrences)× (\(food.occurrencesWithin24h)× <24h)".draw(at: CGPoint(x: 300, y: currentY), withAttributes: foodAttributes)

            // Only show pattern percentage if there's cross-reaction data
            let patternText = food.crossReactionFrequency > 0 ? "\(Int(food.crossReactionFrequency))%" : "—"
            patternText.draw(at: CGPoint(x: 450, y: currentY), withAttributes: foodAttributes)
            currentY += 18
        }

        currentY += 20
        return currentY
    }

    private static func drawTopIngredients(in context: UIGraphicsPDFRendererContext, y: CGFloat, ingredients: [WeightedIngredientScore], pageHeight: CGFloat) -> CGFloat {
        var currentY = y

        // Check if we need a new page
        if currentY > pageHeight - 200 {
            context.beginPage()
            currentY = 50
        }

        // Section Header
        let headerAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 16),
            .foregroundColor: UIColor.black
        ]

        "Top Possible Trigger Ingredients".draw(at: CGPoint(x: 50, y: currentY), withAttributes: headerAttributes)
        currentY += 25

        // Table Header
        let tableHeaderAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 11),
            .foregroundColor: UIColor.darkGray
        ]

        "Ingredient".draw(at: CGPoint(x: 70, y: currentY), withAttributes: tableHeaderAttributes)
        "Occurrences".draw(at: CGPoint(x: 300, y: currentY), withAttributes: tableHeaderAttributes)
        "Pattern %".draw(at: CGPoint(x: 450, y: currentY), withAttributes: tableHeaderAttributes)
        currentY += 20

        // Ingredients
        let ingredientAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10),
            .foregroundColor: UIColor.black
        ]

        for ingredient in ingredients.prefix(10) {
            if currentY > pageHeight - 100 {
                context.beginPage()
                currentY = 50
            }

            ingredient.ingredientName.draw(at: CGPoint(x: 70, y: currentY), withAttributes: ingredientAttributes)
            "\(ingredient.occurrences)×".draw(at: CGPoint(x: 300, y: currentY), withAttributes: ingredientAttributes)

            // Only show pattern percentage if there's cross-reaction data
            let patternText = ingredient.crossReactionFrequency > 0 ? "\(Int(ingredient.crossReactionFrequency))%" : "—"
            patternText.draw(at: CGPoint(x: 450, y: currentY), withAttributes: ingredientAttributes)
            currentY += 18
        }

        currentY += 20
        return currentY
    }

    private static func drawMealHistory(in context: UIGraphicsPDFRendererContext, y: CGFloat, meals: [FoodEntry], pageRect: CGRect) -> CGFloat {
        var currentY = y

        // Sort meals by date (newest first for reverse chronological)
        let sortedMeals = meals.sorted { $0.date > $1.date }

        // Group meals by date
        let calendar = Calendar.current
        var mealsByDate: [Date: [FoodEntry]] = [:]

        for meal in sortedMeals {
            let dateOnly = calendar.startOfDay(for: meal.date)
            if mealsByDate[dateOnly] == nil {
                mealsByDate[dateOnly] = []
            }
            mealsByDate[dateOnly]?.append(meal)
        }

        // Sort dates (newest first)
        let sortedDates = mealsByDate.keys.sorted(by: >)

        // Date header attributes
        let dateHeaderAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 13),
            .foregroundColor: UIColor.black
        ]

        // Time and meal attributes
        let timeAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10),
            .foregroundColor: UIColor.darkGray
        ]

        let mealNameAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11),
            .foregroundColor: UIColor.black
        ]

        let ingredientCountAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 9),
            .foregroundColor: UIColor.gray
        ]

        // Draw each date group
        for date in sortedDates {
            guard let mealsForDate = mealsByDate[date] else { continue }

            // Check if we need a new page
            if currentY > pageRect.height - 150 {
                context.beginPage()
                currentY = 50
            }

            // Date Header
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "EEEE, MMM d"  // e.g., "Monday, Jan 15"
            let dateString = dateFormatter.string(from: date)

            dateString.draw(at: CGPoint(x: 50, y: currentY), withAttributes: dateHeaderAttributes)
            currentY += 20

            // Sort meals within the day by time
            let mealsForDay = mealsForDate.sorted { $0.date < $1.date }

            // Draw meals for this date
            for meal in mealsForDay {
                // Check if we need a new page
                if currentY > pageRect.height - 80 {
                    context.beginPage()
                    currentY = 50
                }

                // Time
                let timeFormatter = DateFormatter()
                timeFormatter.dateFormat = "h:mm a"  // e.g., "8:30 AM"
                let timeString = timeFormatter.string(from: meal.date)

                timeString.draw(at: CGPoint(x: 70, y: currentY), withAttributes: timeAttributes)

                // Meal name (aligned to the right of time)
                meal.foodName.draw(at: CGPoint(x: 140, y: currentY), withAttributes: mealNameAttributes)

                // Ingredient count (if available, shown discreetly)
                if let ingredients = meal.ingredients, !ingredients.isEmpty {
                    let ingredientCount = "(\(ingredients.count) ingredient\(ingredients.count == 1 ? "" : "s"))"
                    ingredientCount.draw(at: CGPoint(x: 450, y: currentY), withAttributes: ingredientCountAttributes)
                }

                currentY += 16
            }

            currentY += 10  // Space between dates
        }

        currentY += 5
        return currentY
    }

    private static func drawFooter(in context: UIGraphicsPDFRendererContext, pageRect: CGRect) {
        let footerAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.italicSystemFont(ofSize: 10),
            .foregroundColor: UIColor.gray
        ]

        let disclaimer = "For nutritional review only. Not a medical diagnosis."
        let disclaimerSize = disclaimer.size(withAttributes: footerAttributes)

        let footerY = pageRect.height - 50
        disclaimer.draw(at: CGPoint(x: (pageRect.width - disclaimerSize.width) / 2, y: footerY), withAttributes: footerAttributes)

        let logo = "NutraSafe"
        let logoAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 12),
            .foregroundColor: UIColor.blue
        ]

        logo.draw(at: CGPoint(x: 50, y: footerY), withAttributes: logoAttributes)
    }

    // MARK: - Cross-Reaction Analysis

    private static func analyzeCrossReactions(currentEntry: ReactionLogEntry, mealHistory: [FoodEntry], allReactions: [ReactionLogEntry]) -> [(food: FoodEntry, reactionCount: Int, commonIngredients: [String])] {
        var results: [(food: FoodEntry, reactionCount: Int, commonIngredients: [String])] = []

        // Get food names from current reaction's trigger analysis (for exclusion)
        guard let currentAnalysis = currentEntry.triggerAnalysis else { return results }
        let currentFoodNames = Set(currentAnalysis.topFoods.map { $0.foodName.lowercased() })

        // Filter out reactions that are the same as current
        let otherReactions = allReactions.filter { $0.id != currentEntry.id }

        // For each meal in the 7-day history
        for meal in mealHistory {
            let mealFoodName = meal.foodName.lowercased()

            // Skip if this food is already in the current reaction's trigger analysis
            if currentFoodNames.contains(mealFoodName) {
                continue
            }

            // Check how many OTHER reactions this FOOD NAME appeared in
            var reactionCount = 0
            var allIngredients: Set<String> = []

            for reaction in otherReactions {
                guard let analysis = reaction.triggerAnalysis else { continue }

                // Check if this FOOD NAME appears in the reaction's trigger analysis
                let reactionFoodNames = Set(analysis.topFoods.map { $0.foodName.lowercased() })
                if reactionFoodNames.contains(mealFoodName) {
                    reactionCount += 1

                    // Collect ingredients from this reaction's trigger analysis
                    for ingredient in analysis.topIngredients {
                        allIngredients.insert(ingredient.ingredientName.lowercased())
                    }
                }
            }

            // If this food appeared in at least one other reaction, include it
            if reactionCount > 0 {
                // Get common ingredients between this meal and the reactions it appeared in
                let mealIngredients = Set((meal.ingredients ?? []).map { $0.lowercased() })
                let commonIngredients = Array(mealIngredients.intersection(allIngredients))

                results.append((food: meal, reactionCount: reactionCount, commonIngredients: commonIngredients))
            }
        }

        // Sort by reaction count (descending)
        results.sort { $0.reactionCount > $1.reactionCount }

        return results
    }

    private static func drawCrossReactionAnalysis(in context: UIGraphicsPDFRendererContext, y: CGFloat, crossReactions: [(food: FoodEntry, reactionCount: Int, commonIngredients: [String])], pageRect: CGRect) -> CGFloat {
        var currentY = y

        // Check if we need a new page
        if currentY > pageRect.height - 300 {
            context.beginPage()
            currentY = 50
        }

        // Section Header
        let headerAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 16),
            .foregroundColor: UIColor.black
        ]

        "Related Reaction History".draw(at: CGPoint(x: 50, y: currentY), withAttributes: headerAttributes)
        currentY += 20

        let subHeaderAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10),
            .foregroundColor: UIColor.darkGray
        ]

        "Foods from this 7-day window that also appeared in other reactions".draw(at: CGPoint(x: 50, y: currentY), withAttributes: subHeaderAttributes)
        currentY += 30

        // Food name attributes
        let foodNameAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 13),
            .foregroundColor: UIColor.black
        ]

        let reactionCountAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11),
            .foregroundColor: UIColor.red
        ]

        let ingredientLabelAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 10),
            .foregroundColor: UIColor.darkGray
        ]

        let ingredientAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10),
            .foregroundColor: UIColor.gray
        ]

        // Draw each cross-reacted food
        for crossReaction in crossReactions.prefix(10) {  // Show top 10
            // Check if we need a new page
            if currentY > pageRect.height - 150 {
                context.beginPage()
                currentY = 50
            }

            // Food name
            let foodDisplayName: String
            if let brandName = crossReaction.food.brandName {
                foodDisplayName = "\(crossReaction.food.foodName) (\(brandName))"
            } else {
                foodDisplayName = crossReaction.food.foodName
            }

            foodDisplayName.draw(at: CGPoint(x: 65, y: currentY), withAttributes: foodNameAttributes)
            currentY += 18

            // Reaction count
            let reactionText = "Appeared in \(crossReaction.reactionCount) other reaction\(crossReaction.reactionCount == 1 ? "" : "s")"
            reactionText.draw(at: CGPoint(x: 80, y: currentY), withAttributes: reactionCountAttributes)
            currentY += 15

            // Common ingredients (if any)
            if !crossReaction.commonIngredients.isEmpty {
                "Common suspected ingredients: ".draw(at: CGPoint(x: 80, y: currentY), withAttributes: ingredientLabelAttributes)
                currentY += 13

                let ingredientsText = crossReaction.commonIngredients.prefix(5).joined(separator: ", ")
                let remainingCount = crossReaction.commonIngredients.count - 5

                var displayText = ingredientsText
                if remainingCount > 0 {
                    displayText += ", +\(remainingCount) more"
                }

                let ingredientsRect = CGRect(x: 80, y: currentY, width: 450, height: 1000)
                let ingredientsSize = displayText.boundingRect(
                    with: ingredientsRect.size,
                    options: [.usesLineFragmentOrigin],
                    attributes: ingredientAttributes,
                    context: nil
                )
                displayText.draw(in: ingredientsRect, withAttributes: ingredientAttributes)
                currentY += ingredientsSize.height + 5
            }

            currentY += 15  // Space between foods
        }

        currentY += 20
        return currentY
    }

    // MARK: - Pattern Analysis

    private static func analyzeReactionPatterns(reactions: [ReactionLogEntry]) -> [(symptom: String, count: Int, foods: [String], ingredients: [String])] {
        // Get last 7 reactions
        let recentReactions = Array(reactions.prefix(7))

        // Count symptoms
        var symptomCounts: [String: Int] = [:]
        var symptomFoods: [String: Set<String>] = [:]
        var symptomIngredients: [String: Set<String>] = [:]

        for reaction in recentReactions {
            let symptom = reaction.reactionType
            symptomCounts[symptom, default: 0] += 1

            // Collect foods from analysis
            if let analysis = reaction.triggerAnalysis {
                for food in analysis.topFoods.prefix(5) {
                    symptomFoods[symptom, default: []].insert(food.foodName)
                }

                for ingredient in analysis.topIngredients.prefix(5) {
                    symptomIngredients[symptom, default: []].insert(ingredient.ingredientName)
                }
            }
        }

        // Create pattern data
        var patterns: [(symptom: String, count: Int, foods: [String], ingredients: [String])] = []
        for (symptom, count) in symptomCounts.sorted(by: { $0.value > $1.value }) {
            let foods = Array(symptomFoods[symptom] ?? [])
            let ingredients = Array(symptomIngredients[symptom] ?? [])
            patterns.append((symptom: symptom, count: count, foods: foods, ingredients: ingredients))
        }

        return patterns
    }

    private static func drawPatternAnalysis(in context: UIGraphicsPDFRendererContext, y: CGFloat, patterns: [(symptom: String, count: Int, foods: [String], ingredients: [String])], pageRect: CGRect) -> CGFloat {
        var currentY = y

        // Check if we need a new page
        if currentY > pageRect.height - 200 {
            context.beginPage()
            currentY = 50
        }

        // Section title
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 16),
            .foregroundColor: UIColor.black
        ]
        "PATTERN ANALYSIS (Last 7 Reactions)".draw(at: CGPoint(x: 40, y: currentY), withAttributes: titleAttributes)
        currentY += 30

        let bodyAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10),
            .foregroundColor: UIColor.darkGray
        ]

        let boldAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 11),
            .foregroundColor: UIColor.black
        ]

        for pattern in patterns {
            // Check for page break
            if currentY > pageRect.height - 120 {
                context.beginPage()
                currentY = 50
            }

            // Symptom and count
            let symptomText = "\(pattern.symptom) (\(pattern.count)x)"
            symptomText.draw(at: CGPoint(x: 50, y: currentY), withAttributes: boldAttributes)
            currentY += 15

            // Common foods
            if !pattern.foods.isEmpty {
                "Common foods: \(pattern.foods.prefix(5).joined(separator: ", "))".draw(
                    at: CGPoint(x: 60, y: currentY),
                    withAttributes: bodyAttributes
                )
                currentY += 13
            }

            // Common ingredients
            if !pattern.ingredients.isEmpty {
                "Common ingredients: \(pattern.ingredients.prefix(5).joined(separator: ", "))".draw(
                    at: CGPoint(x: 60, y: currentY),
                    withAttributes: bodyAttributes
                )
                currentY += 13
            }

            currentY += 10
        }

        currentY += 20
        return currentY
    }

    private static func drawRecentReactionsHistory(in context: UIGraphicsPDFRendererContext, y: CGFloat, reactions: [ReactionLogEntry], pageRect: CGRect) -> CGFloat {
        var currentY = y

        // Check if we need a new page
        if currentY > pageRect.height - 200 {
            context.beginPage()
            currentY = 50
        }

        // Section title
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 16),
            .foregroundColor: UIColor.black
        ]
        "RECENT REACTIONS HISTORY (Last 7)".draw(at: CGPoint(x: 40, y: currentY), withAttributes: titleAttributes)
        currentY += 30

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short

        let boldAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 11),
            .foregroundColor: UIColor.black
        ]

        let bodyAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10),
            .foregroundColor: UIColor.darkGray
        ]

        for (index, reaction) in reactions.enumerated() {
            // Check for page break
            if currentY > pageRect.height - 100 {
                context.beginPage()
                currentY = 50
            }

            // Reaction number and type
            let reactionHeader = "\(index + 1). \(reaction.reactionType) - \(dateFormatter.string(from: reaction.reactionDate))"
            reactionHeader.draw(at: CGPoint(x: 50, y: currentY), withAttributes: boldAttributes)
            currentY += 15

            // Top foods (if available)
            if let analysis = reaction.triggerAnalysis, !analysis.topFoods.isEmpty {
                let topFoods = analysis.topFoods.prefix(3).map { $0.foodName }.joined(separator: ", ")
                "Top foods: \(topFoods)".draw(at: CGPoint(x: 60, y: currentY), withAttributes: bodyAttributes)
                currentY += 13
            }

            // Top ingredients (if available)
            if let analysis = reaction.triggerAnalysis, !analysis.topIngredients.isEmpty {
                let topIngredients = analysis.topIngredients.prefix(3).map { $0.ingredientName }.joined(separator: ", ")
                "Top ingredients: \(topIngredients)".draw(at: CGPoint(x: 60, y: currentY), withAttributes: bodyAttributes)
                currentY += 13
            }

            // Notes (if available)
            if let notes = reaction.notes, !notes.isEmpty {
                "Notes: \(notes)".draw(at: CGPoint(x: 60, y: currentY), withAttributes: bodyAttributes)
                currentY += 13
            }

            currentY += 10
        }

        currentY += 20
        return currentY
    }

    // MARK: - New Helper Functions for Multi-Reaction Report

    private static func drawSectionHeader(in context: UIGraphicsPDFRendererContext, y: CGFloat, title: String, pageRect: CGRect) -> CGFloat {
        var currentY = y

        // Check if we need a new page
        if currentY > pageRect.height - 150 {
            context.beginPage()
            currentY = 50
        }

        // Add some spacing before the section
        currentY += 20

        // Section Header with underline
        let headerAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 18),
            .foregroundColor: UIColor.black
        ]

        title.draw(at: CGPoint(x: 40, y: currentY), withAttributes: headerAttributes)
        currentY += 25

        // Draw underline
        context.cgContext.setStrokeColor(UIColor.blue.cgColor)
        context.cgContext.setLineWidth(2.0)
        context.cgContext.move(to: CGPoint(x: 40, y: currentY))
        context.cgContext.addLine(to: CGPoint(x: pageRect.width - 40, y: currentY))
        context.cgContext.strokePath()

        currentY += 15
        return currentY
    }

    private static func drawPreviousReactionsSummary(in context: UIGraphicsPDFRendererContext, y: CGFloat, reactions: [ReactionLogEntry], pageRect: CGRect) -> CGFloat {
        var currentY = y

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short

        let boldAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 13),
            .foregroundColor: UIColor.black
        ]

        let bodyAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11),
            .foregroundColor: UIColor.darkGray
        ]

        for (index, reaction) in reactions.enumerated() {
            // Check for page break
            if currentY > pageRect.height - 120 {
                context.beginPage()
                currentY = 50
            }

            // Reaction number and type
            let reactionHeader = "\(index + 2). \(reaction.reactionType) - \(dateFormatter.string(from: reaction.reactionDate))"
            reactionHeader.draw(at: CGPoint(x: 50, y: currentY), withAttributes: boldAttributes)
            currentY += 18

            // Top foods (if available)
            if let analysis = reaction.triggerAnalysis, !analysis.topFoods.isEmpty {
                let topFoods = analysis.topFoods.prefix(3).map { $0.foodName }.joined(separator: ", ")
                "Top foods: \(topFoods)".draw(at: CGPoint(x: 60, y: currentY), withAttributes: bodyAttributes)
                currentY += 15
            }

            // Top ingredients (if available)
            if let analysis = reaction.triggerAnalysis, !analysis.topIngredients.isEmpty {
                let topIngredients = analysis.topIngredients.prefix(3).map { $0.ingredientName }.joined(separator: ", ")
                "Top ingredients: \(topIngredients)".draw(at: CGPoint(x: 60, y: currentY), withAttributes: bodyAttributes)
                currentY += 15
            }

            // Notes (if available)
            if let notes = reaction.notes, !notes.isEmpty {
                let notesText = "Notes: \(notes)"
                let notesRect = CGRect(x: 60, y: currentY, width: 480, height: 1000)
                let notesSize = notesText.boundingRect(
                    with: notesRect.size,
                    options: [.usesLineFragmentOrigin],
                    attributes: bodyAttributes,
                    context: nil
                )
                notesText.draw(in: notesRect, withAttributes: bodyAttributes)
                currentY += notesSize.height + 5
            }

            currentY += 15
        }

        currentY += 10
        return currentY
    }

    private static func drawAllergenPatternAnalysis(in context: UIGraphicsPDFRendererContext, y: CGFloat, reactions: [ReactionLogEntry], pageRect: CGRect) -> CGFloat {
        var currentY = y

        // Collect all ingredients from all reactions and categorize
        var allergenData: [String: (count: Int, reactionsAppeared: Set<String>, ingredients: Set<String>)] = [:]

        for reaction in reactions.prefix(7) {
            guard let analysis = reaction.triggerAnalysis else { continue }

            for ingredient in analysis.topIngredients {
                if let allergenCategory = getBaseAllergen(for: ingredient.ingredientName) {
                    if allergenData[allergenCategory] == nil {
                        allergenData[allergenCategory] = (0, [], [])
                    }

                    // Safe dictionary mutation
                    if var data = allergenData[allergenCategory] {
                        data.count += 1
                        data.reactionsAppeared.insert(reaction.id ?? "")
                        data.ingredients.insert(ingredient.ingredientName)
                        allergenData[allergenCategory] = data
                    }
                }
            }
        }

        // Sort by count (descending)
        let sortedAllergens = allergenData.sorted { $0.value.count > $1.value.count }

        if sortedAllergens.isEmpty {
            let noDataAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.italicSystemFont(ofSize: 12),
                .foregroundColor: UIColor.gray
            ]
            "No recognized allergens found in the analyzed reactions.".draw(at: CGPoint(x: 50, y: currentY), withAttributes: noDataAttributes)
            currentY += 30
            return currentY
        }

        let boldAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 13),
            .foregroundColor: UIColor.black
        ]

        let bodyAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11),
            .foregroundColor: UIColor.darkGray
        ]

        for (category, data) in sortedAllergens {
            // Check for page break
            if currentY > pageRect.height - 120 {
                context.beginPage()
                currentY = 50
            }

            // Category name with count
            let categoryText = "\(category) (appeared in \(data.reactionsAppeared.count) reaction\(data.reactionsAppeared.count == 1 ? "" : "s"))"
            categoryText.draw(at: CGPoint(x: 50, y: currentY), withAttributes: boldAttributes)
            currentY += 18

            // List specific ingredients
            let ingredientsList = Array(data.ingredients).prefix(5).joined(separator: ", ")
            let ingredientsText = "Specific ingredients: \(ingredientsList)"
            let ingredientsRect = CGRect(x: 60, y: currentY, width: 480, height: 1000)
            let ingredientsSize = ingredientsText.boundingRect(
                with: ingredientsRect.size,
                options: [.usesLineFragmentOrigin],
                attributes: bodyAttributes,
                context: nil
            )
            ingredientsText.draw(in: ingredientsRect, withAttributes: bodyAttributes)
            currentY += ingredientsSize.height + 5

            currentY += 15
        }

        currentY += 10
        return currentY
    }

    private static func drawOtherIngredientPatternAnalysis(in context: UIGraphicsPDFRendererContext, y: CGFloat, reactions: [ReactionLogEntry], pageRect: CGRect) -> CGFloat {
        var currentY = y

        // Collect all non-allergen ingredients from all reactions
        var ingredientData: [String: (count: Int, reactionsAppeared: Set<String>)] = [:]

        for reaction in reactions.prefix(7) {
            guard let analysis = reaction.triggerAnalysis else { continue }

            for ingredient in analysis.topIngredients {
                // Skip if it's a recognized allergen
                if getBaseAllergen(for: ingredient.ingredientName) != nil {
                    continue
                }

                let normalizedName = ingredient.ingredientName.lowercased()
                if ingredientData[normalizedName] == nil {
                    ingredientData[normalizedName] = (0, [])
                }

                // Safe dictionary mutation
                if var data = ingredientData[normalizedName] {
                    data.count += 1
                    data.reactionsAppeared.insert(reaction.id ?? "")
                    ingredientData[normalizedName] = data
                }
            }
        }

        // Filter to ingredients appearing in 2+ reactions
        let significantIngredients = ingredientData.filter { $0.value.reactionsAppeared.count >= 2 }

        // Sort by reaction count (descending)
        let sortedIngredients = significantIngredients.sorted { $0.value.count > $1.value.count }

        if sortedIngredients.isEmpty {
            let noDataAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.italicSystemFont(ofSize: 12),
                .foregroundColor: UIColor.gray
            ]
            "No significant ingredient patterns found (must appear in 2+ reactions).".draw(at: CGPoint(x: 50, y: currentY), withAttributes: noDataAttributes)
            currentY += 30
            return currentY
        }

        let ingredientAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor.black
        ]

        let countAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 11),
            .foregroundColor: UIColor.blue
        ]

        for (ingredientName, data) in sortedIngredients.prefix(15) {
            // Check for page break
            if currentY > pageRect.height - 80 {
                context.beginPage()
                currentY = 50
            }

            // Ingredient name
            ingredientName.capitalized.draw(at: CGPoint(x: 50, y: currentY), withAttributes: ingredientAttributes)

            // Count (aligned to the right)
            let countText = "× \(data.reactionsAppeared.count) reaction\(data.reactionsAppeared.count == 1 ? "" : "s")"
            countText.draw(at: CGPoint(x: 450, y: currentY), withAttributes: countAttributes)

            currentY += 18
        }

        currentY += 10
        return currentY
    }

    private static func getBaseAllergen(for ingredient: String) -> String? {
        let lower = ingredient.lowercased()

        // Milk and dairy (uses comprehensive cheese/dairy detection)
        if AllergenDetector.shared.containsDairyMilk(in: lower) {
            return "Milk & Dairy"
        }

        // Eggs (comprehensive)
        let eggKeywords = ["egg", "albumin", "mayonnaise", "meringue", "ovalbumin", "lecithin", "lysozyme",
                           "quiche", "frittata", "omelette", "omelet", "brioche", "challah", "hollandaise",
                           "béarnaise", "bearnaise", "aioli", "carbonara", "pavlova", "soufflé", "souffle",
                           "custard", "eggnog", "scotch egg"]
        if eggKeywords.contains(where: { lower.contains($0) }) {
            return "Eggs"
        }

        // Peanuts
        let peanutKeywords = ["peanut", "groundnut", "arachis", "peanut butter", "peanut oil", "satay", "monkey nuts"]
        if peanutKeywords.contains(where: { lower.contains($0) }) {
            return "Peanuts"
        }

        // Tree nuts (comprehensive)
        let treeNutKeywords = ["almond", "hazelnut", "walnut", "cashew", "pistachio", "pecan", "filbert",
                               "brazil nut", "macadamia", "pine nut", "chestnut", "praline", "gianduja",
                               "marzipan", "frangipane", "nougat", "nutella", "nut butter", "almond flour",
                               "ground almonds", "flaked almonds", "walnut oil", "hazelnut oil"]
        if treeNutKeywords.contains(where: { lower.contains($0) }) {
            return "Tree Nuts"
        }

        // Gluten (comprehensive)
        let glutenKeywords = ["wheat", "gluten", "barley", "rye", "oats", "spelt", "kamut", "einkorn",
                              "triticale", "durum", "farro", "freekeh", "seitan", "malt", "brewer's yeast",
                              "semolina", "bulgur", "couscous", "flour", "bread", "pasta", "beer", "lager", "ale", "stout"]
        if glutenKeywords.contains(where: { lower.contains($0) }) {
            return "Gluten & Grains"
        }

        // Soya (comprehensive)
        let soyKeywords = ["soy", "soya", "soybean", "tofu", "tempeh", "miso", "shoyu", "tamari",
                           "edamame", "soy sauce", "soy milk", "soy protein", "soy lecithin", "natto", "tvp"]
        if soyKeywords.contains(where: { lower.contains($0) }) {
            return "Soya"
        }

        // Fish (comprehensive)
        let fishKeywords = ["fish", "fish sauce", "worcestershire", "fish finger", "fish cake", "fish pie",
                            "salmon", "tuna", "cod", "bass", "trout", "anchovy", "sardine", "mackerel",
                            "haddock", "plaice", "pollock", "hake", "monkfish", "halibut", "tilapia",
                            "bream", "sole", "herring", "kipper", "whitebait", "pilchard", "sprat",
                            "swordfish", "snapper", "grouper", "perch", "catfish", "carp", "pike", "eel"]
        if fishKeywords.contains(where: { lower.contains($0) }) {
            return "Fish"
        }

        // Shellfish (crustaceans and molluscs combined)
        let shellfishKeywords = ["shellfish", "shrimp", "prawn", "crab", "lobster", "crawfish", "crayfish", "langoustine",
                                 "king prawn", "tiger prawn", "crab stick", "mollusc", "clam", "mussel", "oyster",
                                 "scallop", "cockle", "winkle", "whelk", "squid", "calamari", "octopus",
                                 "cuttlefish", "abalone", "snail", "escargot"]
        if shellfishKeywords.contains(where: { lower.contains($0) }) {
            return "Shellfish"
        }

        // Sesame (comprehensive)
        let sesameKeywords = ["sesame", "tahini", "sesame oil", "sesame seed", "hummus", "houmous",
                              "halvah", "halva", "za'atar", "zaatar", "gomashio", "benne seed"]
        if sesameKeywords.contains(where: { lower.contains($0) }) {
            return "Sesame"
        }

        // Celery
        let celeryKeywords = ["celery", "celeriac", "celery salt", "celery extract"]
        if celeryKeywords.contains(where: { lower.contains($0) }) {
            return "Celery"
        }

        // Mustard
        let mustardKeywords = ["mustard", "mustard seed", "dijon", "wholegrain mustard"]
        if mustardKeywords.contains(where: { lower.contains($0) }) {
            return "Mustard"
        }

        // Lupin
        let lupinKeywords = ["lupin", "lupine", "lupin flour"]
        if lupinKeywords.contains(where: { lower.contains($0) }) {
            return "Lupin"
        }

        // Sulphites (comprehensive)
        let sulphiteKeywords = ["sulphite", "sulfite", "sulphur dioxide", "sulfur dioxide",
                                "e220", "e221", "e222", "e223", "e224", "e225", "e226", "e227", "e228",
                                "metabisulphite", "metabisulfite"]
        if sulphiteKeywords.contains(where: { lower.contains($0) }) {
            return "Sulphites"
        }

        return nil
    }

    // MARK: - Multiple Food Reactions Details Drawing

    private static func drawMultipleFoodReactionsDetails(in context: UIGraphicsPDFRendererContext, y: CGFloat, reactions: [FoodReaction], pageRect: CGRect) -> CGFloat {
        var currentY = y

        // Section Header
        let headerAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 18),
            .foregroundColor: UIColor.black
        ]

        "Food Reactions".draw(at: CGPoint(x: 50, y: currentY), withAttributes: headerAttributes)
        currentY += 30

        // Draw each reaction
        for (index, reaction) in reactions.enumerated() {
            // Check if we need a new page
            if currentY > pageRect.height - 200 {
                context.beginPage()
                currentY = 50
            }

            // Reaction number
            let numberAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 14),
                .foregroundColor: UIColor.darkGray
            ]
            "Reaction \(index + 1) of \(reactions.count)".draw(at: CGPoint(x: 50, y: currentY), withAttributes: numberAttributes)
            currentY += 20

            // Draw reaction details
            currentY = drawFoodReactionDetails(in: context, y: currentY, reaction: reaction)
            currentY += 20 // Space between reactions
        }

        return currentY
    }

    // MARK: - New Helper Methods for Comprehensive Food Reactions Export

    private static func drawPastFoodReactions(in context: UIGraphicsPDFRendererContext, y: CGFloat, reactions: [FoodReaction], pageRect: CGRect) -> CGFloat {
        var currentY = y

        let numberAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11, weight: .medium),
            .foregroundColor: UIColor.darkGray
        ]

        let foodNameAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 13, weight: .semibold),
            .foregroundColor: UIColor.black
        ]

        let dateAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11),
            .foregroundColor: UIColor.gray
        ]

        let symptomsAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10),
            .foregroundColor: UIColor.darkGray
        ]

        // Draw each past reaction in compact form
        for (index, reaction) in reactions.enumerated() {
            // Check if we need a new page
            if currentY > pageRect.height - 100 {
                context.beginPage()
                currentY = 50
            }

            // Reaction number
            "#\(index + 2)".draw(at: CGPoint(x: 60, y: currentY), withAttributes: numberAttributes)
            currentY += 16

            // Food name
            reaction.foodName.draw(at: CGPoint(x: 70, y: currentY), withAttributes: foodNameAttributes)
            currentY += 16

            // Date
            let date = reaction.timestamp.dateValue()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM d, yyyy"
            dateFormatter.string(from: date).draw(at: CGPoint(x: 70, y: currentY), withAttributes: dateAttributes)
            currentY += 14

            // Symptoms (if any)
            if !reaction.symptoms.isEmpty {
                let symptomsText = reaction.symptoms.joined(separator: ", ")
                symptomsText.draw(at: CGPoint(x: 70, y: currentY), withAttributes: symptomsAttributes)
                currentY += 14
            }

            currentY += 15 // Space between reactions
        }

        return currentY
    }

    private static func drawFoodReactionPatternAnalysis(in context: UIGraphicsPDFRendererContext, y: CGFloat, reactions: [FoodReaction], pageRect: CGRect) -> CGFloat {
        var currentY = y

        // Require at least 3 reactions before showing patterns
        guard reactions.count >= 3 else { return currentY }

        // Count ingredient frequencies from suspected ingredients
        var ingredientCounts: [String: Int] = [:]
        for reaction in reactions {
            for ingredient in reaction.suspectedIngredients {
                let normalized = ingredient.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                ingredientCounts[normalized, default: 0] += 1
            }
        }

        // Calculate percentages and determine if allergen
        let totalReactions = reactions.count
        var allTriggers: [(ingredient: String, count: Int, percentage: Int, isAllergen: Bool, baseAllergen: String?)] = []

        for (ingredient, count) in ingredientCounts {
            let percentage = Int((Double(count) / Double(totalReactions)) * 100)
            let baseAllergen = getBaseAllergen(for: ingredient)
            let isAllergen = baseAllergen != nil
            allTriggers.append((ingredient.capitalized, count, percentage, isAllergen, baseAllergen))
        }

        // Sort by frequency (descending)
        allTriggers.sort { $0.count > $1.count }

        // Separate allergens and non-allergens
        let allergenTriggers = allTriggers.filter { $0.isAllergen }
        let otherTriggers = allTriggers.filter { !$0.isAllergen }

        // Group allergens by base category
        var groupedAllergens: [String: [(ingredient: String, count: Int, percentage: Int)]] = [:]

        for trigger in allergenTriggers {
            guard let category = trigger.baseAllergen else { continue }

            let ingredient = (
                ingredient: trigger.ingredient,
                count: trigger.count,
                percentage: trigger.percentage
            )

            if groupedAllergens[category] != nil {
                groupedAllergens[category]?.append(ingredient)
            } else {
                groupedAllergens[category] = [ingredient]
            }
        }

        // Calculate category percentages (max percentage in category)
        var groupedArray: [(category: String, percentage: Int, ingredients: [(ingredient: String, count: Int, percentage: Int)])] = []
        for (category, ingredients) in groupedAllergens {
            let maxPercentage = ingredients.map { $0.percentage }.max() ?? 0
            groupedArray.append((category: category, percentage: maxPercentage, ingredients: ingredients))
        }

        // Sort by percentage descending
        groupedArray.sort { $0.percentage > $1.percentage }

        // DRAW RECOGNISED ALLERGENS SECTION
        if !groupedArray.isEmpty {
            // Subsection header
            let subHeaderAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 14),
                .foregroundColor: UIColor.black
            ]
            "Recognised Allergens".draw(at: CGPoint(x: 60, y: currentY), withAttributes: subHeaderAttributes)
            currentY += 25

            let categoryAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 13, weight: .semibold),
                .foregroundColor: UIColor.systemRed
            ]

            let ingredientAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11),
                .foregroundColor: UIColor.darkGray
            ]

            for group in groupedArray {
                // Check for page break
                if currentY > pageRect.height - 100 {
                    context.beginPage()
                    currentY = 50
                }

                // Category with percentage
                "\(group.category) \(group.percentage)%".draw(at: CGPoint(x: 70, y: currentY), withAttributes: categoryAttributes)
                currentY += 16

                // Individual ingredients in this category
                for ingredient in group.ingredients {
                    if currentY > pageRect.height - 60 {
                        context.beginPage()
                        currentY = 50
                    }

                    "  • \(ingredient.ingredient) \(ingredient.percentage)%".draw(at: CGPoint(x: 80, y: currentY), withAttributes: ingredientAttributes)
                    currentY += 14
                }

                currentY += 8 // Space between categories
            }

            currentY += 15
        }

        // DRAW OTHER INGREDIENTS SECTION
        if !otherTriggers.isEmpty {
            // Check for page break
            if currentY > pageRect.height - 150 {
                context.beginPage()
                currentY = 50
            }

            // Subsection header
            let subHeaderAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 14),
                .foregroundColor: UIColor.black
            ]
            "Other Ingredients".draw(at: CGPoint(x: 60, y: currentY), withAttributes: subHeaderAttributes)
            currentY += 25

            let ingredientAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11),
                .foregroundColor: UIColor.darkGray
            ]

            for trigger in otherTriggers.prefix(15) {
                if currentY > pageRect.height - 60 {
                    context.beginPage()
                    currentY = 50
                }

                "\(trigger.ingredient) \(trigger.percentage)%".draw(at: CGPoint(x: 70, y: currentY), withAttributes: ingredientAttributes)
                currentY += 14
            }
        }

        currentY += 20
        return currentY
    }
}
