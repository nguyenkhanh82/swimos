// Supabase Edge Function to fetch club teams from a URL
// Deploy with: supabase functions deploy fetch-club-teams

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

interface ClubTeamsRequest {
  url: string
}

serve(async (req) => {
  try {
    // Handle CORS
    if (req.method === 'OPTIONS') {
      return new Response('ok', {
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'POST, OPTIONS',
          'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
        },
      })
    }

    // Parse request
    const { url }: ClubTeamsRequest = await req.json()

    if (!url) {
      return new Response(
        JSON.stringify({ error: 'url is required' }),
        { 
          status: 400,
          headers: { 
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
          },
        }
      )
    }

    console.log(`Fetching club teams from URL: ${url}`)

    // Call external API that runs the Python scraper
    const PYTHON_API_URL = Deno.env.get('PYTHON_API_URL') || 'http://localhost:8000'
    
    const response = await fetch(`${PYTHON_API_URL}/fetch-club-teams-from-url`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ url }),
    })

    if (!response.ok) {
      const error = await response.text()
      throw new Error(`Python API error: ${error}`)
    }

    const result = await response.json()

    return new Response(
      JSON.stringify({
        success: true,
        url,
        teams_found: result.teams_found || 0,
        message: `Successfully fetched ${result.teams_found || 0} teams from URL`,
      }),
      {
        status: 200,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
        },
      }
    )

  } catch (error) {
    console.error('Error:', error)
    return new Response(
      JSON.stringify({ 
        error: error.message,
        success: false,
      }),
      {
        status: 500,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
        },
      }
    )
  }
})
