import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";

const YELLOW = "\x1b[38;2;249;226;175m";
const RESET = "\x1b[0m";

function shortModelName(modelId: string | undefined): string {
  if (!modelId) return "no model";

  return modelId
    .replace(/^claude-/, "")
    .replace(/^gpt-/, "gpt-")
    .replace(/-latest$/, "")
    .replace(/-20\d{6}$/, "")
    .replace(/-\d{4}-\d{2}-\d{2}$/, "");
}

function stripAnsi(text: string): string {
  return text.replace(/\x1b\[[0-9;]*m/g, "");
}

function parseSafetyStatus(statuses: ReadonlyMap<string, string>): string | undefined {
  const raw = statuses.get("safety");
  if (!raw) return undefined;

  const clean = stripAnsi(raw).trim();
  return `${YELLOW}${clean}${RESET}`;
}

function currentTime(): string {
  return new Date().toLocaleTimeString("en-US", { hour12: false });
}

export default function cleanFooterExtension(pi: ExtensionAPI) {
  let enabled = true;

  function applyFooter(ctx: any) {
    if (!ctx.hasUI) return;

    if (!enabled) {
      ctx.ui.setFooter(undefined);
      return;
    }

    ctx.ui.setFooter((tui: any, theme: any, footerData: any) => {
      const unsub = footerData.onBranchChange(() => tui.requestRender());

      return {
        dispose: unsub,
        invalidate() {},
        render(width: number): string[] {
          const statuses = footerData.getExtensionStatuses();
          const piMark = theme.fg("accent", "π");
          const model = theme.fg("text", shortModelName(ctx.model?.id));
          const thinking = theme.fg("dim", pi.getThinkingLevel());
          const left = `${piMark} ${model} ${thinking}`;

          const rightParts = [parseSafetyStatus(statuses), theme.fg("dim", currentTime())].filter(Boolean) as string[];
          const right = rightParts.join(theme.fg("dim", " "));

          const gap = Math.max(1, width - visibleWidth(left) - visibleWidth(right));
          return [truncateToWidth(left + " ".repeat(gap) + right, width)];
        },
      };
    });
  }

  pi.on("session_start", async (_event, ctx) => {
    applyFooter(ctx);
  });

  pi.on("model_select", async (_event, ctx) => {
    applyFooter(ctx);
  });

  pi.on("thinking_level_select", async (_event, ctx) => {
    applyFooter(ctx);
  });

  pi.registerCommand("clean-footer", {
    description: "Toggle the clean custom footer: on, off, or status",
    getArgumentCompletions: (prefix) => {
      const candidates = ["on", "off", "status"];
      const filtered = candidates.filter((candidate) => candidate.startsWith(prefix));
      return filtered.length > 0 ? filtered.map((value) => ({ value, label: value })) : null;
    },
    handler: async (args, ctx) => {
      const requested = args.trim().toLowerCase();

      if (!requested || requested === "status") {
        ctx.ui.notify(`Clean footer is ${enabled ? "on" : "off"}`, "info");
        return;
      }

      if (requested !== "on" && requested !== "off") {
        ctx.ui.notify("Usage: /clean-footer [on|off|status]", "error");
        return;
      }

      enabled = requested === "on";
      applyFooter(ctx);
      ctx.ui.notify(`Clean footer ${enabled ? "enabled" : "disabled"}`, "info");
    },
  });
}
