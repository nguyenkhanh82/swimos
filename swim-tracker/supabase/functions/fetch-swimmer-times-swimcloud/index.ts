// Supabase Edge Function to fetch swimmer times from SwimCloud
// Used for on-demand updates when users login or use the app
// Deploy with: supabase functions deploy fetch-swimmer-times-swimcloud

import "jsr:@supabase/functions-js/edge-runtime.d.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0"

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

interface SwimmerRequest {
  swimmer_id: number // SwimCloud swimmer ID
}

interface SwimTime {
  event_name: string
  time_seconds: number
  date?: string
  meet_name?: string
  course?: string // SCY, LCM, SCM
  is_personal_best?: boolean
  stroke?: string // Free, Back, Breast, Fly, IM
  distance?: number
}

// SwimCloud API response structure
interface SwimCloudTime {
  id: number
  eventgender: string
  eventdistance: number
  eventstroke: string // "1"=Free, "2"=Back, "3"=Breast, "4"=Fly, "5"=IM
  eventcourse: string // "Y"=Yards, "L"=Long Course Meters
  eventtime: string // Time as string (e.g., "26.91", "1:23.45")
  dateofswim: string // "2026-01-04"
  meet_name?: string
  name?: string // Meet name
  legal: boolean
  flag?: string // "S" for special flags
  [key: string]: any // Allow other fields
}

/**
 * Converts time string (e.g., "1:23.45" or "23.45") to seconds
 */
function parseTimeToSeconds(timeStr: string): number {
  const parts = timeStr.split(':')
  if (parts.length === 2) {
    // Format: MM:SS.mm
    const minutes = parseFloat(parts[0])
    const seconds = parseFloat(parts[1])
    return minutes * 60 + seconds
  } else {
    // Format: SS.mm
    return parseFloat(timeStr)
  }
}

/**
 * Converts stroke number to stroke name
 */
function strokeNumberToName(stroke: string): string {
  const strokeMap: Record<string, string> = {
    '1': 'Free',
    '2': 'Back',
    '3': 'Breast',
    '4': 'Fly',
    '5': 'IM',
  }
  return strokeMap[stroke] || 'Free'
}

/**
 * Converts course code to pool type
 */
function courseCodeToPoolType(course: string): string {
  const courseMap: Record<string, string> = {
    'Y': 'SCY', // Yards (Short Course Yards)
    'L': 'LCM', // Long Course Meters
  }
  return courseMap[course] || 'SCY'
}

/**
 * Builds event name from stroke, distance, and course
 */
function buildEventName(stroke: string, distance: number, course: string): string {
  const strokeName = strokeNumberToName(stroke)
  return `${distance} ${strokeName}`
}

/**
 * Parse event_name (e.g. "200 IM", "50 Free") into distance and stroke for NOT NULL columns
 */
function parseEventName(eventName: string): { distance: number; stroke: string } | null {
  const trimmed = eventName.trim().replace(/\s+/g, ' ')
  const match = trimmed.match(/^(\d+)\s+(.+)$/)
  if (!match) return null
  const distance = parseInt(match[1], 10)
  const strokePart = match[2].trim()
  if (Number.isNaN(distance) || !strokePart) return null
  // Normalize stroke: "IM" | "Free" | "Back" | "Breast" | "Fly"
  const strokeMap: Record<string, string> = {
    'im': 'IM', 'free': 'Free', 'fr': 'Free', 'back': 'Back', 'bk': 'Back',
    'breast': 'Breast', 'br': 'Breast', 'fly': 'Fly', 'fl': 'Fly',
  }
  const stroke = strokeMap[strokePart.toLowerCase()] ?? strokePart
  return { distance, stroke }
}

/**
 * Fetches swimmer fastest times from SwimCloud API to get list of events
 * Then fetches all times for each event to get all meets
 */
