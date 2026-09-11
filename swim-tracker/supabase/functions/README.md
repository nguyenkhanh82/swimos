# Supabase Edge Functions

This directory contains Edge Functions for the SwimTrack Pro application.

## Functions

### 1. `suggest-training`
Generates personalized training set suggestions based on historical data and goals.

### 2. `generate-meal-plan`
Creates weekly meal plans based on nutrition goals.

### 3. `generate-race-plan`
Generates detailed race strategies and pacing plans.

## Environment Variables

These functions require AI API keys to be configured. You can use either:

- **OpenAI API** (recommended): Set `OPENAI_API_KEY`
- **Google Gemini API**: Set `GEMINI_API_KEY`

The functions will prefer OpenAI if both are set, otherwise fallback to Gemini.

### Setting Environment Variables

#### Using Supabase Dashboard:
1. Go to your project dashboard
2. Navigate to **Edge Functions** → **Secrets**
3. Add the secret:
   - Key: `OPENAI_API_KEY` or `GEMINI_API_KEY`
   - Value: Your API key

#### Using Supabase CLI:
```bash
# For OpenAI
supabase secrets set OPENAI_API_KEY=your_openai_api_key_here

# For Gemini (alternative)
supabase secrets set GEMINI_API_KEY=your_gemini_api_key_here
```

### Getting API Keys

**OpenAI:**
1. Go to https://platform.openai.com/api-keys
2. Create a new API key
3. Copy the key (starts with `sk-`)

**Google Gemini:**
1. Go to https://aistudio.google.com/app/apikey
2. Create a new API key
3. Copy the key

## Deployment

Deploy all functions:
```bash
supabase functions deploy suggest-training
supabase functions deploy generate-meal-plan
supabase functions deploy generate-race-plan
```

Or deploy all at once:
```bash
supabase functions deploy
```

## Testing

You can test the functions locally using:
```bash
supabase functions serve suggest-training
```

Then make a POST request to `http://localhost:54321/functions/v1/suggest-training` with the appropriate payload.
