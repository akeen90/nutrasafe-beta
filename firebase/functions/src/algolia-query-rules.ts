/**
 * Algolia Query Rules for Smart Search Expansion
 * These rules automatically expand queries and boost relevant brands
 */

import * as functions from "firebase-functions/v2";
import {defineSecret} from "firebase-functions/params";
import {algoliasearch} from "algoliasearch";

const ALGOLIA_APP_ID = "WK0TIF84M2";
const algoliaAdminKey = defineSecret("ALGOLIA_ADMIN_API_KEY");

// All indices to sync rules to
const ALL_INDICES = [
  "verified_foods",
  "foods",
  "manual_foods",
  "user_added",
  "ai_enhanced",
  "ai_manually_added",
];

// Type for anchoring (Algolia SDK)
type Anchoring = "is" | "startsWith" | "endsWith" | "contains";

// =============================================================================
// QUERY RULES DEFINITIONS
// =============================================================================

interface QueryRuleCondition {
  pattern: string;
  anchoring: Anchoring;
  alternatives?: boolean;
}

interface QueryRule {
  objectID: string;
  conditions: QueryRuleCondition[];
  consequence: {
    params: {
      optionalFilters?: string[];
    };
  };
  description: string;
}

/**
 * Query Rules for Fast Food Menu Items
 * When a user searches for a menu item, boost the associated brand
 */
const QUERY_RULES: QueryRule[] = [
  // McDonald's products
  {
    objectID: "rule-big-mac",
    conditions: [{pattern: "big mac", anchoring: "contains", alternatives: false}],
    consequence: {
      params: {
        optionalFilters: ["brandName:McDonald's<score=10>", "brandName:McDonalds<score=10>"],
      },
    },
    description: "Boost McDonald's for Big Mac searches",
  },
  {
    objectID: "rule-quarter-pounder",
    conditions: [{pattern: "quarter pounder", anchoring: "contains", alternatives: false}],
    consequence: {
      params: {
        optionalFilters: ["brandName:McDonald's<score=10>", "brandName:McDonalds<score=10>"],
      },
    },
    description: "Boost McDonald's for Quarter Pounder searches",
  },
  {
    objectID: "rule-mcflurry",
    conditions: [{pattern: "mcflurry", anchoring: "contains", alternatives: false}],
    consequence: {
      params: {
        optionalFilters: ["brandName:McDonald's<score=10>", "brandName:McDonalds<score=10>"],
      },
    },
    description: "Boost McDonald's for McFlurry searches",
  },
  {
    objectID: "rule-mcnuggets",
    conditions: [{pattern: "mcnugget", anchoring: "contains", alternatives: false}],
    consequence: {
      params: {
        optionalFilters: ["brandName:McDonald's<score=10>", "brandName:McDonalds<score=10>"],
      },
    },
    description: "Boost McDonald's for McNuggets searches",
  },
  {
    objectID: "rule-happy-meal",
    conditions: [{pattern: "happy meal", anchoring: "contains", alternatives: false}],
    consequence: {
      params: {
        optionalFilters: ["brandName:McDonald's<score=10>", "brandName:McDonalds<score=10>"],
      },
    },
    description: "Boost McDonald's for Happy Meal searches",
  },

  // Burger King products
  {
    objectID: "rule-whopper",
    conditions: [{pattern: "whopper", anchoring: "contains", alternatives: false}],
    consequence: {
      params: {
        optionalFilters: ["brandName:Burger King<score=10>"],
      },
    },
    description: "Boost Burger King for Whopper searches",
  },

  // KFC products
  {
    objectID: "rule-zinger",
    conditions: [{pattern: "zinger", anchoring: "contains", alternatives: false}],
    consequence: {
      params: {
        optionalFilters: ["brandName:KFC<score=10>"],
      },
    },
    description: "Boost KFC for Zinger searches",
  },
  {
    objectID: "rule-popcorn-chicken",
    conditions: [{pattern: "popcorn chicken", anchoring: "contains", alternatives: false}],
    consequence: {
      params: {
        optionalFilters: ["brandName:KFC<score=10>"],
      },
    },
    description: "Boost KFC for Popcorn Chicken searches",
  },

  // Greggs products
  {
    objectID: "rule-sausage-roll",
    conditions: [{pattern: "sausage roll", anchoring: "contains", alternatives: false}],
    consequence: {
      params: {
        optionalFilters: ["brandName:Greggs<score=8>"],
      },
    },
    description: "Boost Greggs for Sausage Roll searches",
  },
  {
    objectID: "rule-steak-bake",
    conditions: [{pattern: "steak bake", anchoring: "contains", alternatives: false}],
    consequence: {
      params: {
        optionalFilters: ["brandName:Greggs<score=10>"],
      },
    },
    description: "Boost Greggs for Steak Bake searches",
  },
  {
    objectID: "rule-festive-bake",
    conditions: [{pattern: "festive bake", anchoring: "contains", alternatives: false}],
    consequence: {
      params: {
        optionalFilters: ["brandName:Greggs<score=10>"],
      },
    },
    description: "Boost Greggs for Festive Bake searches",
  },

  // Nando's products
  {
    objectID: "rule-peri-peri",
    conditions: [{pattern: "peri peri", anchoring: "contains", alternatives: false}],
    consequence: {
      params: {
        optionalFilters: ["brandName:Nando's<score=8>", "brandName:Nandos<score=8>"],
      },
    },
    description: "Boost Nando's for Peri Peri searches",
  },

  // Subway products
  {
    objectID: "rule-footlong",
    conditions: [{pattern: "footlong", anchoring: "contains", alternatives: false}],
    consequence: {
      params: {
        optionalFilters: ["brandName:Subway<score=10>"],
      },
    },
    description: "Boost Subway for Footlong searches",
  },
  {
    objectID: "rule-meatball-marinara",
    conditions: [{pattern: "meatball marinara", anchoring: "contains", alternatives: false}],
    consequence: {
      params: {
        optionalFilters: ["brandName:Subway<score=10>"],
      },
    },
    description: "Boost Subway for Meatball Marinara searches",
  },

  // Starbucks products
  {
    objectID: "rule-frappuccino",
    conditions: [{pattern: "frappuccino", anchoring: "contains", alternatives: false}],
    consequence: {
      params: {
        optionalFilters: ["brandName:Starbucks<score=10>"],
      },
    },
    description: "Boost Starbucks for Frappuccino searches",
  },

  // Domino's products
  {
    objectID: "rule-stuffed-crust",
    conditions: [{pattern: "stuffed crust", anchoring: "contains", alternatives: false}],
    consequence: {
      params: {
        optionalFilters: ["brandName:Domino's<score=8>", "brandName:Dominos<score=8>"],
      },
    },
    description: "Boost Domino's for Stuffed Crust searches",
  },

  // Wagamama products
  {
    objectID: "rule-katsu-curry",
    conditions: [{pattern: "katsu curry", anchoring: "contains", alternatives: false}],
    consequence: {
      params: {
        optionalFilters: ["brandName:Wagamama<score=5>"],
      },
    },
    description: "Slightly boost Wagamama for Katsu Curry (but allow other brands)",
  },

  // Charlie Bigham's
  {
    objectID: "rule-bighams",
    conditions: [{pattern: "bighams", anchoring: "contains", alternatives: false}],
    consequence: {
      params: {
        optionalFilters: ["brandName:Charlie Bigham's<score=10>"],
      },
    },
    description: "Boost Charlie Bigham's for Bighams searches",
  },
];

