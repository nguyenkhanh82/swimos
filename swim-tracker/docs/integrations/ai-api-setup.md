# AI API Setup for Edge Functions

## Overview

The SwimTrack Pro app uses AI models to generate:
- **Training Set Suggestions** - Personalized workout recommendations
- **Meal Plans** - Weekly nutrition plans based on goals
- **Race Plans** - Detailed race strategies and pacing

## Supported AI Providers

The edge functions support two AI providers:

1. **OpenAI** (Recommended)
   - Model: `gpt-4o-mini`
   - Fast, reliable, good JSON generation
   - Function calling support for structured outputs

2. **Google Gemini** (Alternative)
   - Model: `gemini-1.5-flash`
   - Cost-effective alternative
   - Good for general text generation

## Configuration

### Option 1: OpenAI (Recommended)

1. Get your API key from https://platform.openai.com/api-keys
2. Set the secret in Supabase:

```bash
supabase secrets set OPENAI_API_KEY=sk-your-key-here
```

### Option 2: Google Gemini

1. Get your API key from https://aistudio.google.com/app/apikey
2. Set the secret in Supabase:

```bash
supabase secrets set GEMINI_API_KEY=your-key-here
```

### Priority

If both keys are set, the functions will use OpenAI. If only Gemini is set, it will use Gemini.

## Functions

### `suggest-training`
- **Input**: Historical training data, goals
- **Output**: Array of training set suggestions with rationale
- **Uses**: Function calling (OpenAI) or JSON mode (Gemini)

### `generate-meal-plan`
- **Input**: Daily nutrition goals (calories, macros)
- **Output**: Weekly meal plan (28 meals: 7 days × 4 meals/day)
- **Uses**: JSON mode for structured output

### `generate-race-plan`
- **Input**: Event details, target time, personal bests
- **Output**: Detailed markdown race plan
- **Uses**: Standard text generation

## Testing

After setting up API keys, test the functions:

```bash
# Test locally
supabase functions serve suggest-training

# Deploy
supabase functions deploy suggest-training
supabase functions deploy generate-meal-plan
supabase functions deploy generate-race-plan
```

## Cost Considerations

- **OpenAI gpt-4o-mini**: ~$0.15 per 1M input tokens, ~$0.60 per 1M output tokens
- **Gemini 1.5 Flash**: ~$0.075 per 1M input tokens, ~$0.30 per 1M output tokens

For typical usage:
- Training suggestions: ~500-1000 tokens per request
- Meal plans: ~2000-3000 tokens per request
- Race plans: ~1500-2500 tokens per request

## Troubleshooting

### "API key is invalid or expired"
- Verify the API key is correctly set in Supabase secrets
- Check the key hasn't been revoked
- Ensure no extra spaces or quotes in the secret value

### "Rate limit exceeded"
- You've hit the API provider's rate limits
- Wait a few minutes and try again
- Consider upgrading your API plan for higher limits

### "No suggestions returned from AI"
- Check the function logs in Supabase dashboard
- Verify the API is responding correctly
- Try switching between OpenAI and Gemini
