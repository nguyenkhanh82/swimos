// Supabase Edge Function to fetch club teams from SwimCloud
// Used for one-time bulk import of Pacific Northwest teams
// Deploy with: supabase functions deploy fetch-club-teams

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

interface ClubTeamsRequest {
  // Option 1: Use swimmer profile to get age group, gender, region
  swimmer_id?: string // UUID of swimmer in database - will fetch profile data
  
  // Option 2: Manual parameters (overrides swimmer profile if provided)
  ageGroup?: string // e.g., '0910', '1112', '1314', '1516', 'UNOV'
  gender?: 'M' | 'F' // Male or Female
  eventCourse?: 'Y' | 'L' // Y = Yards (Short Course), L = Long Course Meters
  region?: string // e.g., 'lsc_PN' for Pacific Northwest
  seasonId?: number // If not provided, will fetch current season from API
  seasons?: number[] // Array of season IDs to fetch (defaults to last 4 seasons)
  fetchAllPages?: boolean // Default: true - fetch all pages
}

interface TeamInfo {
  name: string
  swimcloud_id?: string
  location?: string
  url?: string
}

// API response structure from SwimCloud
interface SwimCloudApiResponse {
  number: number
  count: number
  page_count: number
  results: Array<{
    id: number
    name: string
    location: string
    city?: string
    state?: string
    absolute_url?: string
    [key: string]: any
  }>
}

// Default values
const DEFAULT_REGION = 'lsc_PN' // Pacific Northwest
const DEFAULT_COURSES: ('Y' | 'L')[] = ['Y', 'L'] // Both Yards and Long Course

/**
 * Fetches available seasons from SwimCloud API
 */
async function fetchSeasons(count: number = 10): Promise<Array<{ seasonId: number; label: string; isCurrent: boolean }>> {
  const apiUrl = `https://www.swimcloud.com/api/seasonchoices/?count=${count}&from_next=false`
  
  const response = await fetch(apiUrl, {
    headers: {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
      'Accept': 'application/json',
    },
  })

  if (!response.ok) {
    throw new Error(`Failed to fetch seasons: ${response.status} ${response.statusText}`)
  }

  const seasons = await response.json()
  return seasons as Array<{ seasonId: number; label: string; isCurrent: boolean }>
}

/**
 * Calculates age group from birth date
 * Returns SwimCloud age group format: '0910', '1112', '1314', '1516', 'UNOV'
 */
function calculateAgeGroup(birthDate: string | Date): string {
  const birth = typeof birthDate === 'string' ? new Date(birthDate) : birthDate
  const today = new Date()
  let age = today.getFullYear() - birth.getFullYear()
  const monthDiff = today.getMonth() - birth.getMonth()
  
  if (monthDiff < 0 || (monthDiff === 0 && today.getDate() < birth.getDate())) {
    age--
  }
  
  if (age <= 10) return '0910'
  if (age <= 12) return '1112'
  if (age <= 14) return '1314'
  if (age <= 16) return '1516'
  return 'UNOV' // 17 and over
}

/**
 * Gets swimmer profile data from database
 */
async function getSwimmerProfile(supabase: ReturnType<typeof createClient>, swimmerId: string): Promise<{
  ageGroup?: string
  gender?: 'M' | 'F'
  region?: string
} | null> {
  const { data: swimmer, error } = await supabase
    .from('swimmers')
    .select('birth_date, gender')
    .eq('id', swimmerId)
    .maybeSingle()
  
  if (error || !swimmer) {
    console.warn(`Swimmer ${swimmerId} not found:`, error)
    return null
  }
  
  const profile: {
    ageGroup?: string
    gender?: 'M' | 'F'
    region?: string
  } = {}
  
  // Calculate age group from birth date
  if (swimmer.birth_date) {
    profile.ageGroup = calculateAgeGroup(swimmer.birth_date)
  }
  
  // Get gender
  if (swimmer.gender) {
    profile.gender = swimmer.gender as 'M' | 'F'
  }
  
  // Region defaults to Pacific Northwest (can be made configurable later)
  profile.region = DEFAULT_REGION
  
  return profile
}

/**
 * Builds SwimCloud API URL from parameters
 */
function buildSwimCloudApiUrl(params: {
  ageGroup?: string
  gender?: 'M' | 'F'
  eventCourse?: 'Y' | 'L'
  seasonId?: number
  region?: string
  page?: number
}): string {
  const baseUrl = 'https://www.swimcloud.com/api/performances/top_rankings/'
  const queryParams = new URLSearchParams()
  
  if (params.ageGroup) queryParams.set('agegroup', params.ageGroup)
  if (params.gender) queryParams.set('gender', params.gender)
  if (params.eventCourse) queryParams.set('event_course', params.eventCourse)
  if (params.seasonId) queryParams.set('season_id', params.seasonId.toString())
  if (params.page) queryParams.set('page', params.page.toString())
  if (params.region) queryParams.set('region', params.region)
  
  queryParams.set('sort_by', 'all') // Changed from 'top50' to 'all' to get all teams
  
  return `${baseUrl}?${queryParams.toString()}`
}

/**
 * Fetches a single page of teams from SwimCloud API
 */
async function fetchClubTeamsPage(apiUrl: string): Promise<{ teams: TeamInfo[]; hasMorePages: boolean; currentPage: number; totalPages: number }> {
  console.log(`Fetching teams from API: ${apiUrl}`)
  
  const response = await fetch(apiUrl, {
    headers: {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
      'Accept': 'application/json',
    },
  })

  if (!response.ok) {
    throw new Error(`Failed to fetch SwimCloud API: ${response.status} ${response.statusText}`)
  }

  const data: SwimCloudApiResponse = await response.json()
  
  const teams: TeamInfo[] = data.results.map((team) => ({
    name: team.name,
    swimcloud_id: team.id.toString(),
    location: team.location || (team.city && team.state ? `${team.city}, ${team.state}` : undefined),
    url: team.absolute_url ? `https://www.swimcloud.com${team.absolute_url}` : undefined,
  }))

  const hasMorePages = data.number < data.page_count

  console.log(`Page ${data.number}/${data.page_count}: Found ${teams.length} teams (Total: ${data.count})`)

  return { 
    teams, 
    hasMorePages,
    currentPage: data.number,
    totalPages: data.page_count,
  }
}

/**
 * Fetches teams from SwimCloud API
 * Handles pagination if fetchAllPages is true
 */
async function fetchClubTeams(
  params: {
    ageGroup: string
    gender: 'M' | 'F'
    eventCourse: 'Y' | 'L'
    seasonId: number
    region?: string
  },
  fetchAllPages: boolean = true
): Promise<TeamInfo[]> {
  const allTeams: TeamInfo[] = []
  let currentPage = 1
  let hasMore = true
  let totalPages = 1
  
  while (hasMore) {
      const apiUrl = buildSwimCloudApiUrl({
        ageGroup: params.ageGroup,
        gender: params.gender,
        eventCourse: params.eventCourse,
        seasonId: params.seasonId,
        region: params.region || DEFAULT_REGION,
        page: currentPage,
      })
    
    const { teams, hasMorePages, totalPages: pages } = await fetchClubTeamsPage(apiUrl)
    allTeams.push(...teams)
    totalPages = pages
    
    if (!fetchAllPages || !hasMorePages || teams.length === 0) {
      hasMore = false
    } else {
      currentPage++
      // Add a small delay to be respectful to the server
      await new Promise(resolve => setTimeout(resolve, 500))
    }
  }

  // Remove duplicates based on swimcloud_id or name
  const uniqueTeams = allTeams.filter((team, index, self) =>
    index === self.findIndex((t) => 
      (team.swimcloud_id && t.swimcloud_id === team.swimcloud_id) || 
      (!team.swimcloud_id && t.name === team.name)
    )
  )

  console.log(`Total: Found ${uniqueTeams.length} unique teams across ${currentPage} page(s)`)
  return uniqueTeams
}

/**
 * Saves teams to database
 */
async function saveTeamsToDatabase(teams: TeamInfo[]): Promise<number> {
  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)
  
  // Get a user ID for created_by field (required) - do this once before the loop
  // Use RPC function to get first user ID from auth.users
  const { data: userData, error: userError } = await supabase.rpc('get_first_user_id')
  
  if (userError || !userData) {
    console.error('Error getting user ID for created_by:', userError)
    console.error('Cannot save teams without a user ID. Please ensure at least one user exists.')
    return 0
  }
  
  const systemUserId = userData
  console.log(`Using user ID ${systemUserId} for created_by field`)
  
  let savedCount = 0
  let skippedCount = 0
  let errorCount = 0
  
  for (const team of teams) {
    try {
      // Check if team already exists by name (sportengines_id not needed)
      const { data: existing } = await supabase
        .from('teams')
        .select('id')
        .eq('name', team.name)
        .eq('team_type', 'regular')
        .maybeSingle()
      
      if (existing) {
        skippedCount++
        continue
      }
      
      // Insert new team
      const { error } = await supabase.from('teams').insert({
        name: team.name,
        location: team.location,
        team_type: 'regular',
        is_active: true,
        created_by: systemUserId,
      })
      
      if (error) {
        errorCount++
        console.error(`Error saving team "${team.name}":`, error)
      } else {
        savedCount++
      }
    } catch (error) {
      errorCount++
      console.error(`Error processing team "${team.name}":`, error)
    }
  }
  
  console.log(`Save summary: ${savedCount} saved, ${skippedCount} skipped (already exist), ${errorCount} errors`)
  return savedCount
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
    const body: ClubTeamsRequest = await req.json()
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)
    
    let fetchAllPages = body.fetchAllPages !== false // Default to true
    
    // Get swimmer profile if swimmer_id provided
    let profileData: { ageGroup?: string; gender?: 'M' | 'F'; region?: string } | null = null
    if (body.swimmer_id) {
      profileData = await getSwimmerProfile(supabase, body.swimmer_id)
      if (!profileData) {
        return new Response(
          JSON.stringify({
            success: false,
            error: `Swimmer ${body.swimmer_id} not found`,
          }),
          {
            status: 404,
            headers: {
              'Content-Type': 'application/json',
              'Access-Control-Allow-Origin': '*',
            },
          }
        )
      }
      console.log(`Using swimmer profile: ageGroup=${profileData.ageGroup}, gender=${profileData.gender}, region=${profileData.region}`)
    }
    
    // Determine parameters (manual params override profile data)
    const ageGroup = body.ageGroup || profileData?.ageGroup
    const gender = body.gender || profileData?.gender
    const region = body.region || profileData?.region || DEFAULT_REGION
    const eventCourses = body.eventCourse ? [body.eventCourse] : DEFAULT_COURSES
    
    // Fetch seasons if not provided
    let seasonIds: number[]
    if (body.seasonId) {
      seasonIds = [body.seasonId]
    } else if (body.seasons && body.seasons.length > 0) {
      seasonIds = body.seasons
    } else {
      // Fetch last 4 seasons from API
      const seasons = await fetchSeasons(10)
      seasonIds = seasons.slice(0, 4).map(s => s.seasonId)
      console.log(`Fetched seasons: ${seasonIds.join(', ')}`)
    }
    
    // Validate required parameters
    if (!ageGroup || !gender) {
      return new Response(
        JSON.stringify({
          success: false,
          error: 'Missing required parameters: ageGroup and gender are required (or provide swimmer_id)',
        }),
        {
          status: 400,
          headers: {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
          },
        }
      )
    }
    
    // If specific parameters provided, use them; otherwise use defaults
    if (body.ageGroup || body.swimmer_id) {
      // Single combination (or from swimmer profile)
      const allTeams: TeamInfo[] = []
      
      // Fetch teams for each course type and season
      for (const eventCourse of eventCourses) {
        for (const seasonId of seasonIds) {
          console.log(`Fetching: Age ${ageGroup}, ${gender}, ${eventCourse}, Season ${seasonId}, Region ${region}`)
          
          try {
            const teams = await fetchClubTeams({
              ageGroup: ageGroup!,
              gender: gender!,
              eventCourse,
              seasonId,
              region,
            }, fetchAllPages)
            allTeams.push(...teams)
            console.log(`  ✓ Found ${teams.length} teams`)
          } catch (error) {
            console.error(`  ✗ Error fetching ${ageGroup}/${gender}/${eventCourse}/Season${seasonId}:`, error)
            // Continue with next combination
          }
          
          // Delay between requests to be respectful
          await new Promise(resolve => setTimeout(resolve, 1000))
        }
      }
      
      // Remove duplicates
      const uniqueTeams = allTeams.filter((team, index, self) =>
        index === self.findIndex((t) => 
          (team.swimcloud_id && t.swimcloud_id === team.swimcloud_id) || 
          (!team.swimcloud_id && t.name === team.name)
        )
      )
      
      const savedCount = await saveTeamsToDatabase(uniqueTeams)
      
      return new Response(
        JSON.stringify({
          success: true,
          swimmer_id: body.swimmer_id,
          age_group: ageGroup,
          gender,
          region,
          courses: eventCourses,
          seasons: seasonIds,
          teams_found: uniqueTeams.length,
          teams_saved: savedCount,
          message: `Successfully fetched ${uniqueTeams.length} unique teams, saved ${savedCount} new teams`,
        }),
        {
          status: 200,
          headers: {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
          },
        }
      )
    } else {
      // Default: fetch all combinations (bulk import mode)
      // This mode requires explicit parameters
      const ageGroups = body.ageGroup ? [body.ageGroup] : ['0910', '1112', '1314', '1516']
      const genders: ('M' | 'F')[] = body.gender ? [body.gender] : ['F']
      const courses: ('Y' | 'L')[] = body.eventCourse ? [body.eventCourse] : DEFAULT_COURSES
      const region = body.region || DEFAULT_REGION
      
      // Fetch seasons if not provided
      let seasonIds: number[]
      if (body.seasonId) {
        seasonIds = [body.seasonId]
      } else if (body.seasons && body.seasons.length > 0) {
        seasonIds = body.seasons
      } else {
        // Fetch last 4 seasons from API
        const seasons = await fetchSeasons(10)
        seasonIds = seasons.slice(0, 4).map(s => s.seasonId)
        console.log(`Fetched seasons: ${seasonIds.join(', ')}`)
      }
      
      const allTeams: TeamInfo[] = []
      let totalRequests = 0
      
      console.log(`Fetching teams for:`)
      console.log(`  Age groups: ${ageGroups.join(', ')}`)
      console.log(`  Genders: ${genders.join(', ')}`)
      console.log(`  Courses: ${courses.join(', ')}`)
      console.log(`  Seasons: ${seasonIds.join(', ')}`)
      console.log(`  Region: ${region}`)
      console.log(`  Total combinations: ${ageGroups.length * genders.length * courses.length * seasonIds.length}`)
      
      for (const ageGroup of ageGroups) {
        for (const gender of genders) {
          for (const course of courses) {
            for (const seasonId of seasonIds) {
              totalRequests++
              console.log(`[${totalRequests}] Fetching: Age ${ageGroup}, ${gender}, ${course}, Season ${seasonId}, Region ${region}`)
              
              try {
                const teams = await fetchClubTeams({
                  ageGroup,
                  gender,
                  eventCourse: course,
                  seasonId,
                  region,
                }, fetchAllPages)
                allTeams.push(...teams)
                console.log(`  ✓ Found ${teams.length} teams`)
              } catch (error) {
                console.error(`  ✗ Error fetching ${ageGroup}/${gender}/${course}/Season${seasonId}:`, error)
                // Continue with next combination
              }
              
              // Delay between requests to be respectful
              await new Promise(resolve => setTimeout(resolve, 1000))
            }
          }
        }
      }
      
      // Remove duplicates and save
      const uniqueTeams = allTeams.filter((team, index, self) =>
        index === self.findIndex((t) => 
          (team.swimcloud_id && t.swimcloud_id === team.swimcloud_id) || 
          (!team.swimcloud_id && t.name === team.name)
        )
      )
      
      console.log(`\nTotal unique teams found: ${uniqueTeams.length} (from ${allTeams.length} total entries)`)
      
      const savedCount = await saveTeamsToDatabase(uniqueTeams)
      
      return new Response(
        JSON.stringify({
          success: true,
          age_groups: ageGroups,
          genders,
          courses,
          seasons: seasonIds,
          total_combinations: totalRequests,
          teams_found: uniqueTeams.length,
          teams_saved: savedCount,
          message: `Successfully fetched ${uniqueTeams.length} unique teams across ${totalRequests} combinations, saved ${savedCount} new teams`,
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

    // This should not be reached due to the if/else structure above
    // But keeping for safety
    return new Response(
      JSON.stringify({
        success: false,
        error: 'Invalid request parameters',
      }),
      {
        status: 400,
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
