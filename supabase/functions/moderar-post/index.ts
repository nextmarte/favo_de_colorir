import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { makeOpenAICaller, moderateContent } from "./moderator.ts";

const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const openaiKey = Deno.env.get("OPENAI_API_KEY") ?? "";

interface ModeratePayload {
  post_id: string;
  content: string;
}

const callOpenAI = openaiKey
  ? makeOpenAICaller(openaiKey)
  : () => Promise.reject(new Error("OPENAI_API_KEY not configured"));

Deno.serve(async (req) => {
  try {
    const payload: ModeratePayload = await req.json();
    const supabase = createClient(supabaseUrl, supabaseKey);

    const result = await moderateContent(payload.content, callOpenAI);

    if (result.flagged) {
      await supabase
        .from("community_posts")
        .update({
          is_flagged: true,
          flag_reason: result.reason,
        })
        .eq("id", payload.post_id);

      const { data: admins } = await supabase
        .from("profiles")
        .select("id")
        .eq("role", "admin");

      if (admins) {
        const bodyParts = [`Post flagado por: ${result.reason}.`];
        if (result.blocked_word) {
          bodyParts.push(`Palavra: "${result.blocked_word}"`);
        }
        const notifications = admins.map((a: { id: string }) => ({
          user_id: a.id,
          title: "Post flagado",
          body: bodyParts.join(" "),
          type: "moderation",
          data: { post_id: payload.post_id, category: result.category },
        }));

        await supabase.from("notifications").insert(notifications);
      }
    }

    return new Response(JSON.stringify(result));
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    return new Response(JSON.stringify({ error: message }), {
      status: 500,
    });
  }
});
