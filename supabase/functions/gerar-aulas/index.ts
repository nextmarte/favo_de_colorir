import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

interface GerarAulasPayload {
  weeks_ahead?: number;
  skip_holidays?: boolean;
}

Deno.serve(async (req) => {
  try {
    const payload: GerarAulasPayload = await req.json().catch(() => ({}));
    const weeksAhead = payload.weeks_ahead ?? 4;
    const skipHolidays = payload.skip_holidays ?? true;
    const supabase = createClient(supabaseUrl, supabaseKey);

    const { data: turmas } = await supabase
      .from("turmas")
      .select("*")
      .eq("is_active", true)
      .eq("modality", "regular");

    if (!turmas || turmas.length === 0) {
      return new Response(
        JSON.stringify({ created: 0, message: "Nenhuma turma ativa" }),
      );
    }

    // Pré-carrega feriados no range
    const today = new Date();
    const horizon = new Date(today);
    horizon.setDate(horizon.getDate() + weeksAhead * 7 + 7);
    const holidayDates = new Set<string>();
    const skippedByHoliday: { date: string; name: string; turma: string }[] = [];

    if (skipHolidays) {
      const { data: feriados } = await supabase
        .from("feriados")
        .select("date, name")
        .gte("date", today.toISOString().split("T")[0])
        .lte("date", horizon.toISOString().split("T")[0]);
      for (const f of feriados ?? []) {
        holidayDates.add(f.date as string);
      }
    }

    let totalCreated = 0;
    let totalSkippedHoliday = 0;
    let totalSkippedExisting = 0;
    const warnings: string[] = [];

    for (const turma of turmas) {
      if (turma.day_of_week === null) continue;
      if (!turma.teacher_id) {
        warnings.push(`Turma "${turma.name}" sem professora atribuída`);
      }

      for (let week = 0; week < weeksAhead; week++) {
        const date = new Date(today);
        const currentDay = date.getDay();
        const targetDay = turma.day_of_week;
        const diff = targetDay - currentDay + week * 7;

        if (diff < 0 && week === 0) continue;

        date.setDate(date.getDate() + diff);
        const dateStr = date.toISOString().split("T")[0];

        if (skipHolidays && holidayDates.has(dateStr)) {
          totalSkippedHoliday++;
          skippedByHoliday.push({
            date: dateStr,
            name: "", // o nome do feriado já está no SQL, omitimos aqui pra reduzir payload
            turma: turma.name,
          });
          continue;
        }

        // UNIQUE constraint (turma_id, scheduled_date) garante idempotência
        const { data: aulaData, error: insertErr } = await supabase
          .from("aulas")
          .insert({
            turma_id: turma.id,
            scheduled_date: dateStr,
            start_time: turma.start_time,
            end_time: turma.end_time,
            status: "scheduled",
          })
          .select("id")
          .maybeSingle();

        if (insertErr) {
          // Se erro de unique (23505), apenas contamos como já existente
          if ((insertErr as any).code === "23505") {
            totalSkippedExisting++;
          } else {
            warnings.push(
              `Falha em ${turma.name} / ${dateStr}: ${insertErr.message}`,
            );
          }
          continue;
        }

        if (!aulaData) {
          totalSkippedExisting++;
          continue;
        }

        const { data: enrollments } = await supabase
          .from("turma_alunos")
          .select("student_id")
          .eq("turma_id", turma.id)
          .eq("status", "active");

        if (enrollments && enrollments.length > 0) {
          const presencas = enrollments.map((e: any) => ({
            aula_id: aulaData.id,
            student_id: e.student_id,
            confirmation: "pending",
          }));
          await supabase.from("presencas").insert(presencas);
        }

        totalCreated++;
      }
    }

    // Audit log
    try {
      const authHeader = req.headers.get("Authorization");
      if (authHeader) {
        const { data: caller } = await supabase.auth.getUser(
          authHeader.replace("Bearer ", ""),
        );
        if (caller?.user) {
          await supabase.from("audit_logs").insert({
            actor_id: caller.user.id,
            action: "generate_aulas",
            resource_type: "turma",
            changes: {
              weeks_ahead: weeksAhead,
              skip_holidays: skipHolidays,
              created: totalCreated,
              skipped_holiday: totalSkippedHoliday,
              skipped_existing: totalSkippedExisting,
            },
          });
        }
      }
    } catch (_) {}

    return new Response(
      JSON.stringify({
        created: totalCreated,
        skipped_holiday: totalSkippedHoliday,
        skipped_existing: totalSkippedExisting,
        turmas_processed: turmas.length,
        weeks: weeksAhead,
        warnings,
      }),
    );
  } catch (error: any) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
    });
  }
});
