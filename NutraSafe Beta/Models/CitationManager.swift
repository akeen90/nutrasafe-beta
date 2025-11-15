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
        case fasting = "Intermittent Fasting"
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
            case .fasting: return "info.circle.fill"
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
                title: "The Eatwell Guide - Nutrient Requirements",
                organization: "UK National Health Service (NHS)",
                url: "https://www.nhs.uk/live-well/eat-well/food-guidelines-and-food-labels/the-eatwell-guide/",
                description: "UK government guidance on healthy eating and balanced nutrition, including Reference Nutrient Intake (RNI) values used for calculating daily nutrient percentages throughout this app.",
                category: .dailyValues
            ),

            Citation(
                title: "SACN Reports and Position Statements",
                organization: "UK Scientific Advisory Committee on Nutrition (SACN)",
                url: "https://www.gov.uk/government/collections/sacn-reports-and-position-statements",
                description: "Official UK government dietary reference values (DRVs) for vitamins, minerals, and nutrients, including comprehensive reports on nutrition standards.",
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
                title: "SUMMARY TABLES: Dietary Reference Intakes",
                organization: "National Institutes of Health (NIH) / National Academies",
                url: "https://www.ncbi.nlm.nih.gov/books/NBK222881/",
                description: "Comprehensive DRI tables presenting Estimated Average Requirements (EARs) and Recommended Dietary Allowances (RDAs) for vitamins and minerals across all life stages.",
                category: .dailyValues
            ),

            // MARK: - Vitamin & Mineral Health Benefits (EFSA Approved Claims)

            Citation(
                title: "Vitamin A related health claims",
                organization: "European Food Safety Authority (EFSA)",
                url: "https://www.efsa.europa.eu/en/efsajournal/pub/1221",
                description: "EFSA-approved health claims: Vitamin A contributes to normal iron metabolism, maintenance of normal mucous membranes, normal skin, normal vision, normal function of immune system, and process of cell specialisation.",
                category: .dailyValues
            ),

            Citation(
                title: "Vitamin C related health claims",
                organization: "European Food Safety Authority (EFSA)",
                url: "https://www.efsa.europa.eu/en/efsajournal/pub/1226",
                description: "EFSA-approved claims: Vitamin C contributes to normal collagen formation for bones, cartilage, skin, gums, and teeth. It also increases iron absorption and contributes to normal function of immune system.",
                category: .dailyValues
            ),

            Citation(
                title: "Vitamin D related health claims",
                organization: "European Food Safety Authority (EFSA)",
                url: "https://www.efsa.europa.eu/en/efsajournal/pub/1227",
                description: "EFSA-approved claims: Vitamin D contributes to normal absorption/utilisation of calcium and phosphorus, normal blood calcium concentrations, maintenance of normal bones and teeth, normal muscle function, and normal function of immune system.",
                category: .dailyValues
            ),

            Citation(
                title: "Iron related health claims",
                organization: "European Food Safety Authority (EFSA)",
                url: "https://www.efsa.europa.eu/en/efsajournal/pub/1740",
                description: "EFSA-approved claims: Iron contributes to normal formation of red blood cells and haemoglobin, normal oxygen transport, normal function of immune system, reduction of tiredness and fatigue, and normal cognitive function.",
                category: .dailyValues
            ),

            Citation(
                title: "Calcium and Vitamin D related health claims",
                organization: "European Food Safety Authority (EFSA)",
                url: "https://www.efsa.europa.eu/en/efsajournal/pub/1272",
                description: "EFSA-approved claims: Calcium is needed for maintenance of normal bones and teeth, contributes to normal blood clotting, normal muscle function, and normal nerve transmission.",
                category: .dailyValues
            ),

            Citation(
                title: "Vitamins and minerals - Vitamin A",
                organization: "UK National Health Service (NHS)",
                url: "https://www.nhs.uk/conditions/vitamins-and-minerals/vitamin-a/",
                description: "NHS guidance: Vitamin A helps immune system work properly, helps vision in dim light, and keeps skin and mucous membranes healthy.",
                category: .dailyValues
            ),

            Citation(
                title: "Vitamins and minerals - Vitamin C",
                organization: "UK National Health Service (NHS)",
                url: "https://www.nhs.uk/conditions/vitamins-and-minerals/vitamin-c/",
                description: "NHS guidance: Vitamin C helps protect cells, maintain healthy skin, blood vessels, bones and cartilage, and helps with wound healing.",
                category: .dailyValues
            ),

            Citation(
                title: "Vitamins and minerals - Vitamin D",
                organization: "UK National Health Service (NHS)",
                url: "https://www.nhs.uk/conditions/vitamins-and-minerals/vitamin-d/",
                description: "NHS guidance: Vitamin D helps regulate calcium and phosphate, keeping bones, teeth and muscles healthy.",
                category: .dailyValues
            ),

            Citation(
                title: "Vitamins and minerals - Iron",
                organization: "UK National Health Service (NHS)",
                url: "https://www.nhs.uk/conditions/vitamins-and-minerals/iron/",
                description: "NHS guidance: Iron helps make red blood cells, which carry oxygen around the body. Lack of iron can lead to iron deficiency anaemia.",
                category: .dailyValues
            ),

            Citation(
                title: "EU Register of Nutrition and Health Claims",
                organization: "European Commission",
                url: "https://food.ec.europa.eu/food-safety/labelling-and-nutrition/nutrition-and-health-claims/eu-register-health-claims_en",
                description: "Official EU register of authorized and rejected nutrition and health claims on foods, providing searchable database of all permitted health claims under Regulation (EC) No 1924/2006.",
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
                title: "Ultra-processed foods, diet quality, and health using the NOVA classification system",
                organization: "Food and Agriculture Organization of the United Nations (FAO)",
                url: "https://www.fao.org/fsnforum/resources/trainings-tools-and-databases/ultra-processed-foods-diet-quality-and-health-using-nova",
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
                title: "Salt reduction targets for 2024",
                organization: "Public Health England / UK Government",
                url: "https://www.gov.uk/government/publications/salt-reduction-targets-for-2024",
                description: "UK government targets for salt reduction in food products, with voluntary targets for 2024 published by Public Health England.",
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
                title: "Food colours and hyperactivity in children - Southampton Study",
                organization: "University of Southampton",
                url: "https://www.southampton.ac.uk/news/2007/09/hyperactivity-in-children-and-food-additives.page",
                description: "Major study funded by the Food Standards Agency finding that mixtures of certain food colours and benzoate preservative can adversely influence the behaviour of children (McCann et al., 2007).",
                category: .additives
            ),

            Citation(
                title: "Food additives and behaviour in 3-year-old and 8/9-year-old children (Southampton Study)",
                organization: "The Lancet / PubMed",
                url: "https://pubmed.ncbi.nlm.nih.gov/17825405/",
                description: "Peer-reviewed randomised, double-blinded, placebo-controlled trial finding that artificial colours or sodium benzoate preservative in the diet result in increased hyperactivity in children. McCann et al., Lancet 2007.",
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
                title: "Food Facts - Nutrition Guidelines",
                organization: "British Dietetic Association (BDA)",
                url: "https://www.bda.uk.com/food-health/food-facts.html",
                description: "Professional nutrition guidance and food fact sheets from the UK's professional association for dietitians, certified by the Patient Information Forum (PIF) TICK.",
                category: .general
            ),

            Citation(
                title: "Intermittent fasting for weight management",
                organization: "UK National Health Service (NHS) - MyHealth London",
                url: "https://www.myhealthlondon.nhs.uk/be-healthier/lose-weight/which-diet-is-right-for-me/intermittent-fasting/",
                description: "NHS information on intermittent fasting including the 5:2 diet approach, safety guidance, medical considerations, and research on time-restricted feeding.",
                category: .general
            ),

            // MARK: - Intermittent Fasting & Autophagy
            Citation(
                title: "Intermittent Fasting: What is it, and how does it work?",
                organization: "Johns Hopkins Medicine",
                url: "https://www.hopkinsmedicine.org/health/wellness-and-prevention/intermittent-fasting-what-is-it-and-how-does-it-work",
                description: "Johns Hopkins Medicine explains the science of intermittent fasting including metabolic switching, cellular repair processes, and evidence-based health benefits supported by peer-reviewed research.",
                category: .fasting
            ),

            Citation(
                title: "Intermittent Fasting and Metabolic Health",
                organization: "National Center for Biotechnology Information (NCBI) / Nutrients Journal",
                url: "https://pmc.ncbi.nlm.nih.gov/articles/PMC8839325/",
                description: "Peer-reviewed 2022 study on metabolic effects of intermittent fasting including glycogen depletion, ketogenesis, and autophagy activation. Published in Nutrients, demonstrating metabolic switching and cellular stress response pathways.",
                category: .fasting
            ),

            Citation(
                title: "The Beneficial and Adverse Effects of Autophagic Response to Caloric Restriction and Fasting",
                organization: "National Center for Biotechnology Information (NCBI)",
                url: "https://pmc.ncbi.nlm.nih.gov/articles/PMC10509423/",
                description: "Peer-reviewed research on autophagy activation during fasting, showing autophagy begins after 18-24 hours of fasting in humans with peak activity at 48-72 hours.",
                category: .fasting
            ),

            Citation(
                title: "Long-Term Fasting-Induced Ketosis in 1610 Subjects: Metabolic Regulation and Safety",
                organization: "National Center for Biotechnology Information (NCBI)",
                url: "https://pmc.ncbi.nlm.nih.gov/articles/PMC11206495/",
                description: "2024 study on ketosis during fasting, demonstrating ketone production increases significantly after 16-18 hours of fasting with metabolic benefits for brain function and energy.",
                category: .fasting
            ),

            Citation(
                title: "Intermittent Fasting: Benefits and Medical Considerations",
                organization: "UK National Health Service (NHS) - MyHealth London",
                url: "https://www.myhealthlondon.nhs.uk/be-healthier/lose-weight/which-diet-is-right-for-me/intermittent-fasting/",
                description: "NHS guidance on intermittent fasting including metabolic changes during fasting periods, safety considerations, and evidence-based benefits from research on insulin sensitivity and blood pressure.",
                category: .fasting
            ),

            Citation(
                title: "The cyclic metabolic switching theory of intermittent fasting",
                organization: "Johns Hopkins University / Nature Metabolism",
                url: "https://pubmed.ncbi.nlm.nih.gov/40087409/",
                description: "2025 paper establishing the cyclic metabolic switching (CMS) theory of intermittent fasting, showing benefits result from alternating between adaptive cellular stress response pathways during fasting and cell growth pathways during feeding.",
                category: .fasting
            )
        ]
    }

    /// Get citations by category
    func citations(for category: CitationCategory) -> [Citation] {
        return allCitations.filter { $0.category == category }
    }

    /// Get primary citation for daily values
    var primaryDailyValuesCitation: Citation? {
        return allCitations.first { $0.category == .dailyValues && $0.organization.contains("FDA") }
    }

    /// Get primary citation for nutrition data
    var primaryNutritionDataCitation: Citation? {
        return allCitations.first { $0.category == .nutritionData }
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
        case .fasting:
            return "Fasting information based on NHS, NIH, and peer-reviewed research"
        case .general:
            return "Guidelines based on NHS and UK government recommendations"
        }
    }
}
