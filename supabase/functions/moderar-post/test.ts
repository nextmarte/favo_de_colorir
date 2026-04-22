import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { moderateContent, type OpenAIModerationResult } from "./moderator.ts";

const cleanOpenAI: OpenAIModerationResult = {
  flagged: false,
  categories: {
    sexual: false,
    "sexual/minors": false,
    harassment: false,
    "harassment/threatening": false,
    hate: false,
    "hate/threatening": false,
    violence: false,
    "violence/graphic": false,
    "self-harm": false,
    "self-harm/intent": false,
    "self-harm/instructions": false,
    illicit: false,
    "illicit/violent": false,
  },
  category_scores: {
    sexual: 0.001,
    "sexual/minors": 0.0,
    harassment: 0.01,
    "harassment/threatening": 0.0,
    hate: 0.001,
    "hate/threatening": 0.0,
    violence: 0.001,
    "violence/graphic": 0.0,
    "self-harm": 0.0,
    "self-harm/intent": 0.0,
    "self-harm/instructions": 0.0,
    illicit: 0.001,
    "illicit/violent": 0.0,
  },
};

function flaggedWith(
  category: keyof OpenAIModerationResult["categories"],
  score = 0.95,
): OpenAIModerationResult {
  const result = structuredClone(cleanOpenAI);
  result.flagged = true;
  result.categories[category] = true;
  result.category_scores[category] = score;
  return result;
}

Deno.test("keyword flags conteúdo político sem chamar OpenAI", async () => {
  let calls = 0;
  const callOpenAI = () => {
    calls++;
    return Promise.resolve(cleanOpenAI);
  };

  const result = await moderateContent("Esse governo não presta", callOpenAI);

  assertEquals(result.flagged, true);
  assertEquals(result.category, "political");
  assertEquals(result.reason, "Conteúdo político detectado");
  assertEquals(result.blocked_word, "governo");
  assertEquals(calls, 0);
});

Deno.test("keyword detecta case-insensitive", async () => {
  const result = await moderateContent(
    "BOLSONARO vs LULA",
    () => Promise.resolve(cleanOpenAI),
  );
  assertEquals(result.flagged, true);
  assertEquals(result.category, "political");
});

Deno.test("conteúdo limpo + OpenAI limpo → não flagado", async () => {
  const result = await moderateContent(
    "Minha caneca ficou linda hoje!",
    () => Promise.resolve(cleanOpenAI),
  );
  assertEquals(result.flagged, false);
  assertEquals(result.reason, null);
  assertEquals(result.category, null);
});

Deno.test("OpenAI flag sexual → category sexual + reason pt-BR", async () => {
  const result = await moderateContent(
    "qualquer conteúdo",
    () => Promise.resolve(flaggedWith("sexual")),
  );
  assertEquals(result.flagged, true);
  assertEquals(result.category, "sexual");
  assertEquals(result.reason, "Conteúdo sexual");
});

Deno.test("OpenAI flag harassment → category harassment + reason pt-BR", async () => {
  const result = await moderateContent(
    "qualquer conteúdo",
    () => Promise.resolve(flaggedWith("harassment")),
  );
  assertEquals(result.flagged, true);
  assertEquals(result.category, "harassment");
  assertEquals(result.reason, "Assédio");
});

Deno.test("OpenAI flag hate → category hate + reason pt-BR", async () => {
  const result = await moderateContent(
    "qualquer conteúdo",
    () => Promise.resolve(flaggedWith("hate")),
  );
  assertEquals(result.flagged, true);
  assertEquals(result.category, "hate");
  assertEquals(result.reason, "Discurso de ódio");
});

Deno.test("OpenAI flag violence → category violence + reason pt-BR", async () => {
  const result = await moderateContent(
    "qualquer conteúdo",
    () => Promise.resolve(flaggedWith("violence")),
  );
  assertEquals(result.flagged, true);
  assertEquals(result.category, "violence");
  assertEquals(result.reason, "Violência");
});

Deno.test("OpenAI flag self-harm → category self-harm + reason pt-BR", async () => {
  const result = await moderateContent(
    "qualquer conteúdo",
    () => Promise.resolve(flaggedWith("self-harm")),
  );
  assertEquals(result.flagged, true);
  assertEquals(result.category, "self-harm");
  assertEquals(result.reason, "Automutilação");
});

Deno.test("OpenAI flag illicit → category illicit + reason pt-BR", async () => {
  const result = await moderateContent(
    "qualquer conteúdo",
    () => Promise.resolve(flaggedWith("illicit")),
  );
  assertEquals(result.flagged, true);
  assertEquals(result.category, "illicit");
  assertEquals(result.reason, "Atividade ilícita");
});

Deno.test("OpenAI flag múltiplas categorias → usa a de maior score", async () => {
  const r = structuredClone(cleanOpenAI);
  r.flagged = true;
  r.categories.sexual = true;
  r.categories.hate = true;
  r.category_scores.sexual = 0.4;
  r.category_scores.hate = 0.85;

  const result = await moderateContent(
    "qualquer",
    () => Promise.resolve(r),
  );
  assertEquals(result.category, "hate");
  assertEquals(result.reason, "Discurso de ódio");
});

Deno.test("fail-open: erro no fetch da OpenAI → não flagado", async () => {
  const result = await moderateContent(
    "conteúdo limpo qualquer",
    () => Promise.reject(new Error("timeout")),
  );
  assertEquals(result.flagged, false);
  assertEquals(result.reason, null);
});

Deno.test("keyword wins: match político não chama API mesmo com OpenAI flagando", async () => {
  let calls = 0;
  const callOpenAI = () => {
    calls++;
    return Promise.resolve(flaggedWith("sexual"));
  };

  const result = await moderateContent("Vote no candidato X", callOpenAI);

  assertEquals(result.flagged, true);
  assertEquals(result.category, "political");
  assertEquals(calls, 0);
});
