import type { ExtensionAPI, ExtensionContext, WorkingIndicatorOptions } from "@earendil-works/pi-coding-agent";

type VibeMode = "vault" | "quiet" | "default";

function indicatorFor(ctx: ExtensionContext, mode: VibeMode): WorkingIndicatorOptions | undefined {
  const theme = ctx.ui.theme;

  switch (mode) {
    case "vault":
      return {
        frames: [
          theme.fg("dim", "·"),
          theme.fg("muted", "•"),
          theme.fg("accent", "●"),
          theme.fg("muted", "•"),
        ],
        intervalMs: 140,
      };
    case "quiet":
      return { frames: [theme.fg("accent", "●")] };
    case "default":
      return undefined;
  }
}

function messageFor(mode: VibeMode): string | undefined {
  switch (mode) {
    case "vault":
      return "consulting the vault…";
    case "quiet":
      return "working…";
    case "default":
      return undefined;
  }
}

function describeMode(mode: VibeMode): string {
  switch (mode) {
    case "vault":
      return "vault pulse + custom working message";
    case "quiet":
      return "quiet static dot";
    case "default":
      return "Pi defaults";
  }
}

function applyVibe(ctx: ExtensionContext, mode: VibeMode) {
  if (!ctx.hasUI) return;

  ctx.ui.setWorkingIndicator(indicatorFor(ctx, mode));
  ctx.ui.setWorkingMessage(messageFor(mode));
  ctx.ui.setStatus("vault-vibes", ctx.ui.theme.fg("dim", `vibe: ${mode}`));
}

export default function vaultVibesExtension(pi: ExtensionAPI) {
  let mode: VibeMode = "vault";

  pi.on("session_start", async (_event, ctx) => {
    applyVibe(ctx, mode);
  });

  pi.registerCommand("vibe", {
    description: "Set Pi's working indicator/message: vault, quiet, or default",
    getArgumentCompletions: (prefix) => {
      const modes: VibeMode[] = ["vault", "quiet", "default"];
      const filtered = modes.filter((candidate) => candidate.startsWith(prefix));
      return filtered.length > 0 ? filtered.map((value) => ({ value, label: value })) : null;
    },
    handler: async (args, ctx) => {
      const requested = args.trim().toLowerCase();

      if (!requested) {
        ctx.ui.notify(`Current vibe: ${describeMode(mode)}`, "info");
        return;
      }

      if (requested !== "vault" && requested !== "quiet" && requested !== "default") {
        ctx.ui.notify("Usage: /vibe [vault|quiet|default]", "error");
        return;
      }

      mode = requested;
      applyVibe(ctx, mode);
      ctx.ui.notify(`Vibe set to: ${describeMode(mode)}`, "info");
    },
  });
}
