import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { relative, resolve } from "node:path";

const blockedPathPrefixes = [".git/", "node_modules/"];
const blockedExactPaths = [".env", "collections/.env", "collections/.env.example", "collections/.env.token"];
const sensitivePathPrefixes = [
  "one-to-one/",
  "manager-library/handoffs/",
  "reflektive/",
  "staff-promo/",
  "crm/",
];

const dangerousBashPatterns = [
  /\brm\s+(-[^\n;|&]*r[^\n;|&]*f|-[^\n;|&]*f[^\n;|&]*r|--recursive)\b/i,
  /\bsudo\b/i,
  /\b(chmod|chown)\b[^\n;|&]*\b777\b/i,
];

function normalizeRepoPath(cwd: string, rawPath: unknown): string | undefined {
  if (typeof rawPath !== "string" || rawPath.length === 0) return undefined;

  const withoutAt = rawPath.startsWith("@") ? rawPath.slice(1) : rawPath;
  const absolutePath = resolve(cwd, withoutAt);
  const repoRelative = relative(cwd, absolutePath).replaceAll("\\", "/");

  return repoRelative === "" ? "." : repoRelative;
}

function pathIsOutsideRepo(repoPath: string): boolean {
  return repoPath === ".." || repoPath.startsWith("../") || repoPath.startsWith("/../");
}

function pathIsBlocked(repoPath: string): boolean {
  return blockedExactPaths.includes(repoPath) || blockedPathPrefixes.some((prefix) => repoPath.startsWith(prefix));
}

function pathIsSensitive(repoPath: string): boolean {
  return sensitivePathPrefixes.some((prefix) => repoPath.startsWith(prefix));
}

async function confirmSensitive(ctx: any, title: string, message: string): Promise<boolean> {
  if (!ctx.hasUI) return false;
  return await ctx.ui.confirm(title, message);
}

export default function safetyExtension(pi: ExtensionAPI) {
  pi.on("tool_call", async (event, ctx) => {
    if (event.toolName === "write" || event.toolName === "edit") {
      const repoPath = normalizeRepoPath(ctx.cwd, (event.input as { path?: unknown }).path);
      if (!repoPath) return undefined;

      if (pathIsOutsideRepo(repoPath)) {
        const ok = await confirmSensitive(
          ctx,
          "External file mutation",
          `The ${event.toolName} tool wants to modify a file outside this repo:\n\n${repoPath}\n\nAllow?`,
        );
        if (!ok) return { block: true, reason: "Blocked external file mutation" };
      }

      if (pathIsBlocked(repoPath)) {
        return { block: true, reason: `Blocked mutation of protected path: ${repoPath}` };
      }

      if (pathIsSensitive(repoPath)) {
        const ok = await confirmSensitive(
          ctx,
          "Sensitive file mutation",
          `The ${event.toolName} tool wants to modify sensitive people/performance-adjacent content:\n\n${repoPath}\n\nAllow?`,
        );
        if (!ok) return { block: true, reason: `Blocked sensitive file mutation: ${repoPath}` };
      }
    }

    if (event.toolName === "bash") {
      const command = (event.input as { command?: unknown }).command;
      if (typeof command !== "string") return undefined;

      const isDangerous = dangerousBashPatterns.some((pattern) => pattern.test(command));
      if (isDangerous) {
        const ok = await confirmSensitive(ctx, "Dangerous bash command", `Pi wants to run:\n\n${command}\n\nAllow?`);
        if (!ok) return { block: true, reason: "Blocked dangerous bash command" };
      }

      const touchesSensitivePath = sensitivePathPrefixes.some((prefix) => command.includes(prefix));
      if (touchesSensitivePath) {
        const ok = await confirmSensitive(
          ctx,
          "Bash touches sensitive content",
          `This bash command mentions sensitive people/performance-adjacent paths:\n\n${command}\n\nAllow?`,
        );
        if (!ok) return { block: true, reason: "Blocked bash command touching sensitive content" };
      }

      const createsGithubComGist = /\bgh\s+gist\s+create\b/.test(command) && !/--hostname\s+ghe\.io\b/.test(command);
      if (createsGithubComGist) {
        const ok = await confirmSensitive(
          ctx,
          "Potential public-host gist",
          `This command creates a gist without --hostname ghe.io:\n\n${command}\n\nSensitive reflection/calibration/promo content must use ghe.io. Allow anyway?`,
        );
        if (!ok) return { block: true, reason: "Blocked gist creation without --hostname ghe.io" };
      }
    }

    return undefined;
  });
}
