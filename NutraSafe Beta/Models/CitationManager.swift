//
//  CitationManager.swift
//  NutraSafe Beta
//
//  Created by Claude on 2025-01-30.
//  Official data sources and citations for nutrition information
//

import Foundation
import SwiftUI

/// Manages all official data sources and citations used in the app
class CitationManager {
    static let shared = CitationManager()

    private init() {}

    // MARK: - Citation Models

    struct Citation: Identifiable {
        let id = UUID()
        let title: String
        let organization: String
        let url: String
        let description: String
        let category: CitationCategory
    }

    enum CitationCategory: String, CaseIterable {
        case dailyValues = "Daily Values & RDAs"
        case nutritionData = "Nutrition Data"
        case additives = "Food Additives"
        case allergens = "Allergen Information"
        case foodProcessing = "Food Processing & Classification"
        case scientificStudies = "Scientific Studies"
        case sugarSalt = "Sugar & Salt Guidelines"
        case general = "General Guidelines"

        var icon: String {
            switch self {
            case .dailyValues: return "chart.bar.fill"
            case .nutritionData: return "list.bullet.clipboard"
            case .additives: return "exclamationmark.triangle.fill"
            case .allergens: return "allergens"
            case .foodProcessing: return "leaf.fill"
            case .scientificStudies: return "doc.text.magnifyingglass"
            case .sugarSalt: return "cube.fill"
            case .general: return "info.circle.fill"
            }
        }
    }

    // MARK: - Official Sources

    /// All citations used in the app
    var allCitations: [Citation] {
        return [
            // MARK: - UK Daily Values & Reference Intakes (PRIMARY)
            Citation(
                title: "Nutrient Requirements (RNI)",
                organization: "UK National Health Service (NHS)",
                url: "https://www.nhs.uk/live-well/eat-well/food-guidelines-and-food-labels/reference-intakes-on-food-labels/",
                description: "UK Reference Nutrient Intake (RNI) values used for calculating daily nutrient percentages throughout this app.",
                category: .dailyValues
            ),

            Citation(
                title: "Dietary Reference Values for Food Energy and Nutrients for the United Kingdom",
                organization: "UK Scientific Advisory Committee on Nutrition (SACN)",
                url: "https://www.gov.uk/government/organisations/scientific-advisory-committee-on-nutrition",
                description: "Official UK government dietary reference values (DRVs) for vitamins, minerals, and nutrients.",
                category: .dailyValues
            ),

            Citation(
                title: "Daily Value on Nutrition and Supplement Facts Labels",
                organization: "U.S. Food & Drug Administration (FDA)",
                url: "https://www.fda.gov/food/nutrition-facts-label/daily-value-nutrition-and-supplement-facts-labels",
                description: "FDA reference for recommended daily values of nutrients, vitamins, and minerals.",
                category: .dailyValues
            ),

            Citation(
                title: "Dietary Reference Intakes (DRIs)",
                organization: "National Institutes of Health (NIH)",
                url: "https://ods.od.nih.gov/HealthInformation/nutrientrecommendations.aspx",
                description: "Reference intakes for vitamins and minerals based on age, sex, and life stage.",
                category: .dailyValues
            ),

            // MARK: - Nutrition Database
            Citation(
                title: "FoodData Central",
                organization: "U.S. Department of Agriculture (USDA)",
                url: "https://fdc.nal.usda.gov/",
                description: "Primary source for comprehensive nutrition data including micronutrients, macronutrients, and serving sizes.",
                category: .nutritionData
            ),

            Citation(
                title: "Composition of Foods Integrated Dataset (CoFID)",
                organization: "UK Public Health England",
                url: "https://www.gov.uk/government/publications/composition-of-foods-integrated-dataset-cofid",
                description: "UK national food composition database with detailed nutritional information for foods consumed in the UK.",
                category: .nutritionData
            ),

            // MARK: - Food Processing & Classification
            Citation(
                title: "NOVA Food Classification System",
                organization: "University of São Paulo / World Public Health Nutrition Association",
                url: "https://www.fao.org/nutrition/education/food-dietary-guidelines/background/faowhoconference/nova-classification/en/",
                description: "International food classification system based on the extent and purpose of food processing. Used for food scoring and processing level analysis.",
                category: .foodProcessing
            ),

            Citation(
                title: "Food Processing and Health",
                organization: "UK Food Standards Agency (FSA)",
                url: "https://www.food.gov.uk/",
                description: "UK government food safety authority providing guidance on food processing, labeling, and nutrition standards.",
                category: .foodProcessing
            ),

            // MARK: - Sugar & Salt Guidelines
            Citation(
                title: "Guideline: Sugars intake for adults and children",
                organization: "World Health Organization (WHO)",
                url: "https://www.who.int/publications/i/item/9789241549028",
                description: "WHO recommends reducing free sugars to less than 10% of total energy intake. Used for sugar content analysis and recommendations.",
                category: .sugarSalt
            ),

            Citation(
                title: "Salt reduction targets and reformulation",
                organization: "UK Food Standards Agency (FSA)",
                url: "https://www.food.gov.uk/business-guidance/salt-reduction-targets",
                description: "UK government targets for salt reduction in food products.",
                category: .sugarSalt
            ),

            Citation(
                title: "Tips to reduce sugar in your diet",
                organization: "UK National Health Service (NHS)",
                url: "https://www.nhs.uk/live-well/eat-well/food-types/how-does-sugar-in-our-diet-affect-our-health/",
                description: "NHS guidance on sugar consumption and health impact.",
                category: .sugarSalt
            ),

            // MARK: - Food Additives (CRITICAL for child hyperactivity claims)
            Citation(
                title: "Food colours and hyperactivity in children",
                organization: "UK Food Standards Agency (FSA)",
                url: "https://www.food.gov.uk/safety-hygiene/food-colours-and-hyperactivity",
                description: "FSA review of evidence linking certain food colours to hyperactivity in children, based on the Southampton Study (2007).",
                category: .additives
            ),

            Citation(
                title: "Food additives and behaviour in 3-year-old and 8/9-year-old children (Southampton Study)",
                organization: "The Lancet / University of Southampton",
                url: "https://www.thelancet.com/journals/lancet/article/PIIS0140-6736(07)61306-3/fulltext",
                description: "Peer-reviewed study finding a link between artificial food colours/preservatives and increased hyperactivity in children. McCann et al., 2007.",
                category: .scientificStudies
            ),

            Citation(
                title: "Food Additives",
                organization: "European Food Safety Authority (EFSA)",
                url: "https://www.efsa.europa.eu/en/topics/topic/food-additives",
                description: "European standards for food additive safety and E-numbers. EFSA provides scientific advice and risk assessments on food additives.",
                category: .additives
            ),

            Citation(
                title: "Approved additives and E numbers",
                organization: "UK Food Standards Agency (FSA)",
                url: "https://www.food.gov.uk/business-guidance/approved-additives-and-e-numbers",
                description: "Complete list of approved food additives in the UK with E-numbers and safety information.",
                category: .additives
            ),

            Citation(
                title: "Food Additive Status List",
                organization: "U.S. Food & Drug Administration (FDA)",
                url: "https://www.fda.gov/food/food-additives-petitions/food-additive-status-list",
                description: "Official FDA database of approved food additives and their safety status.",
                category: .additives
            ),

            // MARK: - Allergen Information
            Citation(
                title: "Food allergen labelling and information requirements",
                organization: "UK Food Standards Agency (FSA)",
                url: "https://www.food.gov.uk/business-guidance/allergen-guidance-for-food-businesses",
                description: "UK legal requirements for food allergen labeling under UK and EU regulations.",
                category: .allergens
            ),

            Citation(
                title: "Food Allergy and Intolerance",
                organization: "UK National Health Service (NHS)",
                url: "https://www.nhs.uk/conditions/food-allergy/",
                description: "NHS guidance on food allergies and allergen management.",
                category: .allergens
            ),

            Citation(
                title: "Food allergen labelling (EU Regulation 1169/2011)",
                organization: "European Commission",
                url: "https://food.ec.europa.eu/safety/labelling-and-nutrition/food-information-consumers-legislation_en",
                description: "EU regulation on food information to consumers, including mandatory allergen declaration requirements.",
                category: .allergens
            ),

            Citation(
                title: "Food Allergies",
                organization: "U.S. Food & Drug Administration (FDA)",
                url: "https://www.fda.gov/food/food-labeling-nutrition/food-allergies",
                description: "Official FDA guidance on major food allergens and labeling requirements.",
                category: .allergens
            ),

            // MARK: - General UK Health Guidelines
            Citation(
                title: "The Eatwell Guide",
                organization: "UK National Health Service (NHS)",
                url: "https://www.nhs.uk/live-well/eat-well/food-guidelines-and-food-labels/the-eatwell-guide/",
                description: "UK government guidance on healthy eating and balanced nutrition. Official dietary guidelines for the UK population.",
                category: .general
            ),

            Citation(
                title: "Nutrition guidelines and resources",
                organization: "British Dietetic Association (BDA)",
                url: "https://www.bda.uk.com/resource/food-facts.html",
                description: "Professional nutrition guidance from the UK's professional association for dietitians.",
                category: .general
            ),

            Citation(
                title: "Intermittent fasting (fasting diets)",
                organization: "UK National Health Service (NHS)",
                url: "https://www.nhs.uk/live-well/healthy-weight/managing-your-weight/ten-tips-to-support-weight-loss/intermittent-fasting/",
                description: "NHS information on intermittent fasting, including safety guidance and medical considerations.",
                category: .general
            )
        ]
    }

    /// Get citations by category
    func citations(for category: CitationCategory) -> [Citation] {
        return allCitations.filter { $0.category == category }
    }

    /// Get primary citation for daily values
    var primaryDailyValuesCitation: Citation {
        return allCitations.first { $0.category == .dailyValues && $0.organization.contains("FDA") }!
    }

    /// Get primary citation for nutrition data
    var primaryNutritionDataCitation: Citation {
        return allCitations.first { $0.category == .nutritionData }!
    }

    // MARK: - Quick Access URLs

    static let fdaDailyValuesURL = "https://www.fda.gov/food/nutrition-facts-label/daily-value-nutrition-and-supplement-facts-labels"
    static let usdaFoodDataURL = "https://fdc.nal.usda.gov/"
    static let nhsEatwellGuideURL = "https://www.nhs.uk/live-well/eat-well/food-guidelines-and-food-labels/the-eatwell-guide/"
    static let fdaAdditivesURL = "https://www.fda.gov/food/food-additives-petitions/food-additive-status-list"
    static let fdaAllergensURL = "https://www.fda.gov/food/food-labeling-nutrition/food-allergies"

    // MARK: - Helper Methods

    /// Open a citation URL in Safari
    func openCitation(_ citation: Citation) {
        if let url = URL(string: citation.url) {
            #if os(iOS)
            UIApplication.shared.open(url)
            #endif
        }
    }

    /// Get formatted citation text for display
    func formattedCitation(_ citation: Citation) -> String {
        return "\(citation.organization). \(citation.title). Available at: \(citation.url)"
    }

    /// Get attribution text for a specific data type
    func attributionText(for dataType: CitationCategory) -> String {
        switch dataType {
        case .dailyValues:
            return "Daily values based on NHS RNI and FDA guidelines"
        case .nutritionData:
            return "Nutrition data from USDA FoodData Central and UK CoFID"
        case .additives:
            return "Additive information from FSA, EFSA, and scientific studies"
        case .allergens:
            return "Allergen data based on UK FSA and EU regulations"
        case .foodProcessing:
            return "Food processing classification based on NOVA system"
        case .scientificStudies:
            return "Based on peer-reviewed scientific research"
        case .sugarSalt:
            return "Guidelines based on WHO and UK FSA recommendations"
        case .general:
            return "Guidelines based on NHS and UK government recommendations"
        }
    }
}