async function fetchSwimmerTimesFromAPI(swimmerId: number): Promise<SwimTime[]> {
  console.log(`Fetching all times from SwimCloud API for swimmer ID: ${swimmerId}`)
  
  // Step 1: Get list of events from fastest times endpoint
  const fastestTimesUrl = `https://www.swimcloud.com/api/swimmers/${swimmerId}/profile_fastest_times/`
  
  let eventCombinations: Set<string> = new Set()
  
  try {
    const fastestResponse = await fetch(fastestTimesUrl, {
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        'Accept': 'application/json',
      },
    })

    if (!fastestResponse.ok) {
      throw new Error(`Failed to fetch fastest times: ${fastestResponse.status} ${fastestResponse.statusText}`)
    }

    const fastestTimes: SwimCloudTime[] = await fastestResponse.json()
    
    if (!Array.isArray(fastestTimes)) {
      throw new Error('Unexpected response format: expected array')
    }

    // Extract unique event combinations (stroke|distance|course)
    for (const time of fastestTimes) {
      if (time.legal) {
        const eventKey = `${time.eventstroke}|${time.eventdistance}|${time.eventcourse}`
        eventCombinations.add(eventKey)
      }
    }

    console.log(`Found ${eventCombinations.size} unique event combinations`)
  } catch (error) {
    console.error('Error fetching fastest times:', error)
    throw error
  }

  // Step 2: Fetch all times for each event combination
  const allTimes: SwimTime[] = []
  
  for (const eventKey of eventCombinations) {
    try {
      const [stroke, distance, course] = eventKey.split('|')
      const eventUrl = `https://www.swimcloud.com/api/swimmers/${swimmerId}/times_by_event/?event=${stroke}%7C${distance}%7C${course}%7C1`
      
      console.log(`Fetching all times for event: ${eventKey}`)
      
      const response = await fetch(eventUrl, {
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          'Accept': 'application/json',
        },
      })

      if (!response.ok) {
        console.warn(`Failed to fetch times for ${eventKey}: ${response.status}`)
        continue
      }

      const apiTimes: SwimCloudTime[] = await response.json()
      
      if (!Array.isArray(apiTimes)) {
        console.warn(`Unexpected response format for ${eventKey}`)
        continue
      }

      // Convert API times to our format
      for (const apiTime of apiTimes) {
        // Skip if not legal time
        if (!apiTime.legal) {
          continue
        }

        // Build event name and stroke/distance for DB
        const strokeName = strokeNumberToName(apiTime.eventstroke)
        const eventName = buildEventName(apiTime.eventstroke, apiTime.eventdistance, apiTime.eventcourse)
        const poolType = courseCodeToPoolType(apiTime.eventcourse)
        const distanceNum = typeof apiTime.eventdistance === 'number' ? apiTime.eventdistance : parseInt(String(apiTime.eventdistance), 10)

        // Parse time
        const timeSeconds = parseTimeToSeconds(apiTime.eventtime)
        if (isNaN(timeSeconds) || timeSeconds <= 0) {
          continue
        }

        // Get meet name - the times_by_event endpoint includes meet names in the 'name' field
        const meetName = apiTime.name || apiTime.meet_name || apiTime.meetname || null

        allTimes.push({
          event_name: eventName,
          time_seconds: timeSeconds,
          date: apiTime.dateofswim,
          meet_name: meetName,
          course: poolType,
          is_personal_best: false, // Will be determined after all times are collected
          stroke: strokeName,
          distance: isNaN(distanceNum) ? undefined : distanceNum,
        })
      }

      // Add small delay to avoid rate limiting
      await new Promise(resolve => setTimeout(resolve, 200))
    } catch (error) {
      console.error(`Error fetching times for event ${eventKey}:`, error)
      // Continue with other events
    }
  }

  // Determine personal bests (fastest time for each event)
  const eventBestTimes = new Map<string, number>()
  for (const time of allTimes) {
    const currentBest = eventBestTimes.get(time.event_name)
    if (!currentBest || time.time_seconds < currentBest) {
      eventBestTimes.set(time.event_name, time.time_seconds)
    }
  }

  // Mark personal bests
  for (const time of allTimes) {
    const bestTime = eventBestTimes.get(time.event_name)
    if (bestTime && time.time_seconds === bestTime) {
      time.is_personal_best = true
    }
  }

  console.log(`Fetched ${allTimes.length} total times from ${eventCombinations.size} events`)
  return allTimes
}

