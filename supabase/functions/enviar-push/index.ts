import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const fcmServerKey = Deno.env.get("FCM_SERVER_KEY"); // opcional

/**
 * Dispara push notification via FCM pra um ou mais usuários.
 *
 * Config necessária (quando plugar): FCM_SERVER_KEY no env da function.
 * Sem a key, a função apenas persiste a notificação em `notifications`
 * (já existe fallback via enviar-recado). Com a key, também manda push
 * pros tokens salvos em `fcm_tokens`.
 *
 * Payload:
 *   {
 *     user_ids: string[],
 *     title: string,
 *     body: string,
 *     data?: Record<string, any>
 *   }
 */
interface Payload {
  user_ids: string[];
  title: string;
  body: string;
  data?: Record<string, unknown>;
}

Deno.serve(async (req) => {
  try {
    const payload: Payload = await req.json();
    const supabase = createClient(supabaseUrl, supabaseKey);

    // Sempre persiste in-app
    const rows = payload.user_ids.map((uid) => ({
      user_id: uid,
      title: payload.title,
      body: payload.body,
      type: "push",
      data: payload.data ?? {},
    }));
    await supabase.from("notifications").insert(rows);

    // Push externo só se o Firebase estiver configurado
    if (!fcmServerKey) {
      return new Response(
        JSON.stringify({
          notified_in_app: rows.length,
          push_sent: 0,
          note: "FCM_SERVER_KEY não configurada — apenas in-app",
        }),
      );
    }

    const { data: tokens } = await supabase
      .from("fcm_tokens")
      .select("token")
      .in("user_id", payload.user_ids);

    const tokenList = (tokens ?? []).map((t: any) => t.token);
    if (tokenList.length === 0) {
      return new Response(
        JSON.stringify({ notified_in_app: rows.length, push_sent: 0 }),
      );
    }

    const fcmResp = await fetch("https://fcm.googleapis.com/fcm/send", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `key=${fcmServerKey}`,
      },
      body: JSON.stringify({
        registration_ids: tokenList,
        notification: {
          title: payload.title,
          body: payload.body,
        },
        data: payload.data ?? {},
      }),
    });

    const fcmResult = await fcmResp.json();
    return new Response(
      JSON.stringify({
        notified_in_app: rows.length,
        push_sent: tokenList.length,
        fcm: fcmResult,
      }),
    );
  } catch (error: any) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
    });
  }
});
