import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const { historicalData, goals } = await req.json();
    const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY");
    const GEMINI_API_KEY = Deno.env.get("GEMINI_API_KEY");
    
    // Prefer OpenAI, fallback to Gemini
    const apiKey = OPENAI_API_KEY || GEMINI_API_KEY;
    const useGemini = !OPENAI_API_KEY && !!GEMINI_API_KEY;
    
    if (!apiKey) {
      throw new Error("OPENAI_API_KEY or GEMINI_API_KEY must be configured");
    }

    const systemPrompt = `You are an expert swim coach AI that creates personalized training sets. 
Based on the swimmer's historical training data and their goals, suggest 3-4 training sets that will help them improve.

Consider:
1. Balance different strokes and intensities
2. Progressive overload principles
3. Recovery needs based on recent training
4. Specific goal events they're training for
5. Variety to keep training engaging

Each suggestion should include:
- set_description: A concise name like "8x100 Free @1:30"
- stroke: One of Freestyle, Backstroke, Breaststroke, Butterfly, IM, Kick, Drill
- distance_per_rep: Distance in meters for each rep
- number_of_reps: How many reps
- total_distance: Total meters
- rest_seconds: Rest between reps (10-120)
- intensity: One of easy, moderate, hard, race_pace
- rationale: Brief explanation of why this set is recommended`;

    const userPrompt = `Here's the swimmer's data:

Historical Training Summary:
- Total sets recorded: ${historicalData.totalSets}
- Average set distance: ${Math.round(historicalData.avgSetDistance)}m
- Stroke breakdown (meters): ${JSON.stringify(historicalData.strokeBreakdown)}
- Intensity distribution: ${JSON.stringify(historicalData.intensityBreakdown)}
- Recent sets: ${JSON.stringify(historicalData.recentSets.slice(0, 5))}

Goals:
${goals.length > 0 ? goals.map((g: any) => `- ${g.event}: Target ${g.targetTime}s`).join('\n') : 'No specific time goals set'}

Please suggest 3-4 training sets that would benefit this swimmer.`;

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
              text: `${systemPrompt}\n\n${userPrompt}\n\nPlease respond with a JSON object containing a "suggestions" array. Each suggestion should have: set_description, stroke, distance_per_rep, number_of_reps, total_distance, rest_seconds, intensity, and rationale.`
            }]
          }],
          generationConfig: {
            temperature: 0.7,
            responseMimeType: "application/json",
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
          tools: [
            {
              type: "function",
              function: {
                name: "suggest_training_sets",
                description: "Return training set suggestions",
                parameters: {
                  type: "object",
                  properties: {
                    suggestions: {
                      type: "array",
                      items: {
                        type: "object",
                        properties: {
                          set_description: { type: "string" },
                          stroke: { 
                            type: "string",
                            enum: ["Freestyle", "Backstroke", "Breaststroke", "Butterfly", "IM", "Kick", "Drill"]
                          },
                          distance_per_rep: { type: "number" },
                          number_of_reps: { type: "number" },
                          total_distance: { type: "number" },
                          rest_seconds: { type: "number" },
                          intensity: { 
                            type: "string",
                            enum: ["easy", "moderate", "hard", "race_pace"]
                          },
                          rationale: { type: "string" },
                        },
                        required: ["set_description", "stroke", "distance_per_rep", "number_of_reps", "total_distance", "rest_seconds", "intensity", "rationale"],
                      },
                    },
                  },
                  required: ["suggestions"],
                },
              },
            },
          ],
          tool_choice: { type: "function", function: { name: "suggest_training_sets" } },
        }),
      });
    }

    if (!response.ok) {
      const errorText = await response.text();
      console.error("AI API error:", response.status, errorText);
      
      if (response.status === 429) {
        return new Response(
          JSON.stringify({ error: "Rate limit exceeded. Please try again later." }),
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
    
    if (useGemini) {
      // Gemini response format
      const text = data.candidates?.[0]?.content?.parts?.[0]?.text;
      if (text) {
        const suggestions = JSON.parse(text);
        return new Response(
          JSON.stringify(suggestions),
          { headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }
    } else {
      // OpenAI response format
      const toolCall = data.choices?.[0]?.message?.tool_calls?.[0];
      if (toolCall?.function?.arguments) {
        const suggestions = JSON.parse(toolCall.function.arguments);
        return new Response(
          JSON.stringify(suggestions),
          { headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }
    }

    throw new Error("No suggestions returned from AI");
  } catch (error: unknown) {
    console.error("Error in suggest-training function:", error);
    const errorMessage = error instanceof Error ? error.message : "Unknown error";
    return new Response(
      JSON.stringify({ error: errorMessage }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
