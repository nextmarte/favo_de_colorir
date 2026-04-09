import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

interface RecadoPayload {
  title: string;
  body: string;
}

Deno.serve(async (req) => {
  try {
    const payload: RecadoPayload = await req.json();
    const supabase = createClient(supabaseUrl, supabaseKey);

    // Buscar todos os profiles ativos
    const { data: profiles } = await supabase
      .from("profiles")
      .select("id")
      .eq("status", "active");

    if (!profiles || profiles.length === 0) {
      return new Response(JSON.stringify({ sent: 0 }));
    }

    // Criar notificação para cada um
    const notifications = profiles.map((p: any) => ({
      user_id: p.id,
      title: payload.title,
      body: payload.body,
      type: "general",
      data: {},
    }));

    await supabase.from("notifications").insert(notifications);

    return new Response(
      JSON.stringify({ sent: profiles.length }),
    );
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
    });
  }
});
