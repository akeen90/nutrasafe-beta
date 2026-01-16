import { getCliClient } from 'sanity/cli'

// Use CLI client which inherits login credentials
const client = getCliClient()

const siteSettings = {
  _type: 'siteSettings',
  _id: 'siteSettings',
  siteName: 'NutraSafe',
  tagline: 'Know What You\'re Eating',
  contactEmail: 'support@nutrasafe.app',
  footerText: '© 2025 NutraSafe. All rights reserved.',
  appStoreUrl: 'https://apps.apple.com/app/nutrasafe',
}

const faqs = [
  {
    _type: 'faq',
    question: 'What are E-numbers?',
    answer: [{ _type: 'block', _key: 'a1', style: 'normal', children: [{ _type: 'span', _key: 's1', text: 'E-numbers are codes for food additives approved for use within the European Union and UK. The "E" stands for "Europe". They include preservatives, colours, antioxidants, emulsifiers, and flavour enhancers.' }] }],
    category: 'additives',
    order: 1,
    isPopular: true,
  },
  {
    _type: 'faq',
    question: 'Are all E-numbers bad for you?',
    answer: [{ _type: 'block', _key: 'a2', style: 'normal', children: [{ _type: 'span', _key: 's2', text: 'No, not all E-numbers are harmful. Many are natural substances like E300 (Vitamin C) or E330 (Citric acid). However, some synthetic additives may cause reactions in sensitive individuals. NutraSafe helps you identify which additives to watch out for based on your personal needs.' }] }],
    category: 'additives',
    order: 2,
    isPopular: true,
  },
  {
    _type: 'faq',
    question: 'What is intermittent fasting?',
    answer: [{ _type: 'block', _key: 'a3', style: 'normal', children: [{ _type: 'span', _key: 's3', text: 'Intermittent fasting is an eating pattern that cycles between periods of fasting and eating. Popular methods include 16:8 (16 hours fasting, 8 hours eating window) and 5:2 (eating normally 5 days, restricting calories 2 days).' }] }],
    category: 'fasting',
    order: 1,
    isPopular: true,
  },
  {
    _type: 'faq',
    question: 'How does NutraSafe scan food?',
    answer: [{ _type: 'block', _key: 'a4', style: 'normal', children: [{ _type: 'span', _key: 's4', text: 'NutraSafe uses AI-powered image recognition to identify foods from photos. Simply take a picture of your meal or scan a barcode, and the app will provide detailed nutritional information, ingredient analysis, and additive warnings.' }] }],
    category: 'features',
    order: 1,
    isPopular: true,
  },
  {
    _type: 'faq',
    question: 'What allergens does NutraSafe detect?',
    answer: [{ _type: 'block', _key: 'a5', style: 'normal', children: [{ _type: 'span', _key: 's5', text: 'NutraSafe detects the 14 major allergens required by UK/EU law: celery, cereals containing gluten, crustaceans, eggs, fish, lupin, milk, molluscs, mustard, nuts, peanuts, sesame seeds, soybeans, and sulphur dioxide.' }] }],
    category: 'allergies',
    order: 1,
    isPopular: true,
  },
]

const homePage = {
  _type: 'page',
  _id: 'page-home',
  title: 'Home',
  slug: { _type: 'slug', current: 'home' },
  metaTitle: 'NutraSafe - Know What You\'re Eating',
  metaDescription: 'NutraSafe is your intelligent food companion. Scan barcodes, analyse ingredients, and track your nutrition with AI-powered insights.',
  heroSection: {
    headline: 'Know What You\'re Eating',
    subheadline: 'Scan. Analyse. Thrive. Your intelligent food companion for a healthier life.',
    ctaText: 'Download Free',
    ctaLink: 'https://apps.apple.com/app/nutrasafe',
  },
  features: [
    {
      _type: 'feature',
      _key: 'f1',
      title: 'AI Food Scanner',
      description: 'Point your camera at any food and get instant nutritional analysis',
      icon: 'camera',
    },
    {
      _type: 'feature',
      _key: 'f2',
      title: 'Barcode Scanning',
      description: 'Scan product barcodes to access detailed ingredient and nutrition data',
      icon: 'barcode',
    },
    {
      _type: 'feature',
      _key: 'f3',
      title: 'Allergen Alerts',
      description: 'Get instant warnings for your personal allergens and intolerances',
      icon: 'warning',
    },
    {
      _type: 'feature',
      _key: 'f4',
      title: 'Additive Analysis',
      description: 'Understand E-numbers and food additives with safety ratings',
      icon: 'lab',
    },
  ],
}

const aboutPage = {
  _type: 'page',
  _id: 'page-about',
  title: 'About',
  slug: { _type: 'slug', current: 'about' },
  metaTitle: 'About NutraSafe',
  metaDescription: 'Learn about NutraSafe and our mission to help people make informed food choices.',
}

const blogPost = {
  _type: 'blogPost',
  _id: 'blog-welcome',
  title: 'Welcome to NutraSafe',
  slug: { _type: 'slug', current: 'welcome-to-nutrasafe' },
  author: 'NutraSafe Team',
  publishedAt: new Date().toISOString(),
  excerpt: 'Introducing NutraSafe - your new intelligent food companion for making informed choices about what you eat.',
  body: [
    {
      _type: 'block',
      _key: 'b1',
      style: 'normal',
      markDefs: [],
      children: [{
        _type: 'span',
        _key: 'sp1',
        marks: [],
        text: 'We\'re excited to introduce NutraSafe, an app designed to help you understand exactly what\'s in your food. Whether you\'re managing allergies, tracking additives, or simply want to make healthier choices, NutraSafe gives you the tools you need.'
      }]
    },
    {
      _type: 'block',
      _key: 'b2',
      style: 'h2',
      markDefs: [],
      children: [{
        _type: 'span',
        _key: 'sp2',
        marks: [],
        text: 'Key Features'
      }]
    },
    {
      _type: 'block',
      _key: 'b3',
      style: 'normal',
      markDefs: [],
      children: [{
        _type: 'span',
        _key: 'sp3',
        marks: [],
        text: 'Scan any food with AI-powered recognition, get instant allergen warnings, understand E-numbers and additives, and track your daily nutrition - all in one app.'
      }]
    },
  ],
  categories: ['app-updates'],
  metaDescription: 'Introducing NutraSafe - your intelligent food companion',
  isPublished: true,
}

async function seed() {
  console.log('Creating site settings...')
  await client.createOrReplace(siteSettings)
  console.log('✓ Site settings created')

  console.log('Creating FAQs...')
  for (const faq of faqs) {
    const id = faq.question.toLowerCase().replace(/[^a-z0-9]+/g, '-').slice(0, 50)
    await client.createOrReplace({ ...faq, _id: `faq-${id}` })
    console.log(`✓ FAQ: ${faq.question.slice(0, 40)}...`)
  }

  console.log('Creating pages...')
  await client.createOrReplace(homePage)
  console.log('✓ Home page created')
  await client.createOrReplace(aboutPage)
  console.log('✓ About page created')

  console.log('Creating blog post...')
  await client.createOrReplace(blogPost)
  console.log('✓ Welcome blog post created')

  console.log('\n✅ Seed complete! Refresh your studio.')
}

seed().catch(console.error)
