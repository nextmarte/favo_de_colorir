import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

interface GerarAulasPayload {
  weeks_ahead?: number; // quantas semanas gerar (default: 4)
}

Deno.serve(async (req) => {
  try {
    const payload: GerarAulasPayload = await req.json().catch(() => ({}));
    const weeksAhead = payload.weeks_ahead ?? 4;
    const supabase = createClient(supabaseUrl, supabaseKey);

    // Buscar turmas regulares ativas
    const { data: turmas } = await supabase
      .from("turmas")
      .select("*")
      .eq("is_active", true)
      .eq("modality", "regular");

    if (!turmas || turmas.length === 0) {
      return new Response(JSON.stringify({ created: 0, message: "No active turmas" }));
    }

    const today = new Date();
    let totalCreated = 0;

    for (const turma of turmas) {
      if (turma.day_of_week === null) continue;

      // Gerar aulas para as próximas N semanas
      for (let week = 0; week < weeksAhead; week++) {
        // Calcular a data da aula nesta semana
        const date = new Date(today);
        const currentDay = date.getDay(); // 0=dom, 6=sab
        const targetDay = turma.day_of_week;
        const diff = targetDay - currentDay + week * 7;

        if (diff < 0 && week === 0) continue; // já passou esta semana

        date.setDate(date.getDate() + diff);
        const dateStr = date.toISOString().split("T")[0];

        // Verificar se já existe aula nesta data para esta turma
        const { data: existing } = await supabase
          .from("aulas")
          .select("id")
          .eq("turma_id", turma.id)
          .eq("scheduled_date", dateStr)
          .maybeSingle();

        if (existing) continue;

        // Criar aula
        await supabase.from("aulas").insert({
          turma_id: turma.id,
          scheduled_date: dateStr,
          start_time: turma.start_time,
          end_time: turma.end_time,
          status: "scheduled",
        });

        // Criar presenças para alunas matriculadas
        const { data: enrollments } = await supabase
          .from("turma_alunos")
          .select("student_id")
          .eq("turma_id", turma.id)
          .eq("status", "active");

        if (enrollments && enrollments.length > 0) {
          const { data: aula } = await supabase
            .from("aulas")
            .select("id")
            .eq("turma_id", turma.id)
            .eq("scheduled_date", dateStr)
            .single();

          if (aula) {
            const presencas = enrollments.map((e: any) => ({
              aula_id: aula.id,
              student_id: e.student_id,
              confirmation: "pending",
            }));

            await supabase.from("presencas").insert(presencas);
          }
        }

        totalCreated++;
      }
    }

    return new Response(
      JSON.stringify({ created: totalCreated, weeks: weeksAhead }),
    );
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
    });
  }
});
