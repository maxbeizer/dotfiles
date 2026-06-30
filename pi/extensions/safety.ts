import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { dirname, relative, resolve } from "node:path";
import { existsSync, realpathSync, statSync } from "node:fs";

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

function expandHome(path: string): string {
  if (path === "~") return process.env.HOME ?? path;
  if (path.startsWith("~/")) return `${process.env.HOME ?? "~"}${path.slice(1)}`;
  return path;
}

function canonicalPath(path: string): string {
  const expanded = expandHome(path);
  const absolute = resolve(expanded);
  return existsSync(absolute) ? realpathSync(absolute) : absolute;
}

function normalizeRepoPath(cwd: string, rawPath: unknown): string | undefined {
  if (typeof rawPath !== "string" || rawPath.length === 0) return undefined;

  const absolutePath = normalizeAbsolutePath(cwd, rawPath);
  if (!absolutePath) return undefined;

  const repoRelative = relative(cwd, absolutePath).replaceAll("\\", "/");
  return repoRelative === "" ? "." : repoRelative;
}

function normalizeAbsolutePath(cwd: string, rawPath: unknown): string | undefined {
  if (typeof rawPath !== "string" || rawPath.length === 0) return undefined;

  const withoutAt = rawPath.startsWith("@") ? rawPath.slice(1) : rawPath;
  const expanded = expandHome(withoutAt);
  const absolutePath = resolve(cwd, expanded);

  return existsSync(absolutePath) ? realpathSync(absolutePath) : absolutePath;
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

function pathIsWithinRoot(path: string, root: string): boolean {
  const rel = relative(root, path).replaceAll("\\", "/");
  return rel === "" || (!rel.startsWith("../") && rel !== "..");
}

function nearestExistingDirectory(path: string): string {
  let current = path;
  while (!existsSync(current)) {
    const parent = dirname(current);
    if (parent === current) return current;
    current = parent;
  }

  return statSync(current).isDirectory() ? current : dirname(current);
}

function formatAllowedRoots(roots: Set<string>): string {
  if (roots.size === 0) return "No session mutation allowlist entries.";
  return [...roots].sort().map((root) => `- ${root}`).join("\n");
}

async function confirmSensitive(ctx: any, title: string, message: string): Promise<boolean> {
  if (!ctx.hasUI) return false;
  return await ctx.ui.confirm(title, message);
}

export default function safetyExtension(pi: ExtensionAPI) {
  const allowedMutationRoots = new Set<string>();

  function isAllowedMutationPath(path: string): boolean {
    return [...allowedMutationRoots].some((root) => pathIsWithinRoot(path, root));
  }

  async function allowedRootForPath(path: string): Promise<string> {
    const gitCwd = nearestExistingDirectory(path);
    const rootResult = await pi.exec("git", ["-C", gitCwd, "rev-parse", "--show-toplevel"], {
      timeout: 2000,
    });

    return rootResult.code === 0 ? canonicalPath(rootResult.stdout.trim()) : canonicalPath(gitCwd);
  }

  function addAllowedMutationRoot(root: string, ctx: any): void {
    allowedMutationRoots.add(root);
    ctx.ui.setStatus("safety", ctx.ui.theme.fg("warning", `allowed: ${allowedMutationRoots.size}`));
    ctx.ui.notify(`Allowed file mutations under this path for this session:\n${root}`, "warning");
  }

  async function chooseMutationPermission(ctx: any, title: string, message: string, pathToAllow: string): Promise<boolean> {
    if (!ctx.hasUI) return false;

    const choice = await ctx.ui.select(`${title}\n\n${message}\n\nAllow?`, ["Allow once", "Allow repo/path for this session", "Block"]);
    if (choice === "Allow once") return true;

    if (choice === "Allow repo/path for this session") {
      const root = await allowedRootForPath(pathToAllow);
      addAllowedMutationRoot(root, ctx);
      return true;
    }

    return false;
  }

  pi.registerCommand("allow-repo", {
    description: "Session-allow file mutations under a repo/path; usage: /allow-repo [path|clear|list]",
    getArgumentCompletions: (prefix) => {
      const candidates = [".", "~/dotfiles", "clear", "list"];
      const filtered = candidates.filter((candidate) => candidate.startsWith(prefix));
      return filtered.length > 0 ? filtered.map((value) => ({ value, label: value })) : null;
    },
    handler: async (args, ctx) => {
      const requested = args.trim();

      if (requested === "clear") {
        allowedMutationRoots.clear();
        ctx.ui.notify("Cleared session mutation allowlist", "info");
        ctx.ui.setStatus("safety", undefined);
        return;
      }

      if (requested === "list") {
        ctx.ui.notify(formatAllowedRoots(allowedMutationRoots), "info");
        return;
      }

      const target = requested || ".";
      const root = await allowedRootForPath(resolve(ctx.cwd, expandHome(target)));
      addAllowedMutationRoot(root, ctx);
    },
  });

  pi.on("tool_call", async (event, ctx) => {
    if (event.toolName === "write" || event.toolName === "edit") {
      const rawPath = (event.input as { path?: unknown }).path;
      const absolutePath = normalizeAbsolutePath(ctx.cwd, rawPath);
      const repoPath = normalizeRepoPath(ctx.cwd, rawPath);
      if (!repoPath || !absolutePath) return undefined;

      if (pathIsOutsideRepo(repoPath) && !isAllowedMutationPath(absolutePath)) {
        const ok = await chooseMutationPermission(
          ctx,
          "External file mutation",
          `The ${event.toolName} tool wants to modify a file outside this repo:\n\n${absolutePath}`,
          absolutePath,
        );
        if (!ok) return { block: true, reason: "Blocked external file mutation" };
      }

      if (pathIsBlocked(repoPath)) {
        return { block: true, reason: `Blocked mutation of protected path: ${repoPath}` };
      }

      if (pathIsSensitive(repoPath) && !isAllowedMutationPath(absolutePath)) {
        const ok = await chooseMutationPermission(
          ctx,
          "Sensitive file mutation",
          `The ${event.toolName} tool wants to modify sensitive people/performance-adjacent content:\n\n${repoPath}`,
          absolutePath,
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
