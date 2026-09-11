import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

const corsHeaders = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

interface RequestData {
    goalId: string;
    goalTitle: string;
    targetValue: number;
    currentValue: number;
    metric: string;
    milestones: any[];
    recentEntries: any[];
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

        const GROQ_API_KEY = Deno.env.get("GROQ_API_KEY");
        if (!GROQ_API_KEY) {
            return new Response(
                JSON.stringify({ error: "Missing server configuration" }),
                { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
            );
        }

        const request: RequestData = await req.json();
        const { goalTitle, targetValue, currentValue, metric, milestones, recentEntries } = request;

        let milestoneContext = "";
        if (milestones && milestones.length > 0) {
            milestoneContext = milestones.map((m: any) => `- ${m.title}: target ${m.target_value}, currently reached? ${currentValue >= m.target_value}`).join("\n");
        }

        let progressContext = "";
        if (recentEntries && recentEntries.length > 0) {
            progressContext = recentEntries.map((e: any) => `- Date: ${e.entry_date}, Value: ${e.value}, Notes: ${e.notes || 'None'}`).join("\n");
        }

        const systemPrompt = `You are an expert swim coach AI. Your job is to analyze a swimmer's progress toward their specific goal and provide encouraging feedback. You should analyze if they have reached any milestones and give actionable advice on what they should focus on next.`;

        const userPrompt = `Goal: ${goalTitle}
Target: ${targetValue} ${metric}
Current Level: ${currentValue} ${metric}
Progress toward goal: ${Math.round((currentValue / targetValue) * 100)}%

Milestones:
${milestoneContext || "No milestones explicitly defined."}

Recent Progress Log:
${progressContext || "No recent entries."}

Please analyze this progress. Point out any milestones they've reached or are close to reaching. Give them 1-2 actionable tips on what to do next. Keep it concise, energetic, and supportive. Return ONLY a JSON object with a single field "analysis" containing your response in plain text format (do not use Markdown).`;

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
            throw new Error("No content block in response");
        }

        const parsed = JSON.parse(content);

        return new Response(
            JSON.stringify({
                success: true,
                analysis: parsed.analysis,
            }),
            { headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );

    } catch (error: any) {
        console.error("Error in analyze-goal-progress function:", error);
        return new Response(
            JSON.stringify({ error: "Internal server error", details: error.message }),
            { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
    }
});
