import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

interface SwimTime {
  event_name: string;
  time_seconds: number;
}

interface RacePlanRequest {
  event: string;
  distance: number;
  targetTime: number;
  personalBests: SwimTime[];
  poolType: string;
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const { event, distance, targetTime, personalBests, poolType } = await req.json() as RacePlanRequest;
    
    const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY");
    const GEMINI_API_KEY = Deno.env.get("GEMINI_API_KEY");
    
    // Prefer OpenAI, fallback to Gemini
    const apiKey = OPENAI_API_KEY || GEMINI_API_KEY;
    const useGemini = !OPENAI_API_KEY && !!GEMINI_API_KEY;
    
    if (!apiKey) {
      throw new Error("OPENAI_API_KEY or GEMINI_API_KEY must be configured");
    }

    // Format personal bests for context
    const pbContext = personalBests.length > 0 
      ? personalBests.map(pb => `${pb.event_name}: ${formatTime(pb.time_seconds)}`).join(", ")
      : "No personal bests recorded yet";

    const targetTimeFormatted = formatTime(targetTime);

    const systemPrompt = `You are an expert swimming coach specializing in race strategy and pacing. 
You provide detailed, actionable race plans for competitive swimmers.
Always be encouraging but realistic based on their current abilities.
Format your response with clear sections using markdown headers.`;

    const userPrompt = `Create a detailed race plan for the following:

**Event:** ${event}
**Distance:** ${distance}m
**Target Time:** ${targetTimeFormatted}
**Pool Type:** ${poolType}
**Swimmer's Personal Bests:** ${pbContext}

Please provide:
1. **Pre-Race Preparation** - Warm-up routine and mental preparation
2. **Race Strategy** - Split times for each 25m/50m segment with pacing notes
3. **Technical Focus Points** - Key technique elements for each phase (start, turns, finish)
4. **Energy Management** - How to pace effort throughout the race
5. **Common Mistakes to Avoid** - Specific to this event distance
6. **Mental Cues** - Short phrases to focus on during the race

Make the plan specific to the ${distance}m ${event.split(' ').pop()} event and realistic based on their target time.`;

    console.log("Generating race plan for:", event, "target:", targetTimeFormatted);

    let response;
    
    if (useGemini) {
      // Use Google Gemini API
      response = await fetch(`https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${apiKey}`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          contents: [{
            parts: [{
              text: `${systemPrompt}\n\n${userPrompt}`
            }]
          }],
          generationConfig: {
            temperature: 0.7,
          },
        }),
      });
    } else {
      // Use OpenAI API
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
          stream: false,
        }),
      });
    }

    if (!response.ok) {
      const errorText = await response.text();
      console.error("AI API error:", response.status, errorText);
      
      if (response.status === 429) {
        return new Response(
          JSON.stringify({ error: "Rate limit exceeded. Please try again in a moment." }),
          { status: 429, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }
      if (response.status === 401 || response.status === 403) {
        return new Response(
          JSON.stringify({ error: "API key is invalid or expired. Please check your API key configuration." }),
          { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }
      
      throw new Error(`AI API error: ${response.status} - ${errorText}`);
    }

    const data = await response.json();
    
    let racePlan;
    if (useGemini) {
      // Gemini response format
      racePlan = data.candidates?.[0]?.content?.parts?.[0]?.text || "Unable to generate race plan.";
    } else {
      // OpenAI response format
      racePlan = data.choices?.[0]?.message?.content || "Unable to generate race plan.";
    }

    console.log("Race plan generated successfully");

    return new Response(
      JSON.stringify({ racePlan }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("Error in generate-race-plan:", error);
    return new Response(
      JSON.stringify({ error: error instanceof Error ? error.message : "Unknown error occurred" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});

function formatTime(seconds: number): string {
  const mins = Math.floor(seconds / 60);
  const secs = seconds % 60;
  if (mins > 0) {
    return `${mins}:${secs.toFixed(2).padStart(5, '0')}`;
  }
  return secs.toFixed(2);
}
