import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

interface PracticeRequest {
  swimmer_id: string;
  prompt: string;
  training_type?: string;
  equipment_type?: string;
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

    if (!supabaseUrl || !supabaseAnonKey || !GROQ_API_KEY) {
      return new Response(
        JSON.stringify({ error: "Missing server configuration" }),
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
    const { prompt, training_type = 'Water', equipment_type = 'Bodyweight' } = request;

    if (!prompt) {
      return new Response(
        JSON.stringify({ error: "prompt is required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Build prompt for Groq
    const isDryland = training_type === 'Dryland';

    let systemPrompt = `You are an expert swim coach AI that creates personalized training practices based on a user's prompt.

Your task is to generate ONE complete training practice (made up of 4-6 sequential sets) that fulfills the user's request.

The practice MUST be logically structured in this order:
1. Warm up
2. Technique/Drills
3. Main Set
4. Cool down

Each individual set in this practice should be specific, measurable, and related to achieving the prompt's request. Make it challenging but realistic.`;

    if (isDryland) {
      systemPrompt = `You are an expert swim coach and strength conditioning AI that creates personalized Dryland training tailored for swimmers.

Your task is to generate ONE complete Dryland body-conditioning practice (4-6 sequential sets) focusing on exercises that directly benefit a swimmer's athletic performance in the water. DO NOT generate dryland for other sports.

The user will specify equipment available. The available equipment is: ${equipment_type}. DO NOT suggest exercises that require equipment other than this.

Structure:
1. Warm up (dynamic stretching/mobility)
2. Core/Activation
3. Main Strength/Conditioning Set
4. Cool down / Stretching`;
    }

    const userPrompt = `User Request:
${prompt}

Generate a single complete practice structure containing 4-6 sequential sets. Return ONLY a JSON object with a "suggestions" array.
Each set in the "suggestions" JSON array MUST include exactly these fields:
- set_description: ${isDryland ? 'A concise specific name/amount like "20x Squat jumps", "3x Plank 1min (Core Set)", "Band Pulls"' : 'A concise name like "400 Warm up mixed", "8x100 Free @1:30 (Main Set)", or "200 Cool down"'}
- stroke: ${isDryland ? 'Always use the exact string "Dryland"' : 'The specific stroke (e.g., Freestyle, Backstroke, IM, Drill, Kick, Mixed)'}
- distance_per_rep: ${isDryland ? '0' : 'Distance in meters/yards for each rep (number)'}
- number_of_reps: How many reps (number)
- total_distance: ${isDryland ? '0' : 'Total meters/yards for this specific set (number)'}
- rest_seconds: Rest between reps or sets in seconds (number)
- intensity: Exact string, ONE of: "easy", "moderate", "hard", "race_pace"
- rationale: A brief 1-sentence explanation of what phase of the practice this is and how it aligns with the user's request.`;

    console.log("🚀 Calling Groq API for generic practice generation...");

    // We can also inject SWimmer's best times if we want, but for now generic prompt is fine.

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

    if (!response.ok) {
      const errorText = await response.text();
      return new Response(
        JSON.stringify({ error: `Groq error: ${response.status} - ${errorText}` }),
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

    let parsedConfig;
    try {
      parsedConfig = JSON.parse(content);
    } catch (e) {
      console.error("Error parsing Groq response:", e);
      return new Response(
        JSON.stringify({ error: "Invalid response format from Groq API", raw: content }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (!parsedConfig.suggestions || !Array.isArray(parsedConfig.suggestions)) {
      return new Response(
        JSON.stringify({ error: "Invalid suggestions format" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    return new Response(
      JSON.stringify({
        success: true,
        suggestions: parsedConfig.suggestions,
      }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );

  } catch (error: any) {
    console.error("Error in generate-practice function:", error);
    return new Response(
      JSON.stringify({ error: "Internal server error", details: error.message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
