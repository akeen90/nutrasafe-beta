import { getCliClient } from 'sanity/cli'
import { createReadStream } from 'fs'
import path from 'path'

const client = getCliClient()

const images = [
  { file: 'app-icon.png', title: 'App Icon', category: 'branding', alt: 'NutraSafe app icon' },
  { file: 'scan-screen.png', title: 'Scan Screen', category: 'screenshots', alt: 'NutraSafe barcode scanning screen' },
  { file: 'nutrition-dashboard.png', title: 'Nutrition Dashboard', category: 'screenshots', alt: 'NutraSafe nutrition dashboard' },
  { file: 'ingredients-view.png', title: 'Ingredients View', category: 'screenshots', alt: 'NutraSafe ingredients analysis' },
  { file: 'allergy-alerts.png', title: 'Allergy Alerts', category: 'screenshots', alt: 'NutraSafe allergen warnings' },
  { file: 'use-by-screen.png', title: 'Use By Screen', category: 'screenshots', alt: 'NutraSafe use by date tracker' },
  { file: 'Simulator Screenshot - iPhone 17 Pro - 2025-10-26 at 10.43.06.png', title: 'Screenshot 1', category: 'screenshots', alt: 'NutraSafe app screenshot' },
  { file: 'Simulator Screenshot - iPhone 17 Pro - 2025-10-26 at 10.43.20.png', title: 'Screenshot 2', category: 'screenshots', alt: 'NutraSafe app screenshot' },
  { file: 'Simulator Screenshot - iPhone 17 Pro - 2025-10-26 at 10.44.23.png', title: 'Screenshot 3', category: 'screenshots', alt: 'NutraSafe app screenshot' },
  { file: 'Simulator Screenshot - iPhone 17 Pro - 2025-10-26 at 10.44.29.png', title: 'Screenshot 4', category: 'screenshots', alt: 'NutraSafe app screenshot' },
  { file: 'Simulator Screenshot - iPhone 17 Pro - 2025-10-26 at 10.45.02.png', title: 'Screenshot 5', category: 'screenshots', alt: 'NutraSafe app screenshot' },
  { file: 'Simulator Screenshot - iPhone 17 Pro - 2025-10-26 at 10.45.24.png', title: 'Screenshot 6', category: 'screenshots', alt: 'NutraSafe app screenshot' },
  { file: 'Simulator Screenshot - iPhone 17 Pro - 2025-10-26 at 10.46.15.png', title: 'Screenshot 7', category: 'screenshots', alt: 'NutraSafe app screenshot' },
  { file: 'Simulator Screenshot - iPhone 17 Pro - 2025-10-26 at 10.46.23.png', title: 'Screenshot 8', category: 'screenshots', alt: 'NutraSafe app screenshot' },
  { file: 'Simulator Screenshot - iPhone 17 Pro - 2025-10-26 at 10.46.30.png', title: 'Screenshot 9', category: 'screenshots', alt: 'NutraSafe app screenshot' },
]

const publicDir = '/Users/aaronkeen/Documents/My Apps/NutraSafe/firebase/public'

async function uploadImages() {
  console.log('Uploading images to Sanity...\n')

  for (const img of images) {
    const filePath = path.join(publicDir, img.file)
    const id = img.title.toLowerCase().replace(/[^a-z0-9]+/g, '-')

    try {
      console.log(`Uploading: ${img.title}...`)

      // Upload the image asset
      const asset = await client.assets.upload('image', createReadStream(filePath), {
        filename: img.file,
      })

      // Create or replace the mediaImage document
      await client.createOrReplace({
        _type: 'mediaImage',
        _id: `media-${id}`,
        title: img.title,
        alt: img.alt,
        category: img.category,
        image: {
          _type: 'image',
          asset: {
            _type: 'reference',
            _ref: asset._id,
          },
        },
      })

      console.log(`✓ ${img.title}`)
    } catch (error) {
      console.error(`✗ Failed: ${img.title} - ${error.message}`)
    }
  }

  console.log('\n✅ Upload complete! Refresh your studio.')
}

uploadImages().catch(console.error)
