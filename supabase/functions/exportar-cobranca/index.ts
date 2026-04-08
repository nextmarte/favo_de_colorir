import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

interface ExportPayload {
  month_year: string;
  format: "csv" | "json";
}

Deno.serve(async (req) => {
  try {
    const payload: ExportPayload = await req.json();
    const { month_year, format } = payload;
    const supabase = createClient(supabaseUrl, supabaseKey);

    const { data: bills } = await supabase
      .from("cobrancas")
      .select("*, profiles:student_id(full_name, email)")
      .eq("month_year", month_year)
      .order("total_amount", { ascending: false });

    if (!bills || bills.length === 0) {
      return new Response(JSON.stringify({ error: "No bills found" }), {
        status: 404,
      });
    }

    if (format === "csv") {
      const headers = [
        "Aluna",
        "Email",
        "Mensalidade",
        "Argila",
        "Queimas",
        "Total",
        "Status",
        "Pago em",
        "Método",
      ];

      const rows = bills.map((b: any) => [
        b.profiles?.full_name ?? "",
        b.profiles?.email ?? "",
        b.plan_amount,
        b.clay_amount,
        b.firing_amount,
        b.total_amount,
        b.status,
        b.paid_at ?? "",
        b.payment_method ?? "",
      ]);

      const csv = [
        headers.join(","),
        ...rows.map((r: any[]) =>
          r.map((v) => `"${String(v).replace(/"/g, '""')}"`).join(",")
        ),
      ].join("\n");

      return new Response(csv, {
        headers: {
          "Content-Type": "text/csv; charset=utf-8",
          "Content-Disposition": `attachment; filename="cobrancas_${month_year}.csv"`,
        },
      });
    }

    return new Response(JSON.stringify(bills, null, 2), {
      headers: { "Content-Type": "application/json" },
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
    });
  }
});
