import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

interface TotalizarPayload {
  month_year: string;
}

Deno.serve(async (req) => {
  try {
    const payload: TotalizarPayload = await req.json();
    const { month_year } = payload;
    const supabase = createClient(supabaseUrl, supabaseKey);

    // Buscar assinaturas ativas com preço do plano
    const { data: subscriptions } = await supabase
      .from("assinaturas")
      .select("student_id, planos(price)")
      .eq("status", "active");

    if (!subscriptions || subscriptions.length === 0) {
      return new Response(JSON.stringify({ created: 0, message: "No active subscriptions" }));
    }

    let created = 0;

    for (const sub of subscriptions) {
      const studentId = sub.student_id;
      const planAmount = (sub as any).planos?.price ?? 0;

      // Argila: somar todas as linhas do aluno no mês (pode ter múltiplos tipos)
      const { data: clayData } = await supabase
        .from("v_consumo_mensal_aluna")
        .select("total_clay_cost")
        .eq("student_id", studentId)
        .eq("month_year", month_year);

      let clayAmount = 0;
      if (clayData) {
        clayAmount = clayData.reduce(
          (sum: number, row: any) => sum + (Number(row.total_clay_cost) || 0),
          0,
        );
      }

      // Queimas: somar todas as linhas do aluno no mês
      const { data: firingData } = await supabase
        .from("v_queimas_mensal_aluna")
        .select("total_firing_cost")
        .eq("student_id", studentId)
        .eq("month_year", month_year);

      let firingAmount = 0;
      if (firingData) {
        firingAmount = firingData.reduce(
          (sum: number, row: any) => sum + (Number(row.total_firing_cost) || 0),
          0,
        );
      }

      const totalAmount = planAmount + clayAmount + firingAmount;

      // Verificar se já existe cobrança
      const { data: existing } = await supabase
        .from("cobrancas")
        .select("id")
        .eq("student_id", studentId)
        .eq("month_year", month_year)
        .maybeSingle();

      if (existing) continue;

      // Criar cobrança (total_amount é generated column, não inserir)
      const { data: cobranca } = await supabase
        .from("cobrancas")
        .insert({
          student_id: studentId,
          month_year,
          plan_amount: planAmount,
          clay_amount: clayAmount,
          firing_amount: firingAmount,
          status: "draft",
          admin_confirmed: false,
        })
        .select()
        .single();

      if (!cobranca) continue;

      // Criar itens
      const items = [];

      if (planAmount > 0) {
        items.push({
          cobranca_id: cobranca.id,
          type: "plan",
          description: "Mensalidade",
          total: planAmount,
        });
      }

      if (clayAmount > 0) {
        items.push({
          cobranca_id: cobranca.id,
          type: "clay",
          description: "Argila consumida no mês",
          total: clayAmount,
        });
      }

      if (firingAmount > 0) {
        items.push({
          cobranca_id: cobranca.id,
          type: "firing",
          description: "Queimas de esmalte no mês",
          total: firingAmount,
        });
      }

      if (items.length > 0) {
        await supabase.from("cobranca_itens").insert(items);
      }

      created++;
    }

    return new Response(JSON.stringify({ created, month_year }));
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
    });
  }
});
