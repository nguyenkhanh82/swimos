import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

interface PracticeRequest {
  swimmer_id: string;
  goal_id: string;
  current_time?: number;
  target_time?: number;
  stroke?: string;
  distance?: number;
  pool_type?: string;
}

interface TrainingSet {
  set_description: string;
  stroke: string;
  distance_per_rep: number;
  number_of_reps: number;
  total_distance: number;
  rest_seconds: number;
  intensity: "easy" | "moderate" | "hard" | "race_pace";
  rationale: string;
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization") || req.headers.get("authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: "Missing authorization header" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const token = authHeader.replace(/^Bearer\s+/i, "");
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY");
    const GROQ_API_KEY = Deno.env.get("GROQ_API_KEY");

    if (!supabaseUrl || !supabaseAnonKey) {
      return new Response(
        JSON.stringify({ error: "Missing Supabase configuration" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (!GROQ_API_KEY) {
      return new Response(
        JSON.stringify({ error: "GROQ_API_KEY not configured" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const supabase = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader } },
      auth: { persistSession: false, autoRefreshToken: false, detectSessionInUrl: false },
    });

    // Validate user
    const { data: { user }, error: userError } = await supabase.auth.getUser(token);
    if (userError || !user) {
      return new Response(
        JSON.stringify({ error: "Invalid or expired JWT token" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const request: PracticeRequest = await req.json();
    const { swimmer_id, goal_id, current_time, target_time, stroke, distance, pool_type } = request;

    if (!swimmer_id || !goal_id) {
      return new Response(
        JSON.stringify({ error: "swimmer_id and goal_id are required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Get goal details
    const { data: goal, error: goalError } = await supabase
      .from("training_goals")
      .select("*")
      .eq("id", goal_id)
      .eq("swimmer_id", swimmer_id)
      .single();

    if (goalError || !goal) {
      return new Response(
        JSON.stringify({ error: "Goal not found" }),
        { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Get current best time if not provided
    let currentBestTime = current_time;
    if (!currentBestTime && goal.goal_type === "time") {
      const eventName = `${goal.distance} ${goal.stroke}`;
      const { data: bestTime } = await supabase
        .from("swim_times")
        .select("time_seconds")
        .eq("swimmer_id", swimmer_id)
        .eq("event_name", eventName)
        .eq("pool_type", pool_type || goal.pool_type || "SCY")
        .order("time_seconds", { ascending: true })
        .limit(1)
        .single();

      if (bestTime) {
        currentBestTime = bestTime.time_seconds;
      }
    }

    if (!currentBestTime) {
      return new Response(
        JSON.stringify({ error: "Current time not found. Please provide current_time or ensure swimmer has times recorded." }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const targetTime = target_time || goal.target_time_seconds;
    if (!targetTime) {
      return new Response(
        JSON.stringify({ error: "Target time is required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const improvement = currentBestTime - targetTime;
    const percentImprovement = (improvement / currentBestTime) * 100;

    const eventStroke = stroke || goal.stroke || "Free";
    const eventDistance = distance || goal.distance || 100;
    const eventPoolType = pool_type || goal.pool_type || "SCY";

    // Build prompt for Groq
    const systemPrompt = `You are an expert swim coach AI that creates personalized training practices based on specific time improvement goals.

Your task is to generate ONE complete training practice (made up of 4-6 sequential sets) that will help a swimmer improve their time from their current performance to their target time.

The practice MUST be logically structured in this order:
1. Warm up
2. Technique/Drills
3. Main Set (specifically targeting the goal pacework, speed, or endurance)
4. Cool down

Each individual set in this practice should be specific, measurable, and related to achieving the time improvement goal. Make it challenging but realistic based on the required improvement percent.`;

    const userPrompt = `Swimmer Goal Analysis:
- Event: ${eventDistance} ${eventStroke} (${eventPoolType})
- Current Time: ${currentBestTime.toFixed(2)}s
- Target Time: ${targetTime.toFixed(2)}s
- Improvement Needed: ${improvement.toFixed(2)}s (${percentImprovement.toFixed(1)}% improvement)

Generate a single complete practice structure containing 4-6 sequential sets. Each set in the JSON array should include:
- set_description: A concise name like "400 Warm up mixed", "8x100 Free @1:30 (Main Set)", or "200 Cool down"
- stroke: The specific stroke (e.g., Freestyle, Backstroke, IM, Drill, Kick, Mixed)
- distance_per_rep: Distance in meters/yards for each rep
- number_of_reps: How many reps
- total_distance: Total meters/yards for this specific set
- rest_seconds: Rest between reps or sets (10-120 seconds)
- intensity: One of easy, moderate, hard, race_pace
- rationale: A brief 1-sentence explanation of what phase of the practice this is and how it helps the overarching goal.

Ensure the "suggestions" array represents the cronological order of a single complete practice (Warm up -> Drills -> Main Set -> Cool down).`;

    console.log("🚀 Calling Groq API for practice generation...");
    const groqStartTime = Date.now();

    const response = await fetch("https://api.groq.com/openai/v1/chat/completions", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${GROQ_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: "llama-3.3-70b-versatile",
        messages: [
          { role: "system", content: systemPrompt },
          { role: "user", content: userPrompt },
        ],
        temperature: 0.7,
        response_format: { type: "json_object" },
      }),
    });

    const groqEndTime = Date.now();
    console.log(`⏱️ Groq Response Time: ${groqEndTime - groqStartTime}ms`);

    if (!response.ok) {
      const errorText = await response.text();
      console.error("❌ Groq API Error:", response.status, errorText);
      return new Response(
        JSON.stringify({ error: `Groq API error: ${response.status} - ${errorText}` }),
        { status: response.status, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const data = await response.json();
    const content = data.choices?.[0]?.message?.content;

    if (!content) {
      return new Response(
        JSON.stringify({ error: "No response from Groq API" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    let suggestions: { suggestions: TrainingSet[] };
    try {
      suggestions = JSON.parse(content);
    } catch (e) {
      console.error("Error parsing Groq response:", e);
      return new Response(
        JSON.stringify({ error: "Invalid response format from Groq API" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (!suggestions.suggestions || !Array.isArray(suggestions.suggestions)) {
      return new Response(
        JSON.stringify({ error: "Invalid suggestions format" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    return new Response(
      JSON.stringify({
        success: true,
        goal_id: goal_id,
        current_time: currentBestTime,
        target_time: targetTime,
        improvement: improvement,
        percent_improvement: percentImprovement,
        suggestions: suggestions.suggestions,
      }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );

  } catch (error: unknown) {
    console.error("Error in generate-practice-from-goal function:", error);
    const errorMessage = error instanceof Error ? error.message : "Unknown error";
    return new Response(
      JSON.stringify({ error: errorMessage }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
