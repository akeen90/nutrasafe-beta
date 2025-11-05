import Foundation

/// Brand synonym mapper for flexible search
/// Allows users to search using common variations of brand names
class BrandSynonymMapper {

    /// Map of canonical brand names to their synonyms
    private static let brandSynonyms: [String: [String]] = [
        "M&S": ["marks and spencer", "marks & spencer", "marks spencer", "m and s", "ms", "m&s food", "marks", "spencer"],
        "Sainsbury's": ["sainsburys", "sainsbury", "j sainsbury", "by sainsbury's", "by sainsburys", "taste the difference"],
        "Tesco": ["tesco finest", "tesco value", "tesco extra", "tesco express"],
        "Asda": ["asda smart price", "asda extra special"],
        "Morrisons": ["morrison", "morrisons savers", "morrisons the best"],
        "Waitrose": ["waitrose & partners", "waitrose essential", "essential waitrose", "waitrose duchy organic"],
        "Aldi": ["aldi specially selected"],
        "Lidl": ["lidl deluxe"],
        "Co-op": ["coop", "co-operative", "cooperative", "co op", "the co-op"],
        "Iceland": ["iceland foods", "iceland frozen foods"],
        "Kellogg's": ["kelloggs", "kellogg"],
        "Cadbury": ["cadburys", "cadbury's"],
        "McVitie's": ["mcvities", "mcvitie"],
        "Heinz": ["hj heinz", "h.j. heinz"],
        "Nestlé": ["nestle", "nestles"],
        "Coca-Cola": ["coke", "coca cola", "cocacola"],
        "Pepsi": ["pepsi-cola", "pepsico"],
        "Walkers": ["walkers crisps"],
        "Quorn": ["quorn foods"],
        "Hovis": ["hovis bread"],
        "Warburtons": ["warburton", "warburton's"],
        "Birds Eye": ["bird's eye", "birdseye", "birds-eye"],
        "Ben's Original": ["uncle ben's", "uncle bens", "bens original"],
        "Müller": ["muller", "mueller"],
        "Philadelphia": ["philly"],
        "Anchor": ["anchor butter", "anchor dairy"],
        "Flora": ["flora buttery"],
        "Branston": ["branston pickle"],
        "Colman's": ["colmans", "colman", "colemans"],
        "Bisto": ["bisto gravy"],
        "Weetabix": ["weetabix cereal"]
    ]

    /// Reverse map: synonym -> canonical brand name
    private static let synonymToCanonical: [String: String] = {
        var map = [String: String]()
        for (canonical, synonyms) in brandSynonyms {
            // Add canonical name mapping to itself
            map[canonical.lowercased()] = canonical

            // Add all synonyms
            for synonym in synonyms {
                map[synonym.lowercased()] = canonical
            }
        }
        return map
    }()

    /// Get the canonical brand name from a search term
    /// - Parameter searchTerm: The brand name or synonym entered by user
    /// - Returns: The canonical brand name used in the database, or the original term if no match
    static func getCanonicalBrand(from searchTerm: String) -> String {
        let normalized = searchTerm.lowercased().trimmingCharacters(in: .whitespaces)
        return synonymToCanonical[normalized] ?? searchTerm
    }

    /// Get all possible search variations for a canonical brand
    /// - Parameter canonicalBrand: The canonical brand name
    /// - Returns: Array of all synonyms including the canonical name
    static func getAllVariations(for canonicalBrand: String) -> [String] {
        var variations = [canonicalBrand]
        if let synonyms = brandSynonyms[canonicalBrand] {
            variations.append(contentsOf: synonyms)
        }
        return variations
    }

    /// Check if a search term matches a brand (including synonyms)
    /// - Parameters:
    ///   - searchTerm: The term being searched
    ///   - brand: The brand from the database
    /// - Returns: True if the search term matches the brand or any of its synonyms
    static func matches(searchTerm: String, brand: String?) -> Bool {
        guard let brand = brand else { return false }

        let normalizedSearch = searchTerm.lowercased().trimmingCharacters(in: .whitespaces)
        let normalizedBrand = brand.lowercased()

        // Direct match
        if normalizedBrand.contains(normalizedSearch) {
            return true
        }

        // Check if search term is a synonym of this brand
        let canonicalForSearch = getCanonicalBrand(from: searchTerm)
        let canonicalForBrand = getCanonicalBrand(from: brand)

        return canonicalForSearch == canonicalForBrand
    }

    /// Example usage in search function:
    /// ```swift
    /// func searchFoods(query: String) -> [Food] {
    ///     let canonicalBrand = BrandSynonymMapper.getCanonicalBrand(from: query)
    ///     // Search database using canonicalBrand
    ///     return database.foods.filter { food in
    ///         BrandSynonymMapper.matches(searchTerm: query, brand: food.brand)
    ///     }
    /// }
    /// ```
}

// MARK: - Extension for easy integration
extension String {
    /// Get canonical brand name for this string
    var canonicalBrand: String {
        BrandSynonymMapper.getCanonicalBrand(from: self)
    }
}