/**
 * Saves swim times to database
 */
async function saveTimesToDatabase(
  supabase: ReturnType<typeof createClient>,
  swimmerId: number,
  times: SwimTime[]
): Promise<{ events_found: number; times_found: number; swimmer_found: boolean; first_insert_error?: string }> {
  // Look up database swimmer by swimcloud_id (try string and number formats)
  const swimcloudIdStr = String(swimmerId).trim()
  let swimmer: { id: string; user_id: string | null } | null = null
  let swimmerError: { message: string; details?: string; hint?: string } | null = null

  const { data: swimmerRow, error: errStr } = await supabase
    .from('swimmers')
    .select('id, user_id')
    .eq('swimcloud_id', swimcloudIdStr)
    .maybeSingle()

  if (swimmerRow) {
    swimmer = swimmerRow
  } else if (errStr) {
    swimmerError = { message: errStr.message, details: errStr.details, hint: errStr.hint }
  }

  // If no match, try normalized id (strip leading zeros) in case DB has different format
  if (!swimmer && swimcloudIdStr) {
    const normalizedId = parseInt(swimcloudIdStr, 10)
    if (!Number.isNaN(normalizedId)) {
      const { data: swimmerNorm } = await supabase
        .from('swimmers')
        .select('id, user_id')
        .eq('swimcloud_id', String(normalizedId))
        .maybeSingle()
      if (swimmerNorm) swimmer = swimmerNorm
    }
  }

  if (!swimmer) {
    console.warn(`Swimmer with swimcloud_id "${swimmerId}" (string: "${swimcloudIdStr}") not found. Error: ${swimmerError?.message ?? 'no matching row'}. Ensure the swimmer profile has SwimCloud ID set.`)
    const uniqueEvents = new Set(times.map(t => t.event_name))
    return {
      events_found: uniqueEvents.size,
      times_found: 0,
      swimmer_found: false,
    }
  }

  console.log(`Found swimmer id=${swimmer.id} (swimcloud_id=${swimmerId}), saving ${times.length} times`)

  let savedCount = 0
  let firstInsertError: string | undefined
  const uniqueEvents = new Set<string>()

  // Track unique meet names to sync meets
  const meetNames = new Set<string>()
  const meetTimesMap = new Map<string, { earliestDate?: Date; poolType?: string }>()

  for (const time of times) {
    try {
      uniqueEvents.add(time.event_name)
      
      // Track meet names for syncing
      if (time.meet_name) {
        meetNames.add(time.meet_name)
        if (!meetTimesMap.has(time.meet_name)) {
          meetTimesMap.set(time.meet_name, { poolType: time.course })
        }
        const meetInfo = meetTimesMap.get(time.meet_name)!
        if (time.date) {
          const timeDate = new Date(time.date)
          if (!meetInfo.earliestDate || timeDate < meetInfo.earliestDate) {
            meetInfo.earliestDate = timeDate
          }
        }
      }
      
      // Check if time already exists (by swimmer_id, event_name, and time_seconds)
      const { data: existing } = await supabase
        .from('swim_times')
        .select('id')
        .eq('swimmer_id', swimmer.id)
        .eq('event_name', time.event_name)
        .eq('time_seconds', time.time_seconds)
        .maybeSingle()

      if (!existing) {
        // Resolve stroke and distance (required NOT NULL in DB): use time fields or parse from event_name
        let stroke = time.stroke
        let distance = time.distance != null && !Number.isNaN(time.distance) ? time.distance : null
        if (stroke == null || distance == null) {
          const parsed = parseEventName(time.event_name)
          if (parsed) {
            stroke = stroke ?? parsed.stroke
            distance = distance ?? parsed.distance
          }
        }
        if (stroke == null || distance == null) {
          console.warn(`Skipping ${time.event_name}: could not resolve stroke/distance for NOT NULL columns`)
          continue
        }

        // Insert new time (stroke and distance are required by DB)
        const timeData: Record<string, unknown> = {
          swimmer_id: swimmer.id,
          event_name: time.event_name,
          time_seconds: time.time_seconds,
          is_personal_best: time.is_personal_best ?? false,
          pool_type: time.course ?? 'SCY',
          stroke,
          distance,
        }
        if (time.date) {
          timeData.meet_date = new Date(time.date).toISOString().split('T')[0]
        }
        if (time.meet_name) {
          timeData.meet_name = time.meet_name
        }
        if (swimmer.user_id) {
          timeData.user_id = swimmer.user_id
        }

        const { error } = await supabase.from('swim_times').insert(timeData)

        if (!error) {
          savedCount++
        } else {
          const errMsg = [error?.message, error?.details, error?.hint].filter(Boolean).join('; ')
          console.error(`Error saving time for ${time.event_name}:`, errMsg)
          if (!firstInsertError) firstInsertError = errMsg
        }
      }
    } catch (error) {
      console.error(`Error processing time ${time.event_name}:`, error)
    }
  }

  // Sync meets from meet names
  if (meetNames.size > 0) {
    console.log(`Syncing ${meetNames.size} unique meets from ${savedCount} times...`)
    let meetsCreated = 0
    for (const meetName of meetNames) {
      try {
        // Check if meet already exists
        const { data: existingMeet } = await supabase
          .from('swim_meets')
          .select('id')
          .eq('swimmer_id', swimmer.id)
          .eq('meet_name', meetName)
          .maybeSingle()

        if (!existingMeet) {
          // Create new meet
          const meetInfo = meetTimesMap.get(meetName)
          const meetDate = meetInfo?.earliestDate || new Date()

          const meetData: Record<string, unknown> = {
            swimmer_id: swimmer.id,
            user_id: swimmer.user_id,
            meet_name: meetName,
            start_date: meetDate.toISOString().split('T')[0],
            pool_type: meetInfo?.poolType || 'SCY',
          }

          const { error: meetError } = await supabase.from('swim_meets').insert(meetData)

          if (meetError) {
            console.error(`Error creating meet ${meetName}:`, meetError?.message, meetError?.details, meetError?.hint)
          } else {
            console.log(`✅ Created meet: ${meetName} on ${meetDate.toISOString().split('T')[0]}`)
            meetsCreated++
          }
        } else {
          console.log(`Meet ${meetName} already exists`)
        }
      } catch (error) {
        console.error(`Error syncing meet ${meetName}:`, error)
      }
    }
    console.log(`Created ${meetsCreated} new meets`)
  } else {
    console.log(`⚠️ No meet names found in ${times.length} times - meets cannot be created without meet names`)
  }

  return {
    events_found: uniqueEvents.size,
    times_found: savedCount,
    swimmer_found: true,
    ...(firstInsertError && { first_insert_error: firstInsertError }),
  }
}