// =============================================================================
// FIREBASE FUNCTIONS
// =============================================================================

/**
 * Configure Query Rules across all Algolia indices
 * Call this endpoint to push rules to all food indices
 */
export const configureQueryRules = functions.https.onRequest({
  secrets: [algoliaAdminKey],
  cors: true,
  timeoutSeconds: 120,
}, async (request, response) => {
  const client = algoliasearch(ALGOLIA_APP_ID, algoliaAdminKey.value());

  const results: Record<string, {status: string; count?: number; error?: string}> = {};

  console.log(`📋 Configuring ${QUERY_RULES.length} query rules across ${ALL_INDICES.length} indices...`);

  for (const indexName of ALL_INDICES) {
    try {
      await client.saveRules({
        indexName,
        rules: QUERY_RULES as any[], // Cast for SDK compatibility
        forwardToReplicas: true,
        clearExistingRules: true,
      });

      results[indexName] = {
        status: "success",
        count: QUERY_RULES.length,
      };
      console.log(`✅ Saved ${QUERY_RULES.length} rules to ${indexName}`);
    } catch (error: any) {
      results[indexName] = {
        status: "failed",
        error: error.message,
      };
      console.error(`❌ Failed to save rules to ${indexName}:`, error.message);
    }
  }

  response.json({
    success: true,
    message: "Query rules configured",
    totalRules: QUERY_RULES.length,
    rules: QUERY_RULES.map((r) => ({id: r.objectID, description: r.description})),
    results,
  });
});

/**
 * Get Query Rules statistics from Algolia
 */
export const getQueryRulesStats = functions.https.onRequest({
  secrets: [algoliaAdminKey],
  cors: true,
}, async (request, response) => {
  const client = algoliasearch(ALGOLIA_APP_ID, algoliaAdminKey.value());

  const stats: Record<string, number> = {};

  for (const indexName of ALL_INDICES) {
    try {
      const result = await client.searchRules({
        indexName,
        searchRulesParams: {query: "", hitsPerPage: 0},
      });
      stats[indexName] = result.nbHits || 0;
    } catch (error: any) {
      stats[indexName] = -1; // Error indicator
      console.error(`Error getting rules for ${indexName}:`, error.message);
    }
  }

  response.json({
    success: true,
    ruleCounts: stats,
    expectedCount: QUERY_RULES.length,
  });
});

/**
 * Clear all Query Rules from Algolia indices
 * Use with caution - removes all rules
 */
export const clearQueryRules = functions.https.onRequest({
  secrets: [algoliaAdminKey],
  cors: true,
}, async (request, response) => {
  // Safety check - require confirmation parameter
  if (request.query.confirm !== "yes") {
    response.status(400).json({
      error: "Add ?confirm=yes to confirm clearing all query rules",
    });
    return;
  }

  const client = algoliasearch(ALGOLIA_APP_ID, algoliaAdminKey.value());

  const results: Record<string, string> = {};

  for (const indexName of ALL_INDICES) {
    try {
      await client.clearRules({
        indexName,
        forwardToReplicas: true,
      });
      results[indexName] = "cleared";
      console.log(`🗑️ Cleared rules from ${indexName}`);
    } catch (error: any) {
      results[indexName] = `failed: ${error.message}`;
    }
  }

  response.json({
    success: true,
    message: "Query rules cleared",
    results,
  });
});
