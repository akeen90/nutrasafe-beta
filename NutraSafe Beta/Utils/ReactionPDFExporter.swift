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

    static func exportReactionReport(entry: ReactionLogEntry, userName: String = "User", mealHistory: [FoodEntry] = []) -> URL? {
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
            print("Error saving PDF: \(error)")
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
            print("Error saving PDF: \(error)")
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

        let exportDate = "Export Date: \(Date().formatted(date: .long, time: .shortened))"
        let userText = "User: \(userName)"

        userText.draw(at: CGPoint(x: 50, y: currentY), withAttributes: attributes)
        currentY += 20

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
            let displayIngredients = Array(reaction.suspectedIngredients.prefix(10))
            let remainingCount = reaction.suspectedIngredients.count - displayIngredients.count
            var ingredientsText = displayIngredients.joined(separator: ", ")
            if remainingCount > 0 {
                ingredientsText += ", +\(remainingCount) more"
            }
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

            // Show first 10 ingredients, then "+ X more"
            let displayIngredients = Array(reaction.suspectedIngredients.prefix(10))
            let remainingCount = reaction.suspectedIngredients.count - displayIngredients.count

            var ingredientsText = displayIngredients.joined(separator: ", ")
            if remainingCount > 0 {
                ingredientsText += ", +\(remainingCount) more"
            }

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

        "7-Day Meal History".draw(at: CGPoint(x: 50, y: currentY), withAttributes: headerAttributes)
        currentY += 20

        let subHeaderAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10),
            .foregroundColor: UIColor.darkGray
        ]

        "Foods consumed in the 7 days prior to reaction".draw(at: CGPoint(x: 50, y: currentY), withAttributes: subHeaderAttributes)
        currentY += 25

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
}