Deno.serve(async (req) => {
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
    const { swimmer_id }: SwimmerRequest = await req.json()

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

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

    // Fetch times from SwimCloud API
    const times = await fetchSwimmerTimesFromAPI(swimmer_id)
    
    // Save times to database
    const result = await saveTimesToDatabase(supabase, swimmer_id, times)

    // Update database with last_fetched timestamp
    const { error: updateError } = await supabase
      .from('swimmers')
      .update({ 
        last_fetched_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      })
      .eq('swimcloud_id', swimmer_id.toString())

    if (updateError) {
      console.error('Error updating swimmer record:', updateError)
      // Don't fail if swimmers table doesn't exist or column doesn't exist
    }
    
    return new Response(
      JSON.stringify({
        success: true,
        swimmer_id,
        events_found: result.events_found,
        times_found: result.times_found,
        total_times_fetched: times.length,
        swimmer_found: result.swimmer_found,
        ...(result.first_insert_error && { insert_error: result.first_insert_error }),
        message: result.swimmer_found
          ? `Fetched ${result.events_found} events, saved ${result.times_found} times.${result.first_insert_error ? ` First insert error: ${result.first_insert_error}` : ''}`
          : `Swimmer not found in database (swimcloud_id=${swimmer_id}). Set SwimCloud ID on the swimmer profile.`,
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
    const errorMessage = error instanceof Error ? error.message : String(error)
    return new Response(
      JSON.stringify({ 
        error: errorMessage,
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
