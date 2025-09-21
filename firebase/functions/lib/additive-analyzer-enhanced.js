"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.analyzeAdditivesEnhanced = void 0;
exports.loadAdditiveDatabase = loadAdditiveDatabase;
exports.analyzeIngredientsForAdditives = analyzeIngredientsForAdditives;
exports.calculateProcessingScore = calculateProcessingScore;
exports.determineGrade = determineGrade;
const functions = require("firebase-functions");
const fs = require("fs");
const path = require("path");
// Comprehensive additives database and processing rules
let COMPREHENSIVE_ADDITIVES_DB = {};
let PROCESSING_RULES;
let DATABASE_LOADED = false;
// Load comprehensive additives database
function loadAdditiveDatabase() {
    if (DATABASE_LOADED)
        return;
    try {
        // First try to load the comprehensive CSV database
        const comprehensiveCSVPath = path.join(__dirname, './uk_additives_with_grades_403_5744a8e4.csv');
        if (fs.existsSync(comprehensiveCSVPath)) {
            console.log('🚀 Loading comprehensive 403 additives from CSV with rich consumer data');
            loadComprehensiveCSV(comprehensiveCSVPath);
        }
        else {
            // Fallback to simplified JSON
            const essentialAdditivesPath = path.join(__dirname, './essential-additives.json');
            if (fs.existsSync(essentialAdditivesPath)) {
                console.log('🚀 Loading comprehensive 403 additives database');
                loadEssentialAdditives(essentialAdditivesPath);
            }
            else {
                console.log('⚠️ Essential additives file not found, using fallback data');
                loadFallbackData();
            }
        }
        // Load processing rules
        const rulesPath = path.join(__dirname, './uk_processing_grade_rules_dbe1dcc2.json');
        if (fs.existsSync(rulesPath)) {
            const rulesContent = fs.readFileSync(rulesPath, 'utf-8');
            PROCESSING_RULES = JSON.parse(rulesContent);
        }
        else {
            console.log('⚠️ Processing rules not found at path:', rulesPath, ', using defaults');
            loadDefaultProcessingRules();
        }
        // Always add enhanced hidden additives to the main database
        addEnhancedHiddenAdditives();
        DATABASE_LOADED = true;
        console.log(`✅ Loaded ${Object.keys(COMPREHENSIVE_ADDITIVES_DB).length} additives (including enhanced hidden additives) and processing rules`);
    }
    catch (error) {
        console.error('❌ Error loading additive database:', error);
        loadFallbackData();
        loadDefaultProcessingRules();
        DATABASE_LOADED = true;
    }
}
/* Temporarily disabled CSV parsing
function parseComprehensiveCSV(csvContent: string) {
  const lines = csvContent.split('\n');
  if (lines.length < 3) return;

  // Skip the identifier and header rows
  const dataLines = lines.slice(2).filter(line => line.trim());

  for (const line of dataLines) {
    try {
      const columns = parseCSVLine(line);
      if (columns.length >= 19) {
        const code = columns[0].trim();
        const sources = parseSourcesFromJSON(columns[19] || '[]');
        
        const additive: AdditiveInfo = {
          code,
          name: columns[1].trim(),
          category: columns[2].trim(),
          permitted_GB: columns[3] === 'TRUE',
          permitted_NI: columns[4] === 'TRUE',
          permitted_EU: columns[5] === 'TRUE',
          status_notes: columns[6].trim() || undefined,
          child_warning: columns[7] === 'TRUE',
          PKU_warning: columns[8] === 'TRUE',
          polyols_warning: columns[9] === 'TRUE',
          sulphites_allergen_label: columns[10] === 'TRUE',
          origin: columns[11].trim(),
          overview: columns[12].trim(),
          typical_uses: columns[13].trim(),
          effects_summary: columns[14].trim(),
          effects_verdict: (columns[15].trim() as 'neutral' | 'caution' | 'avoid') || 'neutral',
          synonyms: columns[16] ? columns[16].split(';').map(s => s.trim()) : [],
          matches: columns[17] ? columns[17].split(';').map(s => s.trim()) : [],
          ins_number: columns[18].trim() || undefined,
          sources
        };

        COMPREHENSIVE_ADDITIVES_DB[code] = additive;

        // Also index by common names for better matching
        for (const synonym of additive.synonyms) {
          if (synonym && !COMPREHENSIVE_ADDITIVES_DB[synonym.toUpperCase()]) {
            COMPREHENSIVE_ADDITIVES_DB[synonym.toUpperCase()] = additive;
          }
        }
      }
    } catch (error) {
      console.error('Error parsing CSV line:', error, line.substring(0, 100));
    }
  }
}

function parseCSVLine(line: string): string[] {
  const result: string[] = [];
  let current = '';
  let inQuotes = false;
  let i = 0;

  while (i < line.length) {
    const char = line[i];
    
    if (char === '"') {
      if (inQuotes && i + 1 < line.length && line[i + 1] === '"') {
        current += '"';
        i++; // Skip the next quote
      } else {
        inQuotes = !inQuotes;
      }
    } else if (char === ',' && !inQuotes) {
      result.push(current);
      current = '';
    } else {
      current += char;
    }
    
    i++;
  }
  
  result.push(current);
  return result;
}
*/
// function parseSourcesFromJSON(sourcesStr: string): Array<{title: string, url: string, covers: string}> {
//   try {
//     return JSON.parse(sourcesStr) || [];
//   } catch {
//     return [];
//   }
// }
function loadComprehensiveCSV(csvPath) {
    console.log('📊 Loading comprehensive CSV with rich consumer data from:', csvPath);
    const csvContent = fs.readFileSync(csvPath, 'utf-8');
    const lines = csvContent.split('\n');
    if (lines.length < 2) {
        console.error('❌ CSV file is empty or malformed');
        return;
    }
    // Parse header
    const headers = parseCSVLine(lines[0]);
    console.log(`📋 CSV headers found: ${headers.length} columns`);
    // Process data lines
    for (let i = 1; i < lines.length; i++) {
        const line = lines[i].trim();
        if (!line)
            continue;
        try {
            const columns = parseCSVLine(line);
            if (columns.length >= 18) {
                const code = columns[0].trim();
                const sources = parseSourcesFromJSON(columns[14] || '[]');
                // Convert grade to effects_verdict  
                let effects_verdict = 'neutral';
                const grade = columns[10].trim();
                if (grade === 'Avoid')
                    effects_verdict = 'avoid';
                else if (grade === 'Limit')
                    effects_verdict = 'caution';
                else if (grade === 'Generally OK')
                    effects_verdict = 'neutral';
                // Extract regulatory status first
                const regulatory_status = columns[9].trim();
                const permitted_EU = !regulatory_status.includes('banned') && !regulatory_status.includes('EU: banned');
                const permitted_NI = !regulatory_status.includes('NI: banned') && !regulatory_status.includes('EU/NI: banned');
                const permitted_GB = !regulatory_status.includes('GB: banned');
                // Extract ALL valuable consumer information
                const what_it_is = columns[3].trim(); // Rich technical description
                const why_it_is_used = columns[4].trim(); // Purpose
                const common_in = columns[5].trim(); // Real product examples  
                const child_note = columns[6].trim(); // Child-specific guidance
                const who_should_take_care = columns[7].trim(); // Target audiences
                const headline_risk = columns[8].trim(); // Risk summary
                // regulatory_status already extracted above
                const quick_advice = columns[11].trim(); // Direct consumer guidance
                const aka_labels = columns[13].trim(); // Alternative names on labels
                const uk_grade_note = columns[17] ? columns[17].trim() : ''; // UK-specific insights
                // Keep individual fields separate for proper consumer-friendly structure
                // Enhanced warnings detection
                const child_warning = child_note.includes('children') || child_note.includes('behaviour') ||
                    child_note.includes('activity') || child_note.includes('attention');
                const PKU_warning = columns[1].toLowerCase().includes('aspartame') || who_should_take_care.includes('PKU');
                const polyols_warning = columns[2].includes('polyol') || columns[1].toLowerCase().includes('polyol');
                const sulphites_allergen_label = columns[1].toLowerCase().includes('sulph') || code.startsWith('E22');
                // Create health-conscious consumer guide with bold headers
                const consumer_info = `**What is it?**
${what_it_is || 'Technical description not available'}

**Why is it added to food?**
${why_it_is_used || 'Purpose not specified'}

**Found in these foods:**
${common_in || 'Common uses not specified'}

**For parents - child safety:**
${child_note || 'No specific guidance available for children'}

**Who should be extra careful:**
${who_should_take_care || 'No specific population warnings identified'}

**Health impact summary:**
${headline_risk || 'Health impact information not available'}

**What you can do:**
${quick_advice || 'No specific consumer guidance available'}

**UK regulatory notes:**
${uk_grade_note || 'No additional UK-specific information'}`;
                const additive = {
                    code: code,
                    name: columns[1].trim(),
                    category: columns[2].trim().toLowerCase(),
                    permitted_GB: permitted_GB,
                    permitted_NI: permitted_NI,
                    permitted_EU: permitted_EU,
                    status_notes: regulatory_status,
                    child_warning: child_warning,
                    PKU_warning: PKU_warning,
                    polyols_warning: polyols_warning,
                    sulphites_allergen_label: sulphites_allergen_label,
                    origin: what_it_is.includes('synthetic') || what_it_is.includes('man-made') ? 'synthetic' :
                        what_it_is.includes('natural') ? 'natural' : 'mixed',
                    consumer_guide: consumer_info, // Complete health-conscious parent guide
                    effects_verdict: effects_verdict,
                    synonyms: aka_labels ? aka_labels.split(',').map(s => s.trim()).filter(s => s.length > 0) : [],
                    matches: [
                        columns[1].toLowerCase(), // name
                        ...(aka_labels ? aka_labels.split(',').map(s => s.trim().toLowerCase()).filter(s => s.length > 0) : []),
                        code.toLowerCase() // E-number
                    ],
                    sources: sources
                };
                COMPREHENSIVE_ADDITIVES_DB[code] = additive;
                // Also index by synonyms for better matching
                for (const synonym of additive.synonyms) {
                    if (synonym && !COMPREHENSIVE_ADDITIVES_DB[synonym.toUpperCase()]) {
                        COMPREHENSIVE_ADDITIVES_DB[synonym.toUpperCase()] = additive;
                    }
                }
            }
        }
        catch (error) {
            console.error('❌ Error parsing CSV line:', error);
        }
    }
    console.log(`📊 Loaded ${Object.keys(COMPREHENSIVE_ADDITIVES_DB).length} comprehensive additives with rich consumer data`);
}
function parseCSVLine(line) {
    const result = [];
    let current = '';
    let inQuotes = false;
    let i = 0;
    while (i < line.length) {
        const char = line[i];
        if (char === '"') {
            if (inQuotes && i + 1 < line.length && line[i + 1] === '"') {
                current += '"';
                i++; // Skip the next quote
            }
            else {
                inQuotes = !inQuotes;
            }
        }
        else if (char === ',' && !inQuotes) {
            result.push(current);
            current = '';
        }
        else {
            current += char;
        }
        i++;
    }
    result.push(current);
    return result;
}
function parseSourcesFromJSON(sourcesStr) {
    try {
        return JSON.parse(sourcesStr) || [];
    }
    catch (_a) {
        return [];
    }
}
function loadEssentialAdditives(filePath) {
    console.log('📋 Loading essential additives from:', filePath);
    const essentialData = JSON.parse(fs.readFileSync(filePath, 'utf-8'));
    for (const [code, essentialAdditive] of Object.entries(essentialData)) {
        const essential = essentialAdditive;
        // Convert grade to effects_verdict
        let effects_verdict = 'neutral';
        if (essential.grade === 'Avoid')
            effects_verdict = 'avoid';
        else if (essential.grade === 'Limit')
            effects_verdict = 'caution';
        else if (essential.grade === 'Generally OK')
            effects_verdict = 'neutral';
        // Determine warnings based on category and known risk factors
        const child_warning = essential.category.includes('colour') &&
            ['E102', 'E104', 'E110', 'E122', 'E124', 'E129'].includes(code);
        const PKU_warning = code === 'E951'; // Aspartame
        const polyols_warning = ['E420', 'E421', 'E953', 'E965', 'E966', 'E967', 'E968'].includes(code);
        const sulphites_allergen_label = code.startsWith('E22'); // Sulphites E220-E229
        // Determine regulatory status
        const permitted_EU = !(code === 'E171' || code === 'E924A' || essential.grade === 'Avoid');
        const permitted_NI = permitted_EU; // Same as EU for most cases
        const permitted_GB = true; // Most are still permitted in GB
        // Handle special cases for E171
        if (code === 'E171') {
            // E171 is banned in EU/NI but still permitted in GB
        }
        const additive = {
            code: essential.code,
            name: essential.name,
            category: essential.category.toLowerCase(),
            permitted_GB: permitted_GB,
            permitted_NI: permitted_NI,
            permitted_EU: permitted_EU,
            status_notes: essential.grade === 'Avoid' ? 'High risk additive' :
                essential.grade === 'Limit' ? 'Use in moderation' :
                    essential.grade === 'Generally OK' ? 'Generally safe' : undefined,
            child_warning: child_warning,
            PKU_warning: PKU_warning,
            polyols_warning: polyols_warning,
            sulphites_allergen_label: sulphites_allergen_label,
            origin: 'synthetic', // Default, could be enhanced with more data
            consumer_guide: `**What is it?**
${essential.name} - ${essential.category} additive

**Why is it added to food?**
Used as ${essential.category.toLowerCase()} in food products

**Found in these foods:**
Various food products

**For parents - child safety:**
${child_warning ? 'May affect children - monitor consumption' : 'No specific guidance available for children'}

**Who should be extra careful:**
${PKU_warning ? 'People with PKU should avoid' : polyols_warning ? 'May cause digestive upset in sensitive individuals' : 'No specific population warnings identified'}

**Health impact summary:**
${essential.grade === 'Avoid' ? 'High risk - avoid if possible' :
                essential.grade === 'Limit' ? 'Moderate risk - limit consumption' :
                    essential.grade === 'Generally OK' ? 'Generally safe for consumption' :
                        'Safety profile not determined'}

**What you can do:**
${essential.grade === 'Avoid' ? 'Choose products without this additive' :
                essential.grade === 'Limit' ? 'Use sparingly and read labels carefully' :
                    'Generally safe when used as intended'}

**UK regulatory notes:**
No additional UK-specific information`,
            effects_verdict: effects_verdict,
            synonyms: essential.synonyms || [],
            matches: essential.matches || [],
            sources: []
        };
        COMPREHENSIVE_ADDITIVES_DB[code] = additive;
        // Also index by synonyms for better matching
        for (const synonym of additive.synonyms) {
            if (synonym && !COMPREHENSIVE_ADDITIVES_DB[synonym.toUpperCase()]) {
                COMPREHENSIVE_ADDITIVES_DB[synonym.toUpperCase()] = additive;
            }
        }
    }
    console.log(`📋 Converted ${Object.keys(essentialData).length} essential additives to comprehensive format`);
}
function addEnhancedHiddenAdditives() {
    console.log('🔍 Adding enhanced hidden additives to comprehensive database...');
    // Define enhanced hidden additives that people don't expect in foods
    const hiddenAdditives = {
        // ANIMAL-DERIVED ADDITIVES (often unexpected)
        'GELATIN': {
            code: 'GELATIN',
            name: 'Gelatin',
            category: 'gelling agent',
            permitted_GB: true,
            permitted_NI: true,
            permitted_EU: true,
            status_notes: 'Animal-derived protein from bones, skin, connective tissue',
            child_warning: false,
            PKU_warning: false,
            polyols_warning: false,
            sulphites_allergen_label: false,
            origin: 'animal',
            consumer_guide: `**What is it?**
Gelatin - protein extracted from animal bones, skin, and connective tissue (usually pork or beef)

**Why is it added to food?**
Creates gel-like texture, helps foods set and hold their shape

**Found in these foods:**
Marshmallows, gummy sweets, jelly, yogurt, ice cream, capsules, some wines

**For parents - child safety:**
Safe for children but not suitable for vegetarians/vegans/certain religious diets

**Who should be extra careful:**
Vegetarians, vegans, Muslims, Jews, people with specific religious dietary restrictions

**Health impact summary:**
Safe protein but many people don't realize it's in their food

**What you can do:**
Look for vegetarian/vegan alternatives - agar, pectin, carrageenan are plant-based substitutes

**UK regulatory notes:**
Must be declared on labels but often people don't realize what it is`,
            effects_verdict: 'neutral',
            synonyms: ['gelatine', 'gel', 'gelling agent'],
            matches: ['gelatin', 'gelatine', 'bovine gelatin', 'pork gelatin', 'fish gelatin'],
            sources: []
        },
        'E120': {
            code: 'E120',
            name: 'Carmine/Cochineal',
            category: 'colour',
            permitted_GB: true,
            permitted_NI: true,
            permitted_EU: true,
            status_notes: 'Red coloring made from crushed insects',
            child_warning: false,
            PKU_warning: false,
            polyols_warning: false,
            sulphites_allergen_label: false,
            origin: 'insect',
            consumer_guide: `**What is it?**
Carmine/Cochineal - bright red coloring made from crushed female cochineal insects

**Why is it added to food?**
Creates natural-looking red color in foods and cosmetics

**Found in these foods:**
Red sweets, strawberry yogurt, red drinks, lipstick, some meat products

**For parents - child safety:**
Safe but many children would be upset knowing it's made from insects

**Who should be extra careful:**
Vegetarians, vegans, people with insect allergies, those avoiding animal products

**Health impact summary:**
Natural and safe but many people prefer to avoid insect-derived ingredients

**What you can do:**
Look for alternatives like beetroot red, paprika extract, or synthetic red dyes

**UK regulatory notes:**
Must be clearly labeled as "Carmine" or "Cochineal" - it's natural but insect-derived`,
            effects_verdict: 'neutral',
            synonyms: ['carmine', 'cochineal', 'cochineal extract', 'carminic acid'],
            matches: ['carmine', 'cochineal', 'natural red'],
            sources: []
        },
        'CASEIN': {
            code: 'CASEIN',
            name: 'Casein',
            category: 'protein',
            permitted_GB: true,
            permitted_NI: true,
            permitted_EU: true,
            status_notes: 'Milk protein - hidden dairy allergen',
            child_warning: false,
            PKU_warning: false,
            polyols_warning: false,
            sulphites_allergen_label: false,
            origin: 'dairy',
            consumer_guide: `**What is it?**
Casein - protein from milk, often found in "dairy-free" products

**Why is it added to food?**
Improves protein content, texture, and binding properties

**Found in these foods:**
Some "non-dairy" creamers, protein bars, processed meats, "vegan" cheese

**For parents - child safety:**
⚠️ HIDDEN DAIRY: Can trigger reactions in milk-allergic children

**Who should be extra careful:**
People with milk allergies, lactose intolerant individuals, vegans

**Health impact summary:**
Safe protein but contains milk allergen - can be seriously hidden

**What you can do:**
Always check ingredients even in "dairy-free" products - look for casein, caseinate

**UK regulatory notes:**
Must be declared as milk allergen even in small amounts`,
            effects_verdict: 'neutral',
            synonyms: ['sodium caseinate', 'calcium caseinate', 'milk protein'],
            matches: ['casein', 'caseinate', 'milk protein'],
            sources: []
        },
        'RENNET': {
            code: 'RENNET',
            name: 'Rennet',
            category: 'enzyme',
            permitted_GB: true,
            permitted_NI: true,
            permitted_EU: true,
            status_notes: 'Often from calf stomach lining - unexpected animal product',
            child_warning: false,
            PKU_warning: false,
            polyols_warning: false,
            sulphites_allergen_label: false,
            origin: 'animal',
            consumer_guide: `**What is it?**
Rennet - enzyme traditionally from calf stomach lining, used to curdle milk for cheese

**Why is it added to food?**
Essential for cheese-making - helps milk proteins coagulate into curds

**Found in these foods:**
Most traditional cheeses, some processed cheese products

**For parents - child safety:**
Safe but many people don't realize cheese contains stomach lining enzymes

**Who should be extra careful:**
Vegetarians, people avoiding animal products for religious reasons

**Health impact summary:**
Safe and natural but many people prefer vegetable or microbial rennet

**What you can do:**
Look for "vegetarian cheese" or "microbial rennet" on labels

**UK regulatory notes:**
Often just listed as "rennet" without specifying animal or vegetable source`,
            effects_verdict: 'neutral',
            synonyms: ['animal rennet', 'calf rennet', 'microbial rennet'],
            matches: ['rennet', 'animal rennet', 'calf rennet'],
            sources: []
        }
    };
    // Add hidden additives to the main database without overwriting existing ones
    let addedCount = 0;
    for (const [code, additive] of Object.entries(hiddenAdditives)) {
        if (!COMPREHENSIVE_ADDITIVES_DB[code]) {
            COMPREHENSIVE_ADDITIVES_DB[code] = additive;
            addedCount++;
            // Also index by synonyms for better matching
            for (const synonym of additive.synonyms) {
                if (synonym && !COMPREHENSIVE_ADDITIVES_DB[synonym.toUpperCase()]) {
                    COMPREHENSIVE_ADDITIVES_DB[synonym.toUpperCase()] = additive;
                }
            }
        }
    }
    console.log(`🔍 Added ${addedCount} enhanced hidden additives to database`);
}
function loadFallbackData() {
    console.log('🔄 Loading fallback additive data with enhanced hidden additive detection...');
    // Comprehensive fallback database with key additives including hidden/unexpected ones
    COMPREHENSIVE_ADDITIVES_DB = {
        // ANIMAL-DERIVED ADDITIVES (often unexpected)
        'GELATIN': {
            code: 'GELATIN',
            name: 'Gelatin',
            category: 'gelling agent',
            permitted_GB: true,
            permitted_NI: true,
            permitted_EU: true,
            status_notes: 'Animal-derived protein from bones, skin, connective tissue',
            child_warning: false,
            PKU_warning: false,
            polyols_warning: false,
            sulphites_allergen_label: false,
            origin: 'animal',
            consumer_guide: `**What is it?**
Gelatin - protein extracted from animal bones, skin, and connective tissue (usually pork or beef)

**Why is it added to food?**
Creates gel-like texture, helps foods set and hold their shape

**Found in these foods:**
Marshmallows, gummy sweets, jelly, yogurt, ice cream, capsules, some wines

**For parents - child safety:**
Safe for children but not suitable for vegetarians/vegans/certain religious diets

**Who should be extra careful:**
Vegetarians, vegans, Muslims, Jews, people with specific religious dietary restrictions

**Health impact summary:**
Safe protein but many people don't realize it's in their food

**What you can do:**
Look for vegetarian/vegan alternatives - agar, pectin, carrageenan are plant-based substitutes

**UK regulatory notes:**
Must be declared on labels but often people don't realize what it is`,
            effects_verdict: 'neutral',
            synonyms: ['gelatine', 'gel', 'gelling agent'],
            matches: ['gelatin', 'gelatine', 'bovine gelatin', 'pork gelatin', 'fish gelatin'],
            sources: []
        },
        'E120': {
            code: 'E120',
            name: 'Carmine/Cochineal',
            category: 'colour',
            permitted_GB: true,
            permitted_NI: true,
            permitted_EU: true,
            status_notes: 'Red coloring made from crushed insects',
            child_warning: false,
            PKU_warning: false,
            polyols_warning: false,
            sulphites_allergen_label: false,
            origin: 'insect',
            consumer_guide: `**What is it?**
Carmine/Cochineal - bright red coloring made from crushed female cochineal insects

**Why is it added to food?**
Creates natural-looking red color in foods and cosmetics

**Found in these foods:**
Red sweets, strawberry yogurt, red drinks, lipstick, some meat products

**For parents - child safety:**
Safe but many children would be upset knowing it's made from insects

**Who should be extra careful:**
Vegetarians, vegans, people with insect allergies, those avoiding animal products

**Health impact summary:**
Natural and safe but many people prefer to avoid insect-derived ingredients

**What you can do:**
Look for alternatives like beetroot red, paprika extract, or synthetic red dyes

**UK regulatory notes:**
Must be clearly labeled as "Carmine" or "Cochineal" - it's natural but insect-derived`,
            effects_verdict: 'neutral',
            synonyms: ['carmine', 'cochineal', 'cochineal extract', 'carminic acid'],
            matches: ['carmine', 'cochineal', 'natural red'],
            sources: []
        },
        'E904': {
            code: 'E904',
            name: 'Shellac',
            category: 'glazing agent',
            permitted_GB: true,
            permitted_NI: true,
            permitted_EU: true,
            status_notes: 'Insect-derived coating to make foods shiny',
            child_warning: false,
            PKU_warning: false,
            polyols_warning: false,
            sulphites_allergen_label: false,
            origin: 'insect',
            consumer_guide: `**What is it?**
Shellac - shiny coating made from the resin secreted by lac insects

**Why is it added to food?**
Makes sweets and pills look glossy and appealing, prevents moisture

**Found in these foods:**
Shiny sweets, chocolate-covered nuts, pharmaceutical tablets, some fruits

**For parents - child safety:**
Safe but many people don't expect insect-derived coatings on food

**Who should be extra careful:**
Vegetarians, vegans, people avoiding animal/insect products

**Health impact summary:**
Safe as a food coating but many prefer to avoid insect-derived ingredients

**What you can do:**
Look for alternatives like plant waxes or choose matte-finish sweets

**UK regulatory notes:**
Must be labeled but many people don't know what shellac actually is`,
            effects_verdict: 'neutral',
            synonyms: ['shellac', 'confectioners glaze', 'resinous glaze'],
            matches: ['shellac', 'confectioner\'s glaze', 'glazing agent'],
            sources: []
        },
        'ISINGLASS': {
            code: 'ISINGLASS',
            name: 'Isinglass',
            category: 'clarifying agent',
            permitted_GB: true,
            permitted_NI: true,
            permitted_EU: true,
            status_notes: 'Fish bladder-derived fining agent',
            child_warning: false,
            PKU_warning: false,
            polyols_warning: false,
            sulphites_allergen_label: false,
            origin: 'fish',
            consumer_guide: `**What is it?**
Isinglass - substance from fish swim bladders used to clarify alcoholic drinks

**Why is it added to food?**
Removes cloudiness from beer, wine, and other alcoholic beverages

**Found in these foods:**
Beer, wine, cider (used in production but removed before bottling)

**For parents - child safety:**
Not relevant for children as it's only in alcoholic products

**Who should be extra careful:**
Vegetarians, vegans, people with fish allergies, those avoiding animal products

**Health impact summary:**
Usually removed during production but traces may remain

**What you can do:**
Look for vegan-certified alcoholic drinks or those filtered with plant-based alternatives

**UK regulatory notes:**
Not required to be listed as ingredient since it's typically removed during processing`,
            effects_verdict: 'neutral',
            synonyms: ['fish finings', 'fish bladder'],
            matches: ['isinglass', 'fish finings'],
            sources: []
        },
        // CONTROVERSIAL PRESERVATIVES
        'E320': {
            code: 'E320',
            name: 'Butylated hydroxyanisole (BHA)',
            category: 'antioxidant',
            permitted_GB: true,
            permitted_NI: true,
            permitted_EU: true,
            status_notes: 'Controversial preservative, possible carcinogen',
            child_warning: true,
            PKU_warning: false,
            polyols_warning: false,
            sulphites_allergen_label: false,
            origin: 'synthetic',
            consumer_guide: `**What is it?**
BHA - synthetic antioxidant that prevents oils from going rancid

**Why is it added to food?**
Extends shelf life by preventing fats and oils from spoiling

**Found in these foods:**
Breakfast cereals, snack foods, processed meats, chewing gum, cosmetics

**For parents - child safety:**
⚠️ CAUTION: Classified as possible carcinogen - limit children's exposure

**Who should be extra careful:**
Pregnant women, children, people concerned about potential cancer risks

**Health impact summary:**
Possible carcinogen according to WHO - many countries restrict its use

**What you can do:**
Choose products with natural antioxidants like vitamin E (tocopherols) instead

**UK regulatory notes:**
Still legal but many manufacturers voluntarily removing due to health concerns`,
            effects_verdict: 'caution',
            synonyms: ['BHA', 'butylated hydroxyanisole'],
            matches: ['bha', 'butylated hydroxyanisole'],
            sources: []
        },
        'E321': {
            code: 'E321',
            name: 'Butylated hydroxytoluene (BHT)',
            category: 'antioxidant',
            permitted_GB: true,
            permitted_NI: true,
            permitted_EU: true,
            status_notes: 'Controversial preservative, health concerns',
            child_warning: true,
            PKU_warning: false,
            polyols_warning: false,
            sulphites_allergen_label: false,
            origin: 'synthetic',
            consumer_guide: `**What is it?**
BHT - synthetic antioxidant similar to BHA, prevents rancidity

**Why is it added to food?**
Prevents fats and oils from spoiling, extends product shelf life

**Found in these foods:**
Cereals, snacks, processed foods, cosmetics, rubber products

**For parents - child safety:**
⚠️ CAUTION: Potential health risks - some studies suggest liver effects

**Who should be extra careful:**
Children, pregnant women, people with liver conditions

**Health impact summary:**
Some studies suggest potential liver and kidney effects with high consumption

**What you can do:**
Choose products with natural preservatives or shorter ingredient lists

**UK regulatory notes:**
Legal but increasingly avoided by health-conscious manufacturers`,
            effects_verdict: 'caution',
            synonyms: ['BHT', 'butylated hydroxytoluene'],
            matches: ['bht', 'butylated hydroxytoluene'],
            sources: []
        },
        // MSG AND VARIANTS
        'E621': {
            code: 'E621',
            name: 'Monosodium glutamate (MSG)',
            category: 'flavour enhancer',
            permitted_GB: true,
            permitted_NI: true,
            permitted_EU: true,
            status_notes: 'Controversial flavor enhancer',
            child_warning: false,
            PKU_warning: false,
            polyols_warning: false,
            sulphites_allergen_label: false,
            origin: 'synthetic',
            consumer_guide: `**What is it?**
MSG - flavor enhancer that makes food taste more savory and intense

**Why is it added to food?**
Enhances umami (savory) flavor, makes processed foods taste better

**Found in these foods:**
Chinese takeaway, processed meats, snacks, soups, restaurant food

**For parents - child safety:**
Generally safe but some children may be sensitive to large amounts

**Who should be extra careful:**
People who experience headaches or sensitivity after eating certain foods

**Health impact summary:**
Generally recognized as safe but some people report sensitivity reactions

**What you can do:**
Try avoiding it if you notice headaches or reactions after meals

**UK regulatory notes:**
Must be clearly labeled - often hidden in "natural flavoring"`,
            effects_verdict: 'neutral',
            synonyms: ['MSG', 'monosodium glutamate', 'sodium glutamate'],
            matches: ['msg', 'monosodium glutamate', 'flavour enhancer'],
            sources: []
        },
        'E471': {
            code: 'E471',
            name: 'Mono- and diglycerides of fatty acids',
            category: 'emulsifier',
            permitted_GB: true,
            permitted_NI: true,
            permitted_EU: true,
            status_notes: 'Common emulsifier',
            child_warning: false,
            PKU_warning: false,
            polyols_warning: false,
            sulphites_allergen_label: false,
            origin: 'synthetic',
            consumer_guide: `**What is it?**
Mono- and diglycerides of fatty acids - synthetic emulsifier that helps mix oil and water

**Why is it added to food?**
Makes textures smooth and creamy by binding ingredients that normally separate

**Found in these foods:**
Chocolate, ice cream, bread, spreads, margarine, cakes

**For parents - child safety:**
No specific risks for children, but ultra-smooth textures may encourage overeating

**Who should be extra careful:**
People with digestive sensitivities or those trying to eat less processed foods

**Health impact summary:**
Generally safe but some people report gut sensitivity to emulsifiers

**What you can do:**
If you notice digestive issues, try foods with fewer emulsifiers or simpler ingredient lists

**UK regulatory notes:**
Widely approved and regulated - limits apply depending on food type`,
            effects_verdict: 'neutral',
            synonyms: ['mono- and diglycerides', 'monoglycerides', 'diglycerides'],
            matches: ['emulsifier', 'mono-', 'diglycerides'],
            sources: []
        },
        // HIDDEN ALLERGEN SOURCES
        'LECITHIN': {
            code: 'LECITHIN',
            name: 'Lecithin',
            category: 'emulsifier',
            permitted_GB: true,
            permitted_NI: true,
            permitted_EU: true,
            status_notes: 'Often from soy, may contain traces of allergens',
            child_warning: false,
            PKU_warning: false,
            polyols_warning: false,
            sulphites_allergen_label: false,
            origin: 'plant/animal',
            consumer_guide: `**What is it?**
Lecithin - natural emulsifier usually from soy, sunflower, or eggs

**Why is it added to food?**
Helps mix ingredients that normally separate, improves texture

**Found in these foods:**
Chocolate, baked goods, margarine, salad dressings, supplements

**For parents - child safety:**
Safe but check source if child has soy or egg allergies

**Who should be extra careful:**
People with soy allergies, egg allergies, those avoiding GMO soy

**Health impact summary:**
Generally safe and natural, but allergen source matters

**What you can do:**
Look for "sunflower lecithin" if avoiding soy, or check allergen warnings

**UK regulatory notes:**
Source must be declared if from major allergens like soy or egg`,
            effects_verdict: 'neutral',
            synonyms: ['soy lecithin', 'soya lecithin', 'sunflower lecithin', 'egg lecithin'],
            matches: ['lecithin', 'soy lecithin', 'soya lecithin'],
            sources: []
        },
        'CASEIN': {
            code: 'CASEIN',
            name: 'Casein',
            category: 'protein',
            permitted_GB: true,
            permitted_NI: true,
            permitted_EU: true,
            status_notes: 'Milk protein - hidden dairy allergen',
            child_warning: false,
            PKU_warning: false,
            polyols_warning: false,
            sulphites_allergen_label: false,
            origin: 'dairy',
            consumer_guide: `**What is it?**
Casein - protein from milk, often found in "dairy-free" products

**Why is it added to food?**
Improves protein content, texture, and binding properties

**Found in these foods:**
Some "non-dairy" creamers, protein bars, processed meats, "vegan" cheese

**For parents - child safety:**
⚠️ HIDDEN DAIRY: Can trigger reactions in milk-allergic children

**Who should be extra careful:**
People with milk allergies, lactose intolerant individuals, vegans

**Health impact summary:**
Safe protein but contains milk allergen - can be seriously hidden

**What you can do:**
Always check ingredients even in "dairy-free" products - look for casein, caseinate

**UK regulatory notes:**
Must be declared as milk allergen even in small amounts`,
            effects_verdict: 'neutral',
            synonyms: ['sodium caseinate', 'calcium caseinate', 'milk protein'],
            matches: ['casein', 'caseinate', 'milk protein'],
            sources: []
        },
        // SULFITES - MAJOR ALLERGEN
        'E220': {
            code: 'E220',
            name: 'Sulphur dioxide',
            category: 'preservative',
            permitted_GB: true,
            permitted_NI: true,
            permitted_EU: true,
            status_notes: 'Sulfite allergen - can trigger severe reactions',
            child_warning: false,
            PKU_warning: false,
            polyols_warning: false,
            sulphites_allergen_label: true,
            origin: 'synthetic',
            consumer_guide: `**What is it?**
Sulphur dioxide - preservative gas that prevents browning and bacterial growth

**Why is it added to food?**
Keeps dried fruits looking fresh, prevents wine from spoiling

**Found in these foods:**
Dried fruits, wine, fruit juices, some medications, processed potatoes

**For parents - child safety:**
⚠️ ALLERGEN WARNING: Can cause severe breathing problems in sensitive children

**Who should be extra careful:**
Asthmatics, people with breathing problems, sulfite-sensitive individuals

**Health impact summary:**
Major allergen - can trigger severe asthma attacks and breathing difficulties

**What you can do:**
Check labels carefully, choose unsulfited dried fruits, ask about restaurant food

**UK regulatory notes:**
Must be clearly labeled - restaurants must declare if used above certain levels`,
            effects_verdict: 'caution',
            synonyms: ['sulphur dioxide', 'sulfur dioxide', 'sulfites'],
            matches: ['sulphur dioxide', 'sulfur dioxide', 'sulfites', 'sulphites'],
            sources: []
        },
        'E223': {
            code: 'E223',
            name: 'Sodium metabisulphite',
            category: 'preservative',
            permitted_GB: true,
            permitted_NI: true,
            permitted_EU: true,
            status_notes: 'Sulfite allergen - hidden in many foods',
            child_warning: false,
            PKU_warning: false,
            polyols_warning: false,
            sulphites_allergen_label: true,
            origin: 'synthetic',
            consumer_guide: `**What is it?**
Sodium metabisulphite - sulfite preservative that releases sulfur dioxide

**Why is it added to food?**
Prevents browning, extends shelf life, maintains color in processed foods

**Found in these foods:**
Sausages, burgers, dried vegetables, fruit preparations, some beers

**For parents - child safety:**
⚠️ ALLERGEN WARNING: Can trigger severe reactions in sensitive children

**Who should be extra careful:**
Asthmatics, people with sulfite sensitivity, those with breathing problems

**Health impact summary:**
Major allergen - can cause severe breathing difficulties and reactions

**What you can do:**
Read labels carefully, avoid if sensitive, choose sulfite-free alternatives

**UK regulatory notes:**
Must be declared - look for "contains sulfites" warning on labels`,
            effects_verdict: 'caution',
            synonyms: ['sodium metabisulphite', 'sodium metabisulfite'],
            matches: ['metabisulphite', 'metabisulfite', 'sulfites'],
            sources: []
        },
        // NITRATES AND NITRITES
        'E250': {
            code: 'E250',
            name: 'Sodium nitrite',
            category: 'preservative',
            permitted_GB: true,
            permitted_NI: true,
            permitted_EU: true,
            status_notes: 'Controversial preservative - cancer concerns',
            child_warning: true,
            PKU_warning: false,
            polyols_warning: false,
            sulphites_allergen_label: false,
            origin: 'synthetic',
            consumer_guide: `**What is it?**
Sodium nitrite - preservative that keeps processed meats pink and prevents botulism

**Why is it added to food?**
Prevents deadly botulism bacteria, maintains appetizing color in cured meats

**Found in these foods:**
Bacon, ham, sausages, hot dogs, cured meats, some cheeses

**For parents - child safety:**
⚠️ CAUTION: Linked to increased cancer risk, especially in processed meats

**Who should be extra careful:**
Children, pregnant women, people concerned about cancer risk

**Health impact summary:**
May form cancer-causing nitrosamines when heated - WHO lists processed meat as carcinogenic

**What you can do:**
Limit processed meat consumption, choose nitrite-free alternatives when possible

**UK regulatory notes:**
Legal and necessary for food safety, but health agencies recommend limiting processed meat`,
            effects_verdict: 'caution',
            synonyms: ['sodium nitrite', 'nitrite'],
            matches: ['sodium nitrite', 'nitrite'],
            sources: []
        },
        'E251': {
            code: 'E251',
            name: 'Sodium nitrate',
            category: 'preservative',
            permitted_GB: true,
            permitted_NI: true,
            permitted_EU: true,
            status_notes: 'Converts to nitrite in body - cancer concerns',
            child_warning: true,
            PKU_warning: false,
            polyols_warning: false,
            sulphites_allergen_label: false,
            origin: 'synthetic',
            consumer_guide: `**What is it?**
Sodium nitrate - preservative that converts to nitrite in your body

**Why is it added to food?**
Long-term preservation of cured meats, prevents bacterial growth

**Found in these foods:**
Cured meats, bacon, some cheeses, occasionally in vegetables

**For parents - child safety:**
⚠️ CAUTION: Converts to nitrite which may increase cancer risk

**Who should be extra careful:**
Children, pregnant women, people limiting processed food intake

**Health impact summary:**
May contribute to cancer risk through nitrite conversion - similar concerns to E250

**What you can do:**
Choose fresh meats over processed, limit cured meat consumption

**UK regulatory notes:**
Legal but health agencies recommend limiting processed meat consumption`,
            effects_verdict: 'caution',
            synonyms: ['sodium nitrate', 'nitrate'],
            matches: ['sodium nitrate', 'nitrate'],
            sources: []
        },
        // HIDDEN GLUTEN SOURCES
        'MALTODEXTRIN': {
            code: 'MALTODEXTRIN',
            name: 'Maltodextrin',
            category: 'thickener',
            permitted_GB: true,
            permitted_NI: true,
            permitted_EU: true,
            status_notes: 'May contain traces of gluten depending on source',
            child_warning: false,
            PKU_warning: false,
            polyols_warning: false,
            sulphites_allergen_label: false,
            origin: 'plant',
            consumer_guide: `**What is it?**
Maltodextrin - processed starch that can come from wheat, corn, or potatoes

**Why is it added to food?**
Thickens foods, adds bulk, improves texture and shelf life

**Found in these foods:**
Sports drinks, processed snacks, instant foods, artificial sweeteners

**For parents - child safety:**
Generally safe but check source if child has celiac disease

**Who should be extra careful:**
People with celiac disease or gluten sensitivity - wheat-derived maltodextrin contains gluten

**Health impact summary:**
Safe ingredient but gluten source matters for sensitive individuals

**What you can do:**
Contact manufacturers to confirm source if you have celiac disease

**UK regulatory notes:**
If wheat-derived, must be declared as containing gluten`,
            effects_verdict: 'neutral',
            synonyms: ['maltodextrin', 'modified starch'],
            matches: ['maltodextrin', 'modified starch'],
            sources: []
        },
        // ANIMAL ENZYMES (often unexpected)
        'RENNET': {
            code: 'RENNET',
            name: 'Rennet',
            category: 'enzyme',
            permitted_GB: true,
            permitted_NI: true,
            permitted_EU: true,
            status_notes: 'Often from calf stomach lining - unexpected animal product',
            child_warning: false,
            PKU_warning: false,
            polyols_warning: false,
            sulphites_allergen_label: false,
            origin: 'animal',
            consumer_guide: `**What is it?**
Rennet - enzyme traditionally from calf stomach lining, used to curdle milk for cheese

**Why is it added to food?**
Essential for cheese-making - helps milk proteins coagulate into curds

**Found in these foods:**
Most traditional cheeses, some processed cheese products

**For parents - child safety:**
Safe but many people don't realize cheese contains stomach lining enzymes

**Who should be extra careful:**
Vegetarians, people avoiding animal products for religious reasons

**Health impact summary:**
Safe and natural but many people prefer vegetable or microbial rennet

**What you can do:**
Look for "vegetarian cheese" or "microbial rennet" on labels

**UK regulatory notes:**
Often just listed as "rennet" without specifying animal or vegetable source`,
            effects_verdict: 'neutral',
            synonyms: ['animal rennet', 'calf rennet', 'microbial rennet'],
            matches: ['rennet', 'animal rennet', 'calf rennet'],
            sources: []
        },
        // PALM OIL (often hidden as "vegetable oil")
        'PALM_OIL': {
            code: 'PALM_OIL',
            name: 'Palm oil',
            category: 'fat',
            permitted_GB: true,
            permitted_NI: true,
            permitted_EU: true,
            status_notes: 'Environmental concerns, often hidden as "vegetable oil"',
            child_warning: false,
            PKU_warning: false,
            polyols_warning: false,
            sulphites_allergen_label: false,
            origin: 'plant',
            consumer_guide: `**What is it?**
Palm oil - oil from oil palm fruit, often hidden under "vegetable oil" label

**Why is it added to food?**
Cheap, stable oil that extends shelf life and improves texture

**Found in these foods:**
Biscuits, margarine, chocolate, instant noodles, many processed foods

**For parents - child safety:**
Safe for consumption but environmental impact concerns

**Who should be extra careful:**
Environmentally conscious consumers, people avoiding unsustainable ingredients

**Health impact summary:**
Safe to eat but major cause of deforestation and habitat destruction

**What you can do:**
Look for "sustainable palm oil" certification or palm-oil-free alternatives

**UK regulatory notes:**
Must be specifically labeled as "palm oil" since 2014 - no longer hidden as "vegetable oil"`,
            effects_verdict: 'neutral',
            synonyms: ['palm oil', 'palm kernel oil', 'vegetable oil'],
            matches: ['palm oil', 'palm kernel oil'],
            sources: []
        },
        'E102': {
            code: 'E102',
            name: 'Tartrazine',
            category: 'colour',
            permitted_GB: true,
            permitted_NI: true,
            permitted_EU: true,
            status_notes: 'Synthetic azo dye with behaviour warning',
            child_warning: true,
            PKU_warning: false,
            polyols_warning: false,
            sulphites_allergen_label: false,
            origin: 'synthetic',
            consumer_guide: `**What is it?**
Tartrazine - bright yellow synthetic food dye made from petroleum derivatives

**Why is it added to food?**
Makes foods look more appealing with bright yellow color - purely cosmetic

**Found in these foods:**
Soft drinks, sweets, flavoured snacks, some medications, processed cheese

**For parents - child safety:**
⚠️ WARNING: May affect activity and attention in children - linked to hyperactivity

**Who should be extra careful:**
Children with ADHD, anyone sensitive to artificial colors, people with asthma

**Health impact summary:**
Linked to hyperactivity and behavioral changes in some children, may trigger allergic reactions

**What you can do:**
Check labels carefully - choose naturally colored alternatives, especially for children's foods

**UK regulatory notes:**
Must be labeled clearly - products containing it must carry hyperactivity warnings`,
            effects_verdict: 'caution',
            synonyms: ['tartrazine', 'yellow 5', 'fd&c yellow 5'],
            matches: ['tartrazine', 'yellow'],
            sources: []
        },
        'E282': {
            code: 'E282',
            name: 'Calcium propionate',
            category: 'preservative',
            permitted_GB: true,
            permitted_NI: true,
            permitted_EU: true,
            status_notes: 'Common bread preservative',
            child_warning: false,
            PKU_warning: false,
            polyols_warning: false,
            sulphites_allergen_label: false,
            origin: 'synthetic',
            consumer_guide: `**What is it?**
Calcium propionate - synthetic preservative that prevents mold growth

**Why is it added to food?**
Extends shelf life by stopping mold and bacteria from growing in baked goods

**Found in these foods:**
Bread, rolls, bakery products, some processed foods

**For parents - child safety:**
Generally safe for children - helps prevent dangerous mold in bread

**Who should be extra careful:**
People with severe chemical sensitivities (rare)

**Health impact summary:**
Generally safe preservative - much safer than moldy bread!

**What you can do:**
Normal consumption is safe - choose fresh bread when possible, freeze bread to avoid preservatives

**UK regulatory notes:**
Widely approved as safe and effective mold inhibitor`,
            effects_verdict: 'neutral',
            synonyms: ['calcium propionate'],
            matches: ['preservative'],
            sources: []
        },
        'E300': {
            code: 'E300',
            name: 'Ascorbic acid',
            category: 'antioxidant',
            permitted_GB: true,
            permitted_NI: true,
            permitted_EU: true,
            status_notes: 'Vitamin C, natural antioxidant',
            child_warning: false,
            PKU_warning: false,
            polyols_warning: false,
            sulphites_allergen_label: false,
            origin: 'natural/synthetic',
            consumer_guide: `**What is it?**
Ascorbic acid - this is Vitamin C! Essential nutrient your body needs

**Why is it added to food?**
Prevents foods from going brown, keeps them fresh, and adds nutritional value

**Found in these foods:**
Flour products, preserved fruits, fruit juices, breakfast cereals

**For parents - child safety:**
✅ EXCELLENT for children - essential vitamin they need for healthy growth

**Who should be extra careful:**
Nobody - this is beneficial for everyone

**Health impact summary:**
This is an essential vitamin! Supports immune system, helps heal wounds, prevents scurvy

**What you can do:**
This is actually a good thing to see on labels - means added nutritional value

**UK regulatory notes:**
Recognized as both safe additive and essential nutrient`,
            effects_verdict: 'neutral',
            synonyms: ['ascorbic acid', 'vitamin c'],
            matches: ['antioxidant', 'ascorbic'],
            sources: []
        },
        'E171': {
            code: 'E171',
            name: 'Titanium Dioxide',
            category: 'colour',
            permitted_GB: true,
            permitted_NI: false,
            permitted_EU: false,
            status_notes: 'Banned in EU/NI since 2022; remains authorized in GB',
            child_warning: false,
            PKU_warning: false,
            polyols_warning: false,
            sulphites_allergen_label: false,
            origin: 'mineral',
            consumer_guide: `**What is it?**
Titanium dioxide - white mineral powder used to make foods look whiter and brighter

**Why is it added to food?**
Purely cosmetic - makes sweets, icing, and tablets look more appealing with bright white color

**Found in these foods:**
White sweets, icing, chewing gum, tablet coatings, some sauces

**For parents - child safety:**
🚨 AVOID for children - EU banned it in 2022 due to potential DNA damage concerns

**Who should be extra careful:**
Pregnant women, children, and anyone concerned about potential carcinogens

**Health impact summary:**
EU banned in 2022 over concerns it may damage DNA and cause cancer

**What you can do:**
Read labels carefully - choose products without E171, especially for children

**UK regulatory notes:**
🇬🇧 Still legal in UK despite EU ban - many UK manufacturers voluntarily removing it`,
            effects_verdict: 'avoid',
            synonyms: ['Titanium dioxide', 'TiO2'],
            matches: ['titanium dioxide', 'tio2'],
            sources: []
        }
    };
}
function loadDefaultProcessingRules() {
    PROCESSING_RULES = {
        version: 'default-v1',
        score_to_grade: [
            { max: 9, grade: 'A', label: 'Minimal processing' },
            { min: 10, max: 19, grade: 'B', label: 'Low processing' },
            { min: 20, max: 34, grade: 'C', label: 'Some processing' },
            { min: 35, max: 49, grade: 'D', label: 'Heavily processed' },
            { min: 50, max: 69, grade: 'E', label: 'Highly processed' },
            { min: 70, grade: 'F', label: 'Ultra processed / red-flag' }
        ],
        red_flags: ['E924A', 'E171'],
        category_weights_notes: {
            colours: { role_contains: 'colour', baseline: 6, azo_extra: 12, azo_ids: ['E102', 'E104', 'E110', 'E122', 'E124', 'E129'], weight: 6 },
            preservatives: { role_contains: 'preservative', weight: 8 },
            sweeteners: { weight: 10 }
        },
        how_to_use: 'Deduplicate additive IDs per product; sum weights; if red flags present, grade F; else map to thresholds.'
    };
}
// Enhanced additive analysis function
exports.analyzeAdditivesEnhanced = functions.https.onRequest(async (req, res) => {
    // Load database if not already loaded
    loadAdditiveDatabase();
    // Set CORS headers
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    if (req.method === 'OPTIONS') {
        res.status(200).send();
        return;
    }
    if (req.method !== 'POST') {
        res.status(405).json({ error: 'Method not allowed' });
        return;
    }
    try {
        const { ingredients } = req.body;
        if (!ingredients || typeof ingredients !== 'string') {
            res.status(400).json({ error: 'ingredients string required' });
            return;
        }
        // Analyze ingredients text for additives
        const analysisResult = analyzeIngredientsForAdditives(ingredients);
        // Calculate processing score using the comprehensive rules
        const processingScore = calculateProcessingScore(analysisResult.detectedAdditives, ingredients);
        // Determine overall grade
        const grade = determineGrade(processingScore.totalScore, analysisResult.hasRedFlags);
        // Transform additives to match iOS app expectations (map consumer_guide to consumerInfo)
        const transformedAdditives = analysisResult.detectedAdditives.map(additive => (Object.assign(Object.assign({}, additive), { consumerInfo: additive.consumer_guide })));
        const response = {
            success: true,
            additives: transformedAdditives,
            processing: {
                score: processingScore.totalScore,
                grade: grade.grade,
                label: grade.label,
                breakdown: processingScore.breakdown
            },
            warnings: {
                children: analysisResult.childWarnings,
                pku: analysisResult.pkuWarnings,
                sulphites: analysisResult.sulphiteWarnings,
                polyols: analysisResult.polyolWarnings,
                regulatory: analysisResult.regulatoryWarnings
            },
            riskAssessment: {
                overall: analysisResult.overallRisk,
                explanation: analysisResult.riskExplanation,
                hasRedFlags: analysisResult.hasRedFlags
            },
            metadata: {
                totalAdditives: analysisResult.detectedAdditives.length,
                confidence: analysisResult.confidence,
                databaseVersion: PROCESSING_RULES.version
            }
        };
        console.log(`🔬 Enhanced additive analysis: ${analysisResult.detectedAdditives.length} additives detected, score: ${processingScore.totalScore}, grade: ${grade.grade}`);
        res.status(200).json(response);
    }
    catch (error) {
        console.error('❌ Enhanced additive analysis error:', error);
        res.status(500).json({
            success: false,
            error: 'Internal server error',
            details: error.message
        });
    }
});
function analyzeIngredientsForAdditives(ingredients) {
    const text = ingredients.toLowerCase();
    const detectedAdditives = [];
    const foundCodes = new Set();
    // Search for E-numbers (E100, E102, etc.)
    const eNumberRegex = /e\d{3,4}[a-z]?/gi;
    const eNumbers = text.match(eNumberRegex) || [];
    for (const eNumber of eNumbers) {
        const upperENumber = eNumber.toUpperCase();
        if (COMPREHENSIVE_ADDITIVES_DB[upperENumber] && !foundCodes.has(upperENumber)) {
            detectedAdditives.push(COMPREHENSIVE_ADDITIVES_DB[upperENumber]);
            foundCodes.add(upperENumber);
        }
    }
    // Search by common names and synonyms
    for (const [, additive] of Object.entries(COMPREHENSIVE_ADDITIVES_DB)) {
        if (foundCodes.has(additive.code))
            continue; // Use additive.code instead of code to avoid duplicate aliases
        // Check main name
        if (text.includes(additive.name.toLowerCase())) {
            detectedAdditives.push(additive);
            foundCodes.add(additive.code);
            continue;
        }
        // Check synonyms and matches with flexible matching
        const searchTerms = [...additive.synonyms, ...additive.matches];
        for (const term of searchTerms) {
            if (term && text.includes(term.toLowerCase())) {
                detectedAdditives.push(additive);
                foundCodes.add(additive.code);
                break;
            }
        }
        // Special flexible matching for common additives (more precise)
        if (!foundCodes.has(additive.code)) {
            // Lecithin matching (E322) - specific patterns only
            if (additive.code === 'E322' && (text.includes('lecithin') ||
                text.includes('soya lecithin') ||
                text.includes('soy lecithin') ||
                text.includes('sunflower lecithin') ||
                text.includes('egg lecithin'))) {
                detectedAdditives.push(additive);
                foundCodes.add(additive.code);
            }
        }
    }
    // Analyze warnings and risks
    const childWarnings = detectedAdditives
        .filter(a => a.child_warning)
        .map(a => `${a.code} (${a.name}): May affect activity and attention in children`);
    const pkuWarnings = detectedAdditives
        .filter(a => a.PKU_warning)
        .map(a => `${a.code} (${a.name}): Not suitable for people with phenylketonuria (PKU)`);
    const sulphiteWarnings = detectedAdditives
        .filter(a => a.sulphites_allergen_label)
        .map(a => `${a.code} (${a.name}): Contains sulphites - may cause reactions in sensitive individuals`);
    const polyolWarnings = detectedAdditives
        .filter(a => a.polyols_warning)
        .map(a => `${a.code} (${a.name}): May have laxative effects if consumed in excess`);
    const regulatoryWarnings = detectedAdditives
        .filter(a => !a.permitted_EU || !a.permitted_NI)
        .map(a => {
        const restrictions = [];
        if (!a.permitted_EU)
            restrictions.push('EU');
        if (!a.permitted_NI)
            restrictions.push('Northern Ireland');
        return `${a.code} (${a.name}): Not permitted in ${restrictions.join(', ')}${a.status_notes ? ` - ${a.status_notes}` : ''}`;
    });
    // Check for red flag additives
    const hasRedFlags = detectedAdditives.some(a => PROCESSING_RULES.red_flags.includes(a.code));
    // Calculate overall risk
    const avoidCount = detectedAdditives.filter(a => a.effects_verdict === 'avoid').length;
    const cautionCount = detectedAdditives.filter(a => a.effects_verdict === 'caution').length;
    let overallRisk = 'LOW';
    let riskExplanation = 'Contains only low-risk or generally safe additives.';
    if (hasRedFlags || avoidCount > 0) {
        overallRisk = 'HIGH';
        riskExplanation = `Contains ${avoidCount > 0 ? `${avoidCount} avoid-level` : 'red-flag'} additive(s). Consider alternatives.`;
    }
    else if (cautionCount >= 3) {
        overallRisk = 'HIGH';
        riskExplanation = `Contains ${cautionCount} caution-level additives. High processing level.`;
    }
    else if (cautionCount > 0) {
        overallRisk = 'MEDIUM';
        riskExplanation = `Contains ${cautionCount} additive(s) requiring caution, especially for sensitive individuals.`;
    }
    // Calculate confidence based on detection method
    let confidence = 0.8;
    if (eNumbers.length > 0)
        confidence += 0.1; // E-numbers are very reliable
    if (detectedAdditives.length === 0)
        confidence = 0.9; // High confidence in no additives
    return {
        detectedAdditives: detectedAdditives.sort((a, b) => a.code.localeCompare(b.code)),
        childWarnings,
        pkuWarnings,
        sulphiteWarnings,
        polyolWarnings,
        regulatoryWarnings,
        hasRedFlags,
        overallRisk,
        riskExplanation,
        confidence: Math.min(confidence, 1.0)
    };
}
function calculateProcessingScore(additives, ingredientsText) {
    const breakdown = {};
    let totalScore = 0;
    // Get unique additives by code to avoid double-counting
    const uniqueAdditives = additives.filter((additive, index, self) => index === self.findIndex(a => a.code === additive.code));
    // Process each category in the rules
    for (const [categoryName, rules] of Object.entries(PROCESSING_RULES.category_weights_notes)) {
        const categoryAdditives = [];
        const ingredientMatches = [];
        // Check additives
        for (const additive of uniqueAdditives) {
            let matches = false;
            // Check by specific IDs
            if (rules.ids && rules.ids.includes(additive.code)) {
                matches = true;
            }
            // Check by ID prefix
            if (!matches && rules.ids_prefix) {
                for (const prefix of rules.ids_prefix) {
                    if (additive.code.startsWith(prefix)) {
                        matches = true;
                        break;
                    }
                }
            }
            // Check by role/category contains
            if (!matches && rules.role_contains && additive.category.includes(rules.role_contains)) {
                matches = true;
            }
            if (matches) {
                categoryAdditives.push(additive);
            }
        }
        // NEW: Check ingredients text for ultra-processed indicators
        if (rules.ingredient_names) {
            const lowerIngredients = ingredientsText.toLowerCase();
            for (const ingredient of rules.ingredient_names) {
                if (lowerIngredients.includes(ingredient.toLowerCase())) {
                    ingredientMatches.push(ingredient);
                }
            }
        }
        // NEW: Check US color names
        if (rules.us_color_names) {
            const lowerIngredients = ingredientsText.toLowerCase();
            for (const colorName of rules.us_color_names) {
                if (lowerIngredients.includes(colorName.toLowerCase())) {
                    ingredientMatches.push(colorName);
                }
            }
        }
        const totalMatches = categoryAdditives.length + ingredientMatches.length;
        if (totalMatches > 0) {
            let categoryScore = rules.baseline || rules.weight;
            // Apply special rules for colors (azo dyes get extra weight)
            if (categoryName === 'colours' && rules.azo_ids) {
                const azoCount = categoryAdditives.filter(a => rules.azo_ids.includes(a.code)).length;
                if (azoCount > 0 && rules.azo_extra) {
                    categoryScore += rules.azo_extra;
                }
                // Apply multiple color penalty for 2+ colors
                if (totalMatches >= 2 && rules.multiple_color_penalty) {
                    categoryScore += rules.multiple_color_penalty * (totalMatches - 1);
                }
            }
            // Apply multiple penalty for sugar categories
            if (categoryName === 'multiple_sugars_penalty' && totalMatches >= 2 && rules.multiple_penalty) {
                categoryScore += rules.multiple_penalty;
            }
            // Calculate final score
            let finalScore = categoryScore;
            if (totalMatches > 1) {
                finalScore = categoryScore + (rules.weight || 5) * (totalMatches - 1);
            }
            totalScore += finalScore;
            breakdown[categoryName] = {
                count: totalMatches,
                score: finalScore,
                details: [
                    ...categoryAdditives.map(a => `${a.code} (${a.name})`),
                    ...ingredientMatches.map(i => `${i} (ingredient)`)
                ]
            };
        }
    }
    return { totalScore, breakdown };
}
function determineGrade(totalScore, hasRedFlags) {
    // Red flags automatically result in F grade
    if (hasRedFlags) {
        return { grade: 'F', label: 'Ultra processed / red-flag' };
    }
    // Find the appropriate grade based on score thresholds
    for (const threshold of PROCESSING_RULES.score_to_grade) {
        const meetsMin = !threshold.min || totalScore >= threshold.min;
        const meetsMax = !threshold.max || totalScore <= threshold.max;
        if (meetsMin && meetsMax) {
            return { grade: threshold.grade, label: threshold.label };
        }
    }
    // Default to F if no threshold matched
    return { grade: 'F', label: 'Ultra processed / red-flag' };
}
//# sourceMappingURL=additive-analyzer-enhanced.js.map