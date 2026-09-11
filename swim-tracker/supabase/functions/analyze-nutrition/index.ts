import "jsr:@supabase/functions-js/edge-runtime.d.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

Deno.serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Check auth
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      throw new Error('Missing Authorization header')
    }

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: authHeader } } }
    )

    const { data: { user }, error: userError } = await supabase.auth.getUser()
    if (userError || !user) {
      throw new Error('Unauthorized')
    }

    const { description, image_base64 } = await req.json()

    if (!description && !image_base64) {
      throw new Error('Must provide either a description or an image')
    }

    const GROQ_API_KEY = Deno.env.get('GROQ_API_KEY')
    if (!GROQ_API_KEY) {
      throw new Error('Missing GROQ API Key configuration')
    }

    const systemPrompt = `You are a professional sports nutritionist AI assistant.
Your job is to analyze food descriptions or images and estimate the macro nutritional breakdown.
Return exactly ONE JSON object with these keys (and NO extra text or markdown wrappers outside the JSON):
{
  "calories": number (estimated total calories),
  "protein": number (estimated total protein in grams),
  "carbs": number (estimated total carbohydrates in grams),
  "fat": number (estimated total fat in grams),
  "sugar": number (estimated total sugar in grams)
}`;

    const messages = [];
    messages.push({ role: "system", content: systemPrompt });

    // Using LLaMA 3.2 Vision if an image is provided, else standard Versatile schema
    const model = image_base64 ? "llama-3.2-11b-vision-preview" : "llama-3.3-70b-versatile";

    if (!image_base64) {
      messages.push({ role: "user", content: `Food description: ${description}` });
    } else {
      let content = [];
      if (description) {
        content.push({ type: "text", text: `Food description: ${description}` });
      }
      content.push({
        type: "image_url",
        image_url: {
          url: `data:image/jpeg;base64,${image_base64}`,
        },
      });
      messages.push({ role: "user", content: content });
    }

    console.log(`🚀 Analyzing nutrition with model: ${model}`);

    const groqResponse = await fetch("https://api.groq.com/openai/v1/chat/completions", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${GROQ_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: model,
        messages: messages,
        temperature: 0.1, // Keep it deterministic for macro counting
        response_format: { type: "json_object" },
      }),
    });

    if (!groqResponse.ok) {
      const errorText = await groqResponse.text();
      console.error("Groq API error:", errorText);
      throw new Error(`Groq API error: ${groqResponse.status}`);
    }

    const groqData = await groqResponse.json();
    const resultText = groqData.choices[0].message.content;

    console.log("Raw LLM response:", resultText);

    const macros = JSON.parse(resultText);

    return new Response(
      JSON.stringify(macros),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 200,
      }
    )
  } catch (error) {
    console.error('Error analyzing nutrition:', error.message)
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 400,
      }
    )
  }
})
