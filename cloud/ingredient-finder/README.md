# NutraSafe Ingredient Finder Cloud Function

HTTP service that finds food ingredients using Google Custom Search and cleans the text via Gemini Flash.

## Local Development

1. Create `.env` from `.env.example` and set keys:

```
GOOGLE_CSE_KEY=...
GOOGLE_CSE_CX=...
GEMINI_API_KEY=...
PORT=8080
```

2. Install dependencies and start the server:

```
npm install
npm start
```

3. Test the endpoint:

```
curl -X POST http://localhost:8080/findIngredients \
  -H 'Content-Type: application/json' \
  -d '{"productName":"Alpro Chocolate Soya Drink","brand":"Alpro"}'
```

## Deployment (Google Cloud Functions)

- Create secrets in Secret Manager (recommended):
  - `nutrasafe-cse-key`
  - `nutrasafe-cse-cx`
  - `nutrasafe-gemini-key`
- Deploy an HTTP function and wire secrets as environment variables or access via Secret Manager SDK.

Example (env vars):

```
gcloud functions deploy findIngredients \
  --runtime nodejs20 --region us-central1 --trigger-http \
  --set-env-vars GOOGLE_CSE_KEY=... ,GOOGLE_CSE_CX=...,GEMINI_API_KEY=...
```

## Response Schema

```json
{
  "ingredients_found": true,
  "ingredients_text": "Water, Pea protein, Flaxseed, Sunflower oil, Cocoa powder...",
  "source_url": "https://..."
}
```

## Firestore Cache Schema (per-user)

- Collection: `ingredientCache`
- Document ID: `${productName}|${brand}` (normalized)
- Fields:
  - `productName` (string)
  - `brand` (string)
  - `ingredientsText` (string)
  - `sourceUrl` (string)
  - `createdAt` (timestamp)

## Notes
- Prioritize official sites and UK supermarkets via the query.
- Never scrape directly; rely on Custom Search results.
- Basic IP rate limiting is included server-side; client also limits 2 req/min.