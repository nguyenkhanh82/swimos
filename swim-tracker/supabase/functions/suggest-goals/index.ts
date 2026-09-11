import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

interface PersonalRecord {
  stroke: string;
  distance: number;
  poolType: string;
  bestTime: number;
  recordDate: string;
  currentStandard?: string;
  nextStandard?: string;
}

interface TrainingAnalysis {
  totalSets: number;
  avgSetDistance: number;
  strokeBreakdown: Record<string, number>;
  intensityBreakdown: Record<string, number>;
  recentActivity: number; // sets in last 30 days
  consistencyScore: number; // 0-100
  personalRecords: PersonalRecord[];
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    // Get authorization header (case-insensitive)
    const authHeader = req.headers.get("Authorization") || req.headers.get("authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: "Missing authorization header" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Extract token from Bearer header
    const token = authHeader.replace(/^Bearer\s+/i, "");
    console.log("🔑 Extracted token, length:", token.length);
    
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY");

    if (!supabaseUrl || !supabaseAnonKey) {
      console.error("Missing Supabase config - URL:", !!supabaseUrl, "AnonKey:", !!supabaseAnonKey);
      return new Response(
        JSON.stringify({ error: "Missing Supabase configuration" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Use anon key with user's JWT - this respects RLS and properly authenticates
    // Create client without trying to read request body
    const supabase = createClient(supabaseUrl, supabaseAnonKey, {
      global: {
        headers: { Authorization: authHeader },
      },
      auth: {
        persistSession: false,
        autoRefreshToken: false,
        detectSessionInUrl: false,
      },
    });

    // Get user from auth token - pass token directly to getUser()
    console.log("🔍 Validating JWT and getting user...");
    let user;
    let userError;
    
    try {
      const result = await supabase.auth.getUser(token);
      user = result.data.user;
      userError = result.error;
    } catch (e) {
      console.error("Exception getting user:", e);
      userError = e as Error;
      user = null;
    }
    if (userError || !user) {
      console.error("Auth error details:", {
        error: userError,
        hasUser: !!user,
        authHeaderPrefix: authHeader?.substring(0, 20),
        supabaseUrl: supabaseUrl?.substring(0, 30),
        hasAnonKey: !!supabaseAnonKey,
      });
      return new Response(
        JSON.stringify({ 
          error: "Invalid or expired JWT token",
          details: userError?.message || "User not found"
        }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Analyze training history
    const trainingAnalysis = await analyzeTrainingHistory(supabase, user.id);

    // Get existing goals to avoid duplicates
    const { data: existingGoals } = await supabase
      .from('training_goals')
      .select('*')
      .eq('user_id', user.id)
      .eq('is_active', true);

    // Get AI suggestions
    const suggestions = await getAISuggestions(trainingAnalysis, existingGoals || []);

    return new Response(
      JSON.stringify({ suggestions, analysis: trainingAnalysis }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (error: unknown) {
    console.error("Error in suggest-goals function:", error);
    const errorMessage = error instanceof Error ? error.message : "Unknown error";
    return new Response(
      JSON.stringify({ error: errorMessage }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});

async function analyzeTrainingHistory(supabase: any, userId: string): Promise<TrainingAnalysis> {
  // Get all training sets
  const { data: trainingSets, error: setsError } = await supabase
    .from('training_sets')
    .select('*')
    .eq('user_id', userId)
    .order('training_date', { ascending: false })
    .limit(200);

  if (setsError) throw setsError;

  const sets = trainingSets || [];
  const totalSets = sets.length;

  if (totalSets === 0) {
    return {
      totalSets: 0,
      avgSetDistance: 0,
      strokeBreakdown: {},
      intensityBreakdown: {},
      recentActivity: 0,
      consistencyScore: 0,
      personalRecords: [],
    };
  }

  // Calculate averages and breakdowns
  const totalDistance = sets.reduce((sum: number, set: any) => sum + (set.total_distance || 0), 0);
  const avgSetDistance = Math.round(totalDistance / totalSets);

  const strokeBreakdown: Record<string, number> = {};
  const intensityBreakdown: Record<string, number> = {};

  sets.forEach((set: any) => {
    const stroke = set.stroke || 'Unknown';
    strokeBreakdown[stroke] = (strokeBreakdown[stroke] || 0) + (set.total_distance || 0);

    const intensity = set.intensity || 'moderate';
    intensityBreakdown[intensity] = (intensityBreakdown[intensity] || 0) + 1;
  });

  // Recent activity (last 30 days)
  const thirtyDaysAgo = new Date();
  thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
  const recentSets = sets.filter((set: any) => {
    const setDate = new Date(set.training_date);
    return setDate >= thirtyDaysAgo;
  });
  const recentActivity = recentSets.length;

  // Consistency score (sets per week in last 30 days)
  const consistencyScore = Math.min(100, Math.round((recentActivity / 4) * 100 / 12)); // Aim for 12 sets/month

  // Calculate personal records from splits
  const personalRecords = await calculatePersonalRecords(supabase, userId);

  return {
    totalSets,
    avgSetDistance,
    strokeBreakdown,
    intensityBreakdown,
    recentActivity,
    consistencyScore,
    personalRecords,
  };
}

async function calculatePersonalRecords(supabase: any, userId: string): Promise<PersonalRecord[]> {
  // Get all splits grouped by event
  const { data: splits, error: splitsError } = await supabase
    .from('training_set_splits')
    .select(`
      id,
      rep_number,
      time_seconds,
      created_at,
      training_sets:training_set_id (
        stroke,
        distance_per_rep,
        pool_type,
        training_date
      )
    `)
    .eq('user_id', userId);

  if (splitsError || !splits || splits.length === 0) {
    return [];
  }

  // Group by event (stroke + distance + pool type)
  const eventPRs: Map<string, PersonalRecord> = new Map();

  splits.forEach((split: any) => {
    if (!split.training_sets) return;

    const stroke = split.training_sets.stroke;
    const distance = split.training_sets.distance_per_rep;
    const poolType = split.training_sets.pool_type || 'SCY';
    const time = split.time_seconds;
    const date = split.training_sets.training_date;

    const eventKey = `${stroke}-${distance}-${poolType}`;

    if (!eventPRs.has(eventKey) || eventPRs.get(eventKey)!.bestTime > time) {
      eventPRs.set(eventKey, {
        stroke,
        distance,
        poolType,
        bestTime: time,
        recordDate: date,
      });
    }
  });

  // Get time standards for PR comparison
  const prs = Array.from(eventPRs.values());

  for (const pr of prs) {
    const { data: standards } = await supabase
      .from('time_standards')
      .select('standard_level')
      .eq('stroke', pr.stroke)
      .eq('distance', pr.distance)
      .eq('course', pr.poolType)
      .gte('time_seconds', pr.bestTime)
      .order('time_seconds', { ascending: true })
      .limit(1);

    if (standards && standards.length > 0) {
      pr.currentStandard = standards[0].standard_level;

      // Get next standard
      const standardLevels = ['B', 'BB', 'A', 'AA', 'AAA', 'AAAA', 'AAAAA'];
      const currentIndex = standardLevels.indexOf(pr.currentStandard);
      if (currentIndex >= 0 && currentIndex < standardLevels.length - 1) {
        pr.nextStandard = standardLevels[currentIndex + 1];
      }
    }
  }

  return prs;
}

async function getAISuggestions(analysis: TrainingAnalysis, existingGoals: any[]): Promise<any[]> {
  console.log('🤖 getAISuggestions: Starting AI suggestion generation');
  const GROQ_API_KEY = Deno.env.get("GROQ_API_KEY");
  const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY");
  const GEMINI_API_KEY = Deno.env.get("GEMINI_API_KEY");

  // Priority: Groq (open source) -> OpenAI -> Gemini -> Rule-based
  const apiKey = GROQ_API_KEY || OPENAI_API_KEY || GEMINI_API_KEY;
  const useGroq = !!GROQ_API_KEY;
  const useGemini = !GROQ_API_KEY && !OPENAI_API_KEY && !!GEMINI_API_KEY;

  console.log('🔑 API Key Status:', {
    hasGroq: !!GROQ_API_KEY,
    hasOpenAI: !!OPENAI_API_KEY,
    hasGemini: !!GEMINI_API_KEY,
    selectedProvider: useGroq ? 'Groq' : useGemini ? 'Gemini' : OPENAI_API_KEY ? 'OpenAI' : 'None',
  });

  if (!apiKey) {
    console.log('⚠️ No API key found, using rule-based suggestions');
    // Fallback to rule-based suggestions if no API key
    return getRuleBasedSuggestions(analysis, existingGoals);
  }

  const systemPrompt = `You are an expert swim coach AI that suggests personalized training goals.
Based on the swimmer's training history, personal records, and current time standards, suggest 2-4 SMART goals that will help them improve.

Consider:
1. Personal records and potential improvements
2. Time standards they can realistically achieve next
3. Balanced stroke development
4. Consistency and volume goals if training is irregular
5. Don't duplicate existing active goals

Each suggestion should include:
- title: Clear, motivating goal title
- goalType: One of "time", "distance", "frequency", "custom"
- stroke: Stroke name if applicable (omit if not applicable)
- distance: Distance in meters if applicable (omit if not applicable)
- targetTimeSeconds: Target time for time-based goals (omit if not applicable)
- targetDistance: Total distance for distance goals (omit if not applicable)
- targetFrequency: Number of sessions for frequency goals (omit if not applicable)
- frequencyPeriod: "week" or "month" - ONLY include this field when goalType is "frequency", otherwise omit it completely
- targetDate: Recommended date (YYYY-MM-DD format, 1-3 months from now)
- rationale: Brief explanation of why this goal is recommended
- priority: "high", "medium", or "low"

IMPORTANT: Only include fields that are relevant to the goalType. For example:
- If goalType is "time": include stroke, distance, targetTimeSeconds
- If goalType is "distance": include targetDistance
- If goalType is "frequency": include targetFrequency and frequencyPeriod
- If goalType is "custom": include only title, rationale, priority, targetDate
Do NOT include empty strings or zero values for fields that don't apply.`;

  const userPrompt = `Here's the swimmer's data:

Training Analysis:
- Total sets completed: ${analysis.totalSets}
- Average set distance: ${analysis.avgSetDistance}m
- Recent activity (last 30 days): ${analysis.recentActivity} sets
- Consistency score: ${analysis.consistencyScore}/100
- Stroke breakdown: ${JSON.stringify(analysis.strokeBreakdown)}

Personal Records:
${analysis.personalRecords.map(pr =>
  `- ${pr.distance}${pr.stroke} (${pr.poolType}): ${formatTime(pr.bestTime)}${pr.currentStandard ? ` [${pr.currentStandard}]` : ''}${pr.nextStandard ? ` → Next: ${pr.nextStandard}` : ''}`
).join('\n')}

Existing Active Goals:
${existingGoals.length > 0 ? existingGoals.map(g => `- ${g.title} (${g.goal_type})`).join('\n') : 'None'}

Please suggest 2-4 new training goals for this swimmer.`;

  let response;

  if (useGemini) {
    response = await fetch(`https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${apiKey}`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        contents: [{
          parts: [{
            text: `${systemPrompt}\n\n${userPrompt}\n\nPlease respond with a JSON object containing a "suggestions" array with the goal suggestions.`
          }]
        }],
        generationConfig: {
          temperature: 0.7,
          responseMimeType: "application/json",
        },
      }),
    });
  } else if (useGroq) {
    // Use Groq API with Llama 3.3 70B (OpenAI-compatible, open source)
    console.log('🚀 Calling Groq API...');
    console.log('📤 Groq Request URL: https://api.groq.com/openai/v1/chat/completions');
    console.log('📤 Groq Model: llama-3.3-70b-versatile');
    console.log('📤 Groq System Prompt Length:', systemPrompt.length);
    console.log('📤 Groq User Prompt Length:', userPrompt.length);
    
    const groqStartTime = Date.now();
    response = await fetch("https://api.groq.com/openai/v1/chat/completions", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: "llama-3.3-70b-versatile",
        messages: [
          { role: "system", content: systemPrompt },
          { role: "user", content: userPrompt },
        ],
        tools: [
          {
            type: "function",
            function: {
              name: "suggest_goals",
              description: "Return training goal suggestions",
              parameters: {
                type: "object",
                properties: {
                  suggestions: {
                    type: "array",
                    items: {
                      type: "object",
                      properties: {
                        title: { type: "string" },
                        goalType: { type: "string", enum: ["time", "distance", "frequency", "custom"] },
                        stroke: { type: "string" },
                        distance: { type: "number" },
                        targetTimeSeconds: { type: "number" },
                        targetDistance: { type: "number" },
                        targetFrequency: { type: "number" },
                        frequencyPeriod: { 
                          type: "string", 
                          enum: ["week", "month"],
                          description: "Only include this field when goalType is 'frequency'. Omit it for all other goal types."
                        },
                        targetDate: { type: "string" },
                        rationale: { type: "string" },
                        priority: { type: "string", enum: ["high", "medium", "low"] },
                      },
                      required: ["title", "goalType", "rationale", "priority"],
                    },
                  },
                },
                required: ["suggestions"],
              },
            },
          },
        ],
        tool_choice: "auto",
        temperature: 0.7,
      }),
    });
    const groqEndTime = Date.now();
    console.log('📥 Groq Response Status:', response.status);
    console.log('⏱️ Groq Response Time:', groqEndTime - groqStartTime, 'ms');
    if (!response.ok) {
      const errorText = await response.text();
      console.error('❌ Groq API Error:', response.status, errorText);
    } else {
      console.log('✅ Groq API Success');
    }
  } else {
    // Use OpenAI API
    console.log('🚀 Calling OpenAI API...');
    console.log('📤 OpenAI Request URL: https://api.openai.com/v1/chat/completions');
    console.log('📤 OpenAI Model: gpt-4o-mini');
    const openaiStartTime = Date.now();
    response = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: "gpt-4o-mini",
        messages: [
          { role: "system", content: systemPrompt },
          { role: "user", content: userPrompt },
        ],
        tools: [
          {
            type: "function",
            function: {
              name: "suggest_goals",
              description: "Return training goal suggestions",
              parameters: {
                type: "object",
                properties: {
                  suggestions: {
                    type: "array",
                    items: {
                      type: "object",
                      properties: {
                        title: { type: "string" },
                        goalType: { type: "string", enum: ["time", "distance", "frequency", "custom"] },
                        stroke: { type: "string" },
                        distance: { type: "number" },
                        targetTimeSeconds: { type: "number" },
                        targetDistance: { type: "number" },
                        targetFrequency: { type: "number" },
                        frequencyPeriod: { 
                          type: "string", 
                          enum: ["week", "month"],
                          description: "Only include this field when goalType is 'frequency'. Omit it for all other goal types."
                        },
                        targetDate: { type: "string" },
                        rationale: { type: "string" },
                        priority: { type: "string", enum: ["high", "medium", "low"] },
                      },
                      required: ["title", "goalType", "rationale", "priority"],
                    },
                  },
                },
                required: ["suggestions"],
              },
            },
          },
        ],
        tool_choice: { type: "function", function: { name: "suggest_goals" } },
      }),
    });
    const openaiEndTime = Date.now();
    console.log('📥 OpenAI Response Status:', response.status);
    console.log('⏱️ OpenAI Response Time:', openaiEndTime - openaiStartTime, 'ms');
    if (!response.ok) {
      const errorText = await response.text();
      console.error('❌ OpenAI API Error:', response.status, errorText);
    } else {
      console.log('✅ OpenAI API Success');
    }
  }

  if (!response.ok) {
    console.error("AI API error:", response.status);
    const errorText = await response.text();
    console.error("AI API error details:", errorText);
    return getRuleBasedSuggestions(analysis, existingGoals);
  }

  console.log('📥 Parsing AI API response...');
  const data = await response.json();
  console.log('📊 AI Response keys:', Object.keys(data));

  if (useGemini) {
    console.log('📥 Processing Gemini response...');
    const text = data.candidates?.[0]?.content?.parts?.[0]?.text;
    if (text) {
      console.log('📊 Gemini response text length:', text.length);
      const result = JSON.parse(text);
      console.log('✅ Gemini parsed, suggestions count:', result.suggestions?.length || 0);
      // Clean up suggestions: remove invalid frequencyPeriod values
      const cleanedSuggestions = (result.suggestions || []).map((s: any) => {
        // Remove frequencyPeriod if it's empty or if goalType is not "frequency"
        if (s.goalType !== "frequency" || !s.frequencyPeriod || s.frequencyPeriod === "") {
          const { frequencyPeriod, ...rest } = s;
          return rest;
        }
        return s;
      });
      return cleanedSuggestions;
    }
    console.log('⚠️ No text in Gemini response');
  } else {
    // OpenAI and Groq both use the same response format
    console.log('📥 Processing OpenAI/Groq response...');
    console.log('📊 Response structure:', {
      hasChoices: !!data.choices,
      choicesLength: data.choices?.length || 0,
    });
    const toolCall = data.choices?.[0]?.message?.tool_calls?.[0];
    if (toolCall?.function?.arguments) {
      console.log('📊 Tool call function name:', toolCall.function.name);
      console.log('📊 Tool call arguments length:', toolCall.function.arguments.length);
      const result = JSON.parse(toolCall.function.arguments);
      console.log('✅ Parsed tool call, suggestions count:', result.suggestions?.length || 0);
      // Clean up suggestions: remove invalid frequencyPeriod values
      const cleanedSuggestions = (result.suggestions || []).map((s: any) => {
        // Remove frequencyPeriod if it's empty or if goalType is not "frequency"
        if (s.goalType !== "frequency" || !s.frequencyPeriod || s.frequencyPeriod === "") {
          const { frequencyPeriod, ...rest } = s;
          return rest;
        }
        return s;
      });
      return cleanedSuggestions;
    }
    console.log('⚠️ No tool call in OpenAI/Groq response');
    console.log('📊 Full response:', JSON.stringify(data, null, 2));
  }

  console.log('⚠️ Falling back to rule-based suggestions');
  return getRuleBasedSuggestions(analysis, existingGoals);
}

function getRuleBasedSuggestions(analysis: TrainingAnalysis, existingGoals: any[]): any[] {
  const suggestions: any[] = [];
  const now = new Date();
  const twoMonthsFromNow = new Date(now);
  twoMonthsFromNow.setMonth(twoMonthsFromNow.getMonth() + 2);

  // Consistency goal if not training regularly
  if (analysis.consistencyScore < 60 && !existingGoals.some(g => g.goal_type === 'frequency')) {
    suggestions.push({
      title: "Build Training Consistency",
      goalType: "frequency",
      targetFrequency: 12,
      frequencyPeriod: "month",
      targetDate: twoMonthsFromNow.toISOString().split('T')[0],
      rationale: "Regular training is the foundation for improvement. Aim for 3 sessions per week.",
      priority: "high",
    });
  }

  // PR improvement goals
  const topPRs = analysis.personalRecords
    .filter(pr => pr.nextStandard)
    .slice(0, 2);

  topPRs.forEach(pr => {
    if (!existingGoals.some(g => g.stroke === pr.stroke && g.distance === pr.distance)) {
      const improvement = pr.bestTime * 0.02; // 2% improvement
      suggestions.push({
        title: `${pr.distance}${pr.stroke} - Reach ${pr.nextStandard} Standard`,
        goalType: "time",
        stroke: pr.stroke,
        distance: pr.distance,
        targetTimeSeconds: pr.bestTime - improvement,
        targetDate: twoMonthsFromNow.toISOString().split('T')[0],
        rationale: `Your current best is ${formatTime(pr.bestTime)} (${pr.currentStandard}). Target ${pr.nextStandard} standard.`,
        priority: "high",
      });
    }
  });

  // Volume goal if training regularly
  if (analysis.consistencyScore >= 60 && analysis.avgSetDistance > 0) {
    const targetDistance = Math.round(analysis.avgSetDistance * 20 / 1000) * 1000; // Round to nearest 1000
    if (!existingGoals.some(g => g.goal_type === 'distance')) {
      suggestions.push({
        title: `Swim ${targetDistance}m Per Month`,
        goalType: "distance",
        targetDistance,
        distancePeriod: "month",
        targetDate: twoMonthsFromNow.toISOString().split('T')[0],
        rationale: "Build endurance and consistency with a monthly distance goal.",
        priority: "medium",
      });
    }
  }

  return suggestions.slice(0, 4);
}

function formatTime(seconds: number): string {
  const mins = Math.floor(seconds / 60);
  const secs = (seconds % 60).toFixed(2);
  return mins > 0 ? `${mins}:${secs.padStart(5, '0')}` : `${secs}s`;
}
