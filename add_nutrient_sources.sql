-- Create nutrient_sources table
CREATE TABLE IF NOT EXISTS nutrient_sources (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    nutrient TEXT NOT NULL,
    title TEXT NOT NULL,
    url TEXT NOT NULL,
    FOREIGN KEY (nutrient) REFERENCES nutrient_info(nutrient)
);

-- Insert sources for each nutrient
-- Vitamins
INSERT INTO nutrient_sources (nutrient, title, url) VALUES
('Vitamin_A', 'Vitamin A - NIH Office of Dietary Supplements', 'https://ods.od.nih.gov/factsheets/VitaminA-Consumer/'),
('Vitamin_A', 'Vitamin A - NHS', 'https://www.nhs.uk/conditions/vitamins-and-minerals/vitamin-a/'),
('Beta_Carotene', 'Beta-Carotene - NIH Office of Dietary Supplements', 'https://ods.od.nih.gov/factsheets/VitaminA-Consumer/'),

('Thiamin_B1', 'Thiamin (B1) - NIH Office of Dietary Supplements', 'https://ods.od.nih.gov/factsheets/Thiamin-Consumer/'),
('Thiamin_B1', 'B vitamins and folic acid - NHS', 'https://www.nhs.uk/conditions/vitamins-and-minerals/vitamin-b/'),

('Riboflavin_B2', 'Riboflavin (B2) - NIH Office of Dietary Supplements', 'https://ods.od.nih.gov/factsheets/Riboflavin-Consumer/'),
('Riboflavin_B2', 'B vitamins and folic acid - NHS', 'https://www.nhs.uk/conditions/vitamins-and-minerals/vitamin-b/'),

('Niacin_B3', 'Niacin (B3) - NIH Office of Dietary Supplements', 'https://ods.od.nih.gov/factsheets/Niacin-Consumer/'),
('Niacin_B3', 'B vitamins and folic acid - NHS', 'https://www.nhs.uk/conditions/vitamins-and-minerals/vitamin-b/'),

('Pantothenic_B5', 'Pantothenic Acid (B5) - NIH Office of Dietary Supplements', 'https://ods.od.nih.gov/factsheets/PantothenicAcid-Consumer/'),
('Pantothenic_B5', 'B vitamins and folic acid - NHS', 'https://www.nhs.uk/conditions/vitamins-and-minerals/vitamin-b/'),

('Vitamin_B6', 'Vitamin B6 - NIH Office of Dietary Supplements', 'https://ods.od.nih.gov/factsheets/VitaminB6-Consumer/'),
('Vitamin_B6', 'B vitamins and folic acid - NHS', 'https://www.nhs.uk/conditions/vitamins-and-minerals/vitamin-b/'),

('Biotin_B7', 'Biotin (B7) - NIH Office of Dietary Supplements', 'https://ods.od.nih.gov/factsheets/Biotin-Consumer/'),
('Biotin_B7', 'B vitamins and folic acid - NHS', 'https://www.nhs.uk/conditions/vitamins-and-minerals/vitamin-b/'),

('Folate_B9', 'Folate (B9) - NIH Office of Dietary Supplements', 'https://ods.od.nih.gov/factsheets/Folate-Consumer/'),
('Folate_B9', 'B vitamins and folic acid - NHS', 'https://www.nhs.uk/conditions/vitamins-and-minerals/vitamin-b/'),

('Vitamin_B12', 'Vitamin B12 - NIH Office of Dietary Supplements', 'https://ods.od.nih.gov/factsheets/VitaminB12-Consumer/'),
('Vitamin_B12', 'B vitamins and folic acid - NHS', 'https://www.nhs.uk/conditions/vitamins-and-minerals/vitamin-b/'),

('Vitamin_C', 'Vitamin C - NIH Office of Dietary Supplements', 'https://ods.od.nih.gov/factsheets/VitaminC-Consumer/'),
('Vitamin_C', 'Vitamin C - NHS', 'https://www.nhs.uk/conditions/vitamins-and-minerals/vitamin-c/'),

('Vitamin_D', 'Vitamin D - NIH Office of Dietary Supplements', 'https://ods.od.nih.gov/factsheets/VitaminD-Consumer/'),
('Vitamin_D', 'Vitamin D - NHS', 'https://www.nhs.uk/conditions/vitamins-and-minerals/vitamin-d/'),

