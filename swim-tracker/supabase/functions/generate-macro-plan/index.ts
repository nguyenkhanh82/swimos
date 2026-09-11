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
    const { goal, daysPerWeek, weeks, targetVolumeMin, targetVolumeMax } = await req.json();
    const GROQ_API_KEY = Deno.env.get("GROQ_API_KEY");

    if (!GROQ_API_KEY) {
      throw new Error("GROQ_API_KEY must be configured");
    }

    const systemPrompt = `You are an elite AI Swim Coach. 
Your task is to generate a macro-level training plan based on the user's goal.
The user wants to train ${daysPerWeek} days per week for ${weeks} weeks.
Target volume per session is between ${targetVolumeMin} and ${targetVolumeMax} yards/meters.

Each training day should have:
- day_index: The day number within the plan (1 to ${daysPerWeek * weeks}).
- week_number: The week number (1 to ${weeks}).
- focus_area: A short string (e.g., "Aerobic Base", "Race Pace", "Anaerobic Threshold", "Recovery", "Sprint", "Dryland").
- target_distance: An integer representing suggested distance (yards/meters). Do not use decimals.
- target_duration_minutes: An integer representing expected duration (e.g. 60, 90).
- notes: A brief sentence on what they will focus on for that day.

Return your response strictly as a JSON object containing a "plan" array of these days.`;

    const userPrompt = `Goal string: "${goal.title}"
${goal.description ? `Goal description: "${goal.description}"` : ""}
Goal Type: ${goal.goal_type}

Please generate the ${weeks}-week schedule JSON now. Ensure it ramps up and then tapers logically towards the end of the ${weeks} weeks!`;

    const response = await fetch("https://api.groq.com/openai/v1/chat/completions", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${GROQ_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: "llama-3.3-70b-versatile",
        messages: [
          { role: "system", content: systemPrompt },
          { role: "user", content: userPrompt },
        ],
        response_format: { type: "json_object" },
      }),
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error("Groq API error:", response.status, errorText);
      throw new Error(`Groq API error: ${response.status} - ${errorText}`);
    }

    const data = await response.json();
    const resultJson = JSON.parse(data.choices[0].message.content);

    return new Response(
      JSON.stringify(resultJson.plan),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (error: unknown) {
    console.error("Error in generate-macro-plan function:", error);
    const errorMessage = error instanceof Error ? error.message : "Unknown error";
    return new Response(
      JSON.stringify({ error: errorMessage }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
