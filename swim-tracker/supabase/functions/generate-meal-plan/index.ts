import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const { goals } = await req.json();
    const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY");
    const GEMINI_API_KEY = Deno.env.get("GEMINI_API_KEY");
    
    // Prefer OpenAI, fallback to Gemini
    const apiKey = OPENAI_API_KEY || GEMINI_API_KEY;
    const useGemini = !OPENAI_API_KEY && !!GEMINI_API_KEY;
    
    if (!apiKey) {
      throw new Error("OPENAI_API_KEY or GEMINI_API_KEY must be configured");
    }

    console.log("Generating meal plan for goals:", goals);

    const systemPrompt = `You are a sports nutrition expert specializing in meal planning for swimmers and athletes. Generate a weekly meal plan based on the user's daily nutrition goals.

You must respond with a valid JSON object containing a "meals" array. Each meal should have:
- day_of_week: 0-6 (0=Sunday, 6=Saturday)
- meal_type: "breakfast", "lunch", "dinner", or "snack"
- meal_name: A descriptive name for the meal
- description: Brief description with key ingredients
- calories: Estimated calories (integer)
- protein_grams: Estimated protein in grams (number)
- carbs_grams: Estimated carbs in grams (number)
- fat_grams: Estimated fat in grams (number)

Focus on:
- High-quality proteins for muscle recovery
- Complex carbohydrates for sustained energy
- Healthy fats for overall health
- Meals that are practical and easy to prepare
- Variety across the week

Generate exactly 4 meals per day (breakfast, lunch, dinner, snack) for all 7 days (28 total meals).`;

    const userPrompt = `Generate a weekly meal plan for a swimmer with these daily nutrition goals:
- Calories: ${goals.daily_calories} kcal
- Protein: ${goals.daily_protein_grams}g
- Carbohydrates: ${goals.daily_carbs_grams}g
- Fat: ${goals.daily_fat_grams}g

Each day's meals should add up close to these daily targets. Return ONLY valid JSON.`;

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
          temperature: 0.7,
          response_format: { type: "json_object" },
        }),
      });
    }

    if (!response.ok) {
      const errorText = await response.text();
      console.error("AI API error:", response.status, errorText);
      
      if (response.status === 429) {
        return new Response(JSON.stringify({ error: "Rate limits exceeded. Please try again later." }), {
          status: 429,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }
      if (response.status === 401 || response.status === 403) {
        return new Response(JSON.stringify({ error: "API key is invalid or expired. Please check your API key configuration." }), {
          status: 401,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }
      
      throw new Error(`AI API error: ${response.status} - ${errorText}`);
    }

    const data = await response.json();
    
    let content;
    if (useGemini) {
      // Gemini response format
      content = data.candidates?.[0]?.content?.parts?.[0]?.text;
    } else {
      // OpenAI response format
      content = data.choices?.[0]?.message?.content;
    }
    
    if (!content) {
      throw new Error("No content in AI response");
    }

    console.log("Raw AI response:", content);

    // Extract JSON from the response (handle markdown code blocks)
    let jsonStr = content;
    const jsonMatch = content.match(/```(?:json)?\s*([\s\S]*?)```/);
    if (jsonMatch) {
      jsonStr = jsonMatch[1].trim();
    }

    const mealPlan = JSON.parse(jsonStr);
    console.log("Parsed meal plan with", mealPlan.meals?.length, "meals");

    return new Response(JSON.stringify(mealPlan), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error: unknown) {
    const errorMessage = error instanceof Error ? error.message : 'Unknown error';
    console.error("Error generating meal plan:", error);
    return new Response(JSON.stringify({ error: errorMessage }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
