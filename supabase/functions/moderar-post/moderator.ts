export const BLOCKED_POLITICAL = [
  "político", "política", "eleição", "candidato", "partido",
  "bolsonaro", "lula", "governo", "presidente", "congresso",
  "senado", "deputado", "vereador", "prefeito", "governador",
  "esquerda", "direita", "comunista", "fascista",
];

export type OpenAICategory =
  | "sexual"
  | "sexual/minors"
  | "harassment"
  | "harassment/threatening"
  | "hate"
  | "hate/threatening"
  | "violence"
  | "violence/graphic"
  | "self-harm"
  | "self-harm/intent"
  | "self-harm/instructions"
  | "illicit"
  | "illicit/violent";

export interface OpenAIModerationResult {
  flagged: boolean;
  categories: Record<OpenAICategory, boolean>;
  category_scores: Record<OpenAICategory, number>;
}

export type OpenAIModerationFn = (content: string) => Promise<OpenAIModerationResult>;

export interface ModerationResult {
  flagged: boolean;
  reason: string | null;
  category: string | null;
  blocked_word: string | null;
}

const CATEGORY_LABEL_PT: Record<string, string> = {
  sexual: "Conteúdo sexual",
  "sexual/minors": "Conteúdo sexual",
  harassment: "Assédio",
  "harassment/threatening": "Assédio",
  hate: "Discurso de ódio",
  "hate/threatening": "Discurso de ódio",
  violence: "Violência",
  "violence/graphic": "Violência",
  "self-harm": "Automutilação",
  "self-harm/intent": "Automutilação",
  "self-harm/instructions": "Automutilação",
  illicit: "Atividade ilícita",
  "illicit/violent": "Atividade ilícita",
};

const CATEGORY_ROOT: Record<string, string> = {
  sexual: "sexual",
  "sexual/minors": "sexual",
  harassment: "harassment",
  "harassment/threatening": "harassment",
  hate: "hate",
  "hate/threatening": "hate",
  violence: "violence",
  "violence/graphic": "violence",
  "self-harm": "self-harm",
  "self-harm/intent": "self-harm",
  "self-harm/instructions": "self-harm",
  illicit: "illicit",
  "illicit/violent": "illicit",
};

function checkPolitical(content: string): ModerationResult | null {
  const lower = content.toLowerCase();
  for (const word of BLOCKED_POLITICAL) {
    if (lower.includes(word)) {
      return {
        flagged: true,
        reason: "Conteúdo político detectado",
        category: "political",
        blocked_word: word,
      };
    }
  }
  return null;
}

function highestCategory(result: OpenAIModerationResult): OpenAICategory | null {
  let top: OpenAICategory | null = null;
  let topScore = -1;
  for (const [cat, flagged] of Object.entries(result.categories)) {
    if (!flagged) continue;
    const score = result.category_scores[cat as OpenAICategory] ?? 0;
    if (score > topScore) {
      top = cat as OpenAICategory;
      topScore = score;
    }
  }
  return top;
}

export async function moderateContent(
  content: string,
  callOpenAI: OpenAIModerationFn,
): Promise<ModerationResult> {
  const political = checkPolitical(content);
  if (political) return political;

  let openAIResult: OpenAIModerationResult;
  try {
    openAIResult = await callOpenAI(content);
  } catch (err) {
    console.error("OpenAI moderation failed, failing open:", err);
    return { flagged: false, reason: null, category: null, blocked_word: null };
  }

  if (!openAIResult.flagged) {
    return { flagged: false, reason: null, category: null, blocked_word: null };
  }

  const top = highestCategory(openAIResult);
  if (!top) {
    return { flagged: false, reason: null, category: null, blocked_word: null };
  }

  return {
    flagged: true,
    reason: CATEGORY_LABEL_PT[top] ?? "Conteúdo inadequado",
    category: CATEGORY_ROOT[top] ?? top,
    blocked_word: null,
  };
}

export function makeOpenAICaller(apiKey: string): OpenAIModerationFn {
  return async (content: string) => {
    const response = await fetch("https://api.openai.com/v1/moderations", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ input: content, model: "omni-moderation-latest" }),
    });

    if (!response.ok) {
      throw new Error(`OpenAI ${response.status}: ${await response.text()}`);
    }

    const json = await response.json();
    const r = json.results?.[0];
    if (!r) throw new Error("OpenAI response missing results[0]");
    return r as OpenAIModerationResult;
  };
}
