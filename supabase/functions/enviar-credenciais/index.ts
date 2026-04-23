import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

/**
 * Envia credenciais iniciais pra nova aluna por email (usando link mágico
 * do Supabase Auth) + registra a notificação in-app.
 *
 * O admin não precisa mais copiar e colar a senha no WhatsApp — a aluna
 * recebe um link que já autentica, setando ela como logada.
 *
 * Payload:
 *   { user_id: string }  // já criado via criar-aluna
 *
 * Requer: Authorization header do admin (RLS-like verificação).
 */
interface Payload {
  user_id: string;
}

Deno.serve(async (req) => {
  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: "Faltando Authorization header" }),
        { status: 401 },
      );
    }

    const supabase = createClient(supabaseUrl, supabaseKey);

    // Verifica admin
    const caller = await supabase.auth.getUser(
      authHeader.replace("Bearer ", ""),
    );
    if (caller.error || !caller.data.user) {
      return new Response(JSON.stringify({ error: "Sessão inválida" }), {
        status: 401,
      });
    }
    const { data: profile } = await supabase
      .from("profiles")
      .select("role")
      .eq("id", caller.data.user.id)
      .single();
    if (!profile || profile.role !== "admin") {
      return new Response(JSON.stringify({ error: "Apenas admin" }), {
        status: 403,
      });
    }

    const payload: Payload = await req.json();

    // Busca email da pessoa
    const { data: targetProfile } = await supabase
      .from("profiles")
      .select("email, full_name")
      .eq("id", payload.user_id)
      .single();

    if (!targetProfile) {
      return new Response(JSON.stringify({ error: "Usuário não encontrado" }), {
        status: 404,
      });
    }

    // Gera magic link (Supabase envia email automaticamente)
    const { data: link, error: linkError } = await supabase.auth.admin
      .generateLink({
        type: "magiclink",
        email: targetProfile.email,
      });

    if (linkError) {
      return new Response(
        JSON.stringify({ error: linkError.message }),
        { status: 400 },
      );
    }

    // Persiste aviso in-app pra quando a aluna abrir o app
    await supabase.from("notifications").insert({
      user_id: payload.user_id,
      title: "Bem-vindo(a) ao Favo!",
      body:
        "Sua conta foi criada. Um link de acesso foi enviado pro seu e-mail.",
      type: "credentials",
    });

    // Audit
    await supabase.from("audit_logs").insert({
      actor_id: caller.data.user.id,
      action: "send_credentials",
      resource_type: "profile",
      resource_id: payload.user_id,
    });

    return new Response(
      JSON.stringify({
        email: targetProfile.email,
        magic_link: link.properties.action_link,
      }),
    );
  } catch (error: any) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
    });
  }
});
