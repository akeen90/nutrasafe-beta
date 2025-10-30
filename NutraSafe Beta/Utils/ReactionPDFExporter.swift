//
//  ReactionPDFExporter.swift
//  NutraSafe Beta
//
//  PDF export for reaction logs - for nutritionist review
//

import Foundation
import PDFKit
import UIKit

class ReactionPDFExporter {

    static func exportReactionReport(entry: ReactionLogEntry, userName: String = "User") -> URL? {
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
