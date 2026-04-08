import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

interface NotificationPayload {
  type: "confirmation_24h" | "reminder_6h" | "approval" | "billing";
  userId?: string;
}

Deno.serve(async (req) => {
  try {
    const payload: NotificationPayload = await req.json();
    const supabase = createClient(supabaseUrl, supabaseKey);

    if (payload.type === "confirmation_24h") {
      return await sendConfirmation24h(supabase);
    }

    if (payload.type === "reminder_6h") {
      return await sendReminder6h(supabase);
    }

    if (payload.type === "approval" && payload.userId) {
      return await sendApprovalNotification(supabase, payload.userId);
    }

    return new Response(JSON.stringify({ error: "Unknown type" }), {
      status: 400,
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
    });
  }
});

/**
 * 24h antes da aula: notificar alunas para confirmar presença
 */
async function sendConfirmation24h(supabase: ReturnType<typeof createClient>) {
  const tomorrow = new Date();
  tomorrow.setDate(tomorrow.getDate() + 1);
  const dateStr = tomorrow.toISOString().split("T")[0];

  // Buscar aulas de amanhã
  const { data: aulas } = await supabase
    .from("aulas")
    .select("id, turma_id, start_time, turmas(name)")
    .eq("scheduled_date", dateStr)
    .eq("status", "scheduled");

  if (!aulas || aulas.length === 0) {
    return new Response(JSON.stringify({ sent: 0 }));
  }

  let sent = 0;

  for (const aula of aulas) {
    // Buscar alunas matriculadas na turma
    const { data: enrollments } = await supabase
      .from("turma_alunos")
      .select("student_id")
      .eq("turma_id", aula.turma_id)
      .eq("status", "active");

    if (!enrollments) continue;

    for (const enrollment of enrollments) {
      // Verificar se já tem presença registrada
      const { data: existing } = await supabase
        .from("presencas")
        .select("id")
        .eq("aula_id", aula.id)
        .eq("student_id", enrollment.student_id)
        .maybeSingle();

      if (existing) continue;

      // Criar presença pendente
      await supabase.from("presencas").insert({
        aula_id: aula.id,
        student_id: enrollment.student_id,
        confirmation: "pending",
      });

      // Criar notificação
      const turmaName = (aula as any).turmas?.name ?? "Aula";
      await supabase.from("notifications").insert({
        user_id: enrollment.student_id,
        title: "Confirme sua presença",
        body: `Você tem aula amanhã: ${turmaName} às ${aula.start_time.substring(0, 5)}. Vai comparecer?`,
        type: "confirmation",
        data: { aula_id: aula.id },
      });

      // TODO: enviar push via FCM quando configurado
      sent++;
    }
  }

  return new Response(JSON.stringify({ sent }));
}

/**
 * 6h antes da aula: lembrete para quem não respondeu
 */
async function sendReminder6h(supabase: ReturnType<typeof createClient>) {
  const today = new Date().toISOString().split("T")[0];

  // Buscar presenças pendentes de hoje
  const { data: pending } = await supabase
    .from("presencas")
    .select("id, student_id, aula_id, aulas(start_time, turmas(name))")
    .eq("confirmation", "pending")
    .eq("aulas.scheduled_date", today);

  if (!pending || pending.length === 0) {
    return new Response(JSON.stringify({ sent: 0 }));
  }

  let sent = 0;

  for (const p of pending) {
    const aulaData = (p as any).aulas;
    if (!aulaData) continue;

    const turmaName = aulaData.turmas?.name ?? "Aula";

    await supabase.from("notifications").insert({
      user_id: p.student_id,
      title: "Lembrete: confirme sua presença",
      body: `Sua aula ${turmaName} é hoje às ${aulaData.start_time.substring(0, 5)}. Confirme sua presença!`,
      type: "reminder",
      data: { aula_id: p.aula_id },
    });

    sent++;
  }

  return new Response(JSON.stringify({ sent }));
}

/**
 * Notificar aluna que foi aprovada
 */
async function sendApprovalNotification(
  supabase: ReturnType<typeof createClient>,
  userId: string,
) {
  await supabase.from("notifications").insert({
    user_id: userId,
    title: "Cadastro aprovado!",
    body: "Seu cadastro no Favo de Colorir foi aprovado. Bem-vinda ao ateliê!",
    type: "approval",
    data: {},
  });

  return new Response(JSON.stringify({ sent: 1 }));
}
