import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

type PromptTip = {
  command: string;
  description: string;
  example?: string;
};

const promptTips: PromptTip[] = [
  {
    command: "/review-changes",
    description: "Review current git changes for correctness, risk, security, and missing tests.",
    example: "/review-changes focus on edge cases",
  },
  {
    command: "/commit-changes",
    description: "Inspect, group, validate, and commit current changes.",
    example: "/commit-changes add pi prompt hint",
  },
  {
    command: "/pr-body",
    description: "Draft a pull request body from the current branch diff.",
    example: "/pr-body main",
  },
  {
    command: "/copilot-review",
    description: "Fetch and fix GitHub Copilot PR review suggestions.",
    example: "/copilot-review 123",
  },
  {
    command: "/explain-repo",
    description: "Explain the current repository structure, commands, and workflows.",
    example: "/explain-repo testing workflow",
  },
  {
    command: "/find-tests",
    description: "Discover relevant test, lint, and typecheck commands without running expensive suites.",
    example: "/find-tests changed files",
  },
  {
    command: "/run-tests",
    description: "Run the fastest relevant validation for current changes and summarize results.",
    example: "/run-tests focused",
  },
];

function randomTip(): PromptTip {
  return promptTips[Math.floor(Math.random() * promptTips.length)] ?? promptTips[0]!;
}

function startupSeconds(): string {
  return process.uptime() < 10 ? process.uptime().toFixed(1) : Math.round(process.uptime()).toString();
}

function renderTip(ctx: ExtensionContext, tip: PromptTip) {
  const theme = ctx.ui.theme;
  const tryLine = `${theme.fg("dim", "try ")}${theme.fg("accent", tip.command)}${theme.fg("dim", ` · startup ${startupSeconds()}s · /prompts browse · /prompt-hint clear`)}`;

  ctx.ui.setWidget("prompt-hint", [tryLine], { placement: "aboveEditor" });
}

function clearTip(ctx: ExtensionContext) {
  ctx.ui.setWidget("prompt-hint", undefined);
}

async function pickPrompt(ctx: ExtensionContext) {
  const selected = await ctx.ui.select(
    "Global prompt templates",
    promptTips.map((tip) => `${tip.command} — ${tip.description}`),
  );

  if (!selected) return;

  const command = selected.split(" — ")[0];
  const tip = promptTips.find((candidate) => candidate.command === command);
  if (tip) {
    renderTip(ctx, tip);
    ctx.ui.setEditorText(tip.example ?? tip.command);
  }
}

export default function promptHintExtension(pi: ExtensionAPI) {
  pi.on("session_start", async (_event, ctx) => {
    if (!ctx.hasUI) return;
    renderTip(ctx, randomTip());
  });

  pi.registerCommand("prompt-hint", {
    description: "Show, list, or clear global Pi prompt-template reminders",
    getArgumentCompletions: (prefix) => {
      const candidates = ["list", "clear", ...promptTips.map((tip) => tip.command.slice(1))];
      const filtered = candidates.filter((candidate) => candidate.startsWith(prefix));
      return filtered.length > 0 ? filtered.map((value) => ({ value, label: value })) : null;
    },
    handler: async (args, ctx) => {
      if (!ctx.hasUI) return;

      const requested = args.trim();

      if (requested === "clear") {
        clearTip(ctx);
        ctx.ui.notify("Cleared prompt hint", "info");
        return;
      }

      if (requested === "list") {
        await pickPrompt(ctx);
        return;
      }

      if (requested) {
        const normalized = requested.startsWith("/") ? requested : `/${requested}`;
        const tip = promptTips.find((candidate) => candidate.command === normalized);
        if (!tip) {
          ctx.ui.notify("Usage: /prompt-hint [list|clear|review-changes|commit-changes|pr-body|copilot-review|explain-repo|find-tests|run-tests]", "error");
          return;
        }

        renderTip(ctx, tip);
        ctx.ui.setEditorText(tip.example ?? tip.command);
        return;
      }

      renderTip(ctx, randomTip());
    },
  });

  pi.registerCommand("prompts", {
    description: "Pick a global Pi prompt template and prefill the editor",
    handler: async (_args, ctx) => {
      if (!ctx.hasUI) return;
      await pickPrompt(ctx);
    },
  });
}