('Vitamin_E', 'Vitamin E - NIH Office of Dietary Supplements', 'https://ods.od.nih.gov/factsheets/VitaminE-Consumer/'),
('Vitamin_E', 'Vitamin E - NHS', 'https://www.nhs.uk/conditions/vitamins-and-minerals/vitamin-e/'),

('Vitamin_K', 'Vitamin K - NIH Office of Dietary Supplements', 'https://ods.od.nih.gov/factsheets/VitaminK-Consumer/'),

-- Minerals
('Calcium', 'Calcium - NIH Office of Dietary Supplements', 'https://ods.od.nih.gov/factsheets/Calcium-Consumer/'),
('Calcium', 'Calcium - NHS', 'https://www.nhs.uk/conditions/vitamins-and-minerals/calcium/'),

('Iron', 'Iron - NIH Office of Dietary Supplements', 'https://ods.od.nih.gov/factsheets/Iron-Consumer/'),
('Iron', 'Iron - NHS', 'https://www.nhs.uk/conditions/vitamins-and-minerals/iron/'),

('Magnesium', 'Magnesium - NIH Office of Dietary Supplements', 'https://ods.od.nih.gov/factsheets/Magnesium-Consumer/'),

('Potassium', 'Potassium - NIH Office of Dietary Supplements', 'https://ods.od.nih.gov/factsheets/Potassium-Consumer/'),

('Zinc', 'Zinc - NIH Office of Dietary Supplements', 'https://ods.od.nih.gov/factsheets/Zinc-Consumer/'),

('Selenium', 'Selenium - NIH Office of Dietary Supplements', 'https://ods.od.nih.gov/factsheets/Selenium-Consumer/'),

('Phosphorus', 'Phosphorus - NIH Office of Dietary Supplements', 'https://ods.od.nih.gov/factsheets/Phosphorus-Consumer/'),

('Copper', 'Copper - NIH Office of Dietary Supplements', 'https://ods.od.nih.gov/factsheets/Copper-Consumer/'),

('Manganese', 'Manganese - NIH Office of Dietary Supplements', 'https://ods.od.nih.gov/factsheets/Manganese-Consumer/'),

('Iodine', 'Iodine - NIH Office of Dietary Supplements', 'https://ods.od.nih.gov/factsheets/Iodine-Consumer/'),

('Chromium', 'Chromium - NIH Office of Dietary Supplements', 'https://ods.od.nih.gov/factsheets/Chromium-Consumer/'),

('Molybdenum', 'Molybdenum - NIH Office of Dietary Supplements', 'https://ods.od.nih.gov/factsheets/Molybdenum-Consumer/'),

('Sodium', 'Salt in your diet - NHS', 'https://www.nhs.uk/live-well/eat-well/food-types/salt-in-your-diet/'),
('Sodium', 'Sodium - FDA Daily Values', 'https://www.fda.gov/food/nutrition-facts-label/daily-value-nutrition-and-supplement-facts-labels'),

('Fluoride', 'Fluoride - CDC', 'https://www.cdc.gov/fluoridation/basics/index.html'),

-- Other Nutrients
('Choline', 'Choline - NIH Office of Dietary Supplements', 'https://ods.od.nih.gov/factsheets/Choline-Consumer/'),

('Omega3_EPA_DHA', 'Omega-3 Fatty Acids - NIH Office of Dietary Supplements', 'https://ods.od.nih.gov/factsheets/Omega3FattyAcids-Consumer/'),
('Omega3_EPA_DHA', 'Fish and shellfish - NHS', 'https://www.nhs.uk/live-well/eat-well/food-types/fish-and-shellfish-nutrition/'),

('Omega3_ALA', 'Omega-3 Fatty Acids - NIH Office of Dietary Supplements', 'https://ods.od.nih.gov/factsheets/Omega3FattyAcids-Consumer/'),

('Lutein_Zeaxanthin', 'Lutein and Zeaxanthin - American Optometric Association', 'https://www.aoa.org/healthy-eyes/eye-health-for-life/lutein'),

('Lycopene', 'Lycopene - National Cancer Institute', 'https://epi.grants.cancer.gov/diet/foodsources/lycopene/')
;