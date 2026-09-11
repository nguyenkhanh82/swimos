#!/bin/bash

# Test Supabase Edge Function from command line
# Replace YOUR_JWT_TOKEN with the token from the app logs

JWT_TOKEN="YOUR_JWT_TOKEN_HERE"
SUPABASE_URL="https://haljddborueaplgigsia.supabase.co"
FUNCTION_NAME="suggest-goals"
API_KEY="sb_publishable_bk_IWh1vezTJqe3j9xGcvg_-vvmvzaL"

echo "Testing edge function: $FUNCTION_NAME"
echo "=================================="

curl -X POST "$SUPABASE_URL/functions/v1/$FUNCTION_NAME" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $JWT_TOKEN" \
  -H "apikey: $API_KEY" \
  -v

echo ""
echo "=================================="
echo "Test complete"
