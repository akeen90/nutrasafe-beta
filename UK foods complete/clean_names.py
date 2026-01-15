#!/usr/bin/env python3
"""
Script to clean OCR errors in UK food product names.
"""
import csv
import re

# Define the fixes: row_number -> (original_name, new_name, reason)
# Row numbers are 1-indexed (matching the CSV line numbers, header is row 1)
fixes = {
    311: ("Tesco Frozen Diced Chorizo", "Frozen Diced Chorizo", "Name contains brand prefix redundantly"),
    326: ("Multuseed Loaf", "Multiseed Loaf", "Typo: 'Multuseed' should be 'Multiseed'"),
    337: ("Yomato And Couget Spaghetti", "Tomato And Courgette Spaghetti", "OCR error: 'Yomato' -> 'Tomato', 'Couget' -> 'Courgette'"),
    407: ("Sasuages", "Sausages", "Typo: 'Sasuages' should be 'Sausages'"),
    419: ("Water Thin Roast Chicken", "Wafer Thin Roast Chicken", "Typo: 'Water' should be 'Wafer'"),
    483: ("Breaded Chicken Goujons Gluten Free", "Fruit Gums", "Name doesn't match ingredients (Glucose syrup, Sugar, Sorbitol syrup, popping candy) - barcode 5059697757686 is for fruit gums/candy"),
    499: ("Roasted And Steamed, Sliced Chicken Thighs In A Gr", "Gyros Roast Chicken Thigh Pieces", "OCR captured marketing text instead of product name - derived from ingredients showing 'GYROS ROAST CHICKEN THIGH PIECES'"),
    524: ("Sweet Chilli Chicken Wrap", "Sweet Chilli Chicken Wrap", "Name OK but record shows nutrition label OCR'd as ingredients - keeping name"),
    529: ("Garlic & Herb Ciabatta Breadstickd", "Garlic & Herb Ciabatta Breadsticks", "Typo: 'Breadstickd' should be 'Breadsticks'"),
    571: ("Pink&white Mini Marshmallows Sainsburs Ctfora SWEE", "Pink & White Mini Marshmallows", "OCR error: garbled text, marketing copy mixed in"),
    600: ("Danish Blue Cheese", "Danish Blue Cheese", "Name OK but ingredients contain marketing text about Grana Padano - keeping name as it matches the product type"),
    610: ("Scan Here For Recipe Inspiration 940 Colman's EST", "Chinese Five Spice", "OCR captured QR code label text - ingredients show it's a spice mix with ginger, garlic, pepper, anise, cinnamon, fennel, clove"),
    613: ("Walkers Crisps Famously Worcester Sauce Crisps", "Lea & Perrins Worcester Sauce Crisps", "OCR captured packaging label fragments instead of proper name"),
    625: ("M&S Granola Mango Coco", "Mango Coconut Granola", "OCR partial capture with brand prefix - cleaned to descriptive name"),
    655: ("Mimi Macarons", "Mini Macarons", "OCR error: 'Mimi' should be 'Mini' based on product type"),
    714: ("Marks-spencer", "Smoky BBQ Crisps", "Name is just brand text - derived from ingredients showing smoky BBQ flavoring with molasses, sugar, smoked elements"),
    780: ("Aldi Fiesta Chilli Con Carne Cooking Sauce", "Chilli Con Carne Cooking Sauce", "Ingredients contain OCR garbage text - keeping cleaned product name"),
    862: ("WIN GUMS By Sainsbury's Saturates Takes CAL Satur", "Wine Gums", "OCR captured nutrition label text - derived from ingredients showing typical wine gums composition"),
    885: ("Bury's Cadbury Stamford Street CO. Instant HOT CHO", "Instant Hot Chocolate", "OCR captured packaging text fragments - derived from ingredients showing hot chocolate mix"),
}

# Read the original file
input_file = "/Users/aaronkeen/Downloads/UK foods complete/name_chunk_03.csv"
output_file = "/Users/aaronkeen/Downloads/UK foods complete/name_chunk_03_cleaned.csv"
log_file = "/Users/aaronkeen/Downloads/UK foods complete/name_cleanup_log_03.txt"

changes = []

with open(input_file, 'r', encoding='utf-8') as infile:
    reader = csv.reader(infile)
    rows = list(reader)

# Apply fixes
for row_num, (original, new_name, reason) in fixes.items():
    if row_num < len(rows):
        actual_original = rows[row_num][0]  # Get the actual name in the file
        if actual_original != original:
            # Check if it's similar enough
            print(f"Warning: Row {row_num} has '{actual_original}' not '{original}'")
        rows[row_num][0] = new_name
        changes.append((row_num, actual_original, new_name, reason))

# Write the cleaned file
with open(output_file, 'w', encoding='utf-8', newline='') as outfile:
    writer = csv.writer(outfile)
    writer.writerows(rows)

# Write the log file
with open(log_file, 'w', encoding='utf-8') as logfile:
    logfile.write("Name Cleanup Log - Chunk 03\n")
    logfile.write("=" * 60 + "\n\n")
    logfile.write(f"Total changes made: {len(changes)}\n\n")
    logfile.write("-" * 60 + "\n\n")

    for row_num, original, new_name, reason in sorted(changes):
        logfile.write(f"Row {row_num}:\n")
        logfile.write(f'  Original: "{original}"\n')
        logfile.write(f'  New:      "{new_name}"\n')
        logfile.write(f'  Reason:   {reason}\n\n')

print(f"Cleaned file written to: {output_file}")
print(f"Log file written to: {log_file}")
print(f"Total changes: {len(changes)}")
