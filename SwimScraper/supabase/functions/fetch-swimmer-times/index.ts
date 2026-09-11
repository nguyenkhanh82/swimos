// Supabase Edge Function to fetch swimmer times
// Deploy with: supabase functions deploy fetch-swimmer-times

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

interface SwimmerRequest {
  swimmer_id: number
}

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
    const body = await req.json()
    
    // Check if this is a club teams request or swimmer times request
    if (body.url) {
      // Club teams from URL request
      const { url }: ClubTeamsRequest = body
      
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
    }
    
    // Swimmer times request
    const { swimmer_id }: SwimmerRequest = body

    if (!swimmer_id) {
      return new Response(
        JSON.stringify({ error: 'swimmer_id is required' }),
        { 
          status: 400,
          headers: { 
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
          },
        }
      )
    }

    console.log(`Fetching times for swimmer ID: ${swimmer_id}`)

    // Call Python script via HTTP or direct execution
    // Option 1: Call a Python API endpoint (if you have one)
    // Option 2: Execute Python script directly (requires Deno Python support)
    // Option 3: Use Supabase's pg_net extension to call a stored procedure
    
    // For now, we'll use a webhook approach or direct Python execution
    // This requires setting up a Python service that the Edge Function can call
    
    // Alternative: Use Supabase's database functions to trigger Python
    // We'll create a database function that calls an external API
    
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

    // Call external API that runs the Python scraper
    // You'll need to set up a separate service (e.g., on Railway, Render, etc.)
    const PYTHON_API_URL = Deno.env.get('PYTHON_API_URL') || 'http://localhost:8000'
    
    const response = await fetch(`${PYTHON_API_URL}/fetch-swimmer-times`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ swimmer_id }),
    })

    if (!response.ok) {
      const error = await response.text()
      throw new Error(`Python API error: ${error}`)
    }

    const result = await response.json()

    // Update database with last_fetched timestamp
    const { error: updateError } = await supabase
      .from('swimmers')
      .update({ 
        last_fetched_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      })
      .eq('swimmer_id', swimmer_id)

    if (updateError) {
      console.error('Error updating swimmer record:', updateError)
    }

    return new Response(
      JSON.stringify({
        success: true,
        swimmer_id,
        events_found: result.events_found || 0,
        times_found: result.times_found || 0,
        message: `Successfully fetched times for swimmer ${swimmer_id}`,
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
