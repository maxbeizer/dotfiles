import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

type RepoSummary = {
  branch: string;
  dirtyCount: number;
  untrackedCount: number;
};

async function getRepoSummary(pi: ExtensionAPI, signal?: AbortSignal): Promise<RepoSummary | undefined> {
  const branchResult = await pi.exec("git", ["branch", "--show-current"], { timeout: 2000, signal });
  if (branchResult.code !== 0) return undefined;

  let branch = branchResult.stdout.trim();
  if (!branch) {
    const shaResult = await pi.exec("git", ["rev-parse", "--short", "HEAD"], { timeout: 2000, signal });
    branch = shaResult.code === 0 ? `detached:${shaResult.stdout.trim()}` : "unknown";
  }

  const statusResult = await pi.exec("git", ["status", "--porcelain"], { timeout: 2000, signal });
  if (statusResult.code !== 0) return { branch, dirtyCount: 0, untrackedCount: 0 };

  const lines = statusResult.stdout.split("\n").filter(Boolean);
  return {
    branch,
    dirtyCount: lines.length,
    untrackedCount: lines.filter((line) => line.startsWith("??")).length,
  };
}

async function refreshRepoStatus(pi: ExtensionAPI, ctx: ExtensionContext, notify = false) {
  if (!ctx.hasUI) return;

  const theme = ctx.ui.theme;
  ctx.ui.setStatus("repo-status", theme.fg("dim", "git …"));

  const summary = await getRepoSummary(pi, ctx.signal);
  if (!summary) {
    ctx.ui.setStatus("repo-status", undefined);
    return;
  }

  const branch = theme.fg("accent", summary.branch);
  const state = summary.dirtyCount === 0
    ? theme.fg("success", " clean")
    : theme.fg("warning", ` +${summary.dirtyCount}${summary.untrackedCount > 0 ? `?${summary.untrackedCount}` : ""}`);

  ctx.ui.setStatus("repo-status", `${theme.fg("dim", "git ")}${branch}${state}`);

  if (notify) {
    const message = summary.dirtyCount === 0
      ? `Repo is clean on ${summary.branch}`
      : `Repo has ${summary.dirtyCount} changed file(s) on ${summary.branch}`;
    ctx.ui.notify(message, summary.dirtyCount === 0 ? "info" : "warning");
  }
}

export default function repoStatusExtension(pi: ExtensionAPI) {
  pi.on("session_start", async (_event, ctx) => {
    await refreshRepoStatus(pi, ctx);
  });

  pi.on("agent_end", async (_event, ctx) => {
    await refreshRepoStatus(pi, ctx);
  });

  pi.registerCommand("repo-status", {
    description: "Refresh and show git branch/dirty status in the footer",
    handler: async (_args, ctx) => {
      await refreshRepoStatus(pi, ctx, true);
    },
  });
}
