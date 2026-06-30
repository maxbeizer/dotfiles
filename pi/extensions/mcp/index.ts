import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { getSettingsListTheme } from "@earendil-works/pi-coding-agent";
import { Container, type SettingItem, SettingsList } from "@earendil-works/pi-tui";
import { Type } from "typebox";
import type { Client } from "@modelcontextprotocol/sdk/client/index.js";
import { readFile } from "node:fs/promises";
import { existsSync } from "node:fs";
import { join } from "node:path";
import { homedir } from "node:os";

interface McpConfig {
  mcpServers?: Record<string, McpServerConfig>;
  mcpMetadata?: Record<string, McpServerMetadata>;
}

interface McpServerMetadata {
  description?: string;
  suggest?: string[];
}

type McpServerConfig =
  | {
      type?: "local" | "stdio";
      command: string;
      args?: string[];
      env?: Record<string, string>;
      cwd?: string;
      tools?: string[];
      autoStart?: boolean;
      description?: string;
      suggest?: string[];
    }
  | {
      type: "http" | "streamable-http";
      url: string;
      headers?: Record<string, string>;
      tools?: string[];
      autoStart?: boolean;
      description?: string;
      suggest?: string[];
    };

interface ConnectedServer {
  name: string;
  config: McpServerConfig;
  client: Client;
  transport: { close(): Promise<void> };
  tools: Array<{ name: string; piName: string; description?: string }>;
}

const CONFIG_FILE = ".mcp.json";
const DEFAULT_SUGGEST_TERMS: Record<string, string[]> = {
  port: ["port", "service", "services", "fundamentals", "scorecard", "scorecards", "ownership", "escalation", "aor"],
  datadog: ["datadog", "metrics", "traces", "notebook", "observability"],
  kusto: ["kusto", "kql", "azure data explorer", "adx", "hydro", "glb"],
  pagerduty: ["pagerduty", "pager duty", "incident", "incidents", "on-call", "on call", "escalation"],
  sentry: ["sentry", "errors", "exceptions", "releases"],
  slack: ["slack", "thread", "threads", "channel", "channels", "canvas"],
  splunk: ["splunk", "logs", "production logs", "search logs"],
  pencil: ["pencil", "diagram", "draw", "sketch"],
  playwright: ["playwright", "browser", "web automation", "screenshot"],
  oneup: ["1up", "oneup", "mcp setup", "install mcp", "available mcps"],
  "1up": ["1up", "oneup", "mcp setup", "install mcp", "available mcps"],
  "outlook-calendar": ["calendar", "meeting", "meetings", "schedule", "availability"],
  "outlook-mail": ["mail", "email", "inbox", "outlook"],
};

const DEFAULT_DESCRIPTIONS: Record<string, string> = {
  port: "Port inventory, ownership, service health, and Fundamentals lookups",
  datadog: "Datadog observability — metrics, logs, traces, notebooks",
  kusto: "Azure Data Explorer / Kusto — GLB logs, hydro tables, MySQL snapshots via KQL",
  pagerduty: "PagerDuty incidents, schedules, services, escalation policies, and teams",
  sentry: "Sentry error tracking, performance issues, and releases",
  slack: "Slack search, channels, threads, profiles, and canvases",
  splunk: "Splunk production log analysis",
  pencil: "Pencil diagramming/sketching MCP",
  playwright: "Playwright browser automation",
  oneup: "1up MCP discovery and setup tools",
  "1up": "1up MCP discovery and setup tools",
  "outlook-calendar": "Outlook calendar tools",
  "outlook-mail": "Outlook mail tools",
};

function defaultSuggestTerms(name: string): string[] {
  return DEFAULT_SUGGEST_TERMS[name] ?? DEFAULT_SUGGEST_TERMS[name.toLowerCase()] ?? [];
}

function defaultDescription(name: string): string | undefined {
  return DEFAULT_DESCRIPTIONS[name] ?? DEFAULT_DESCRIPTIONS[name.toLowerCase()];
}

function sanitizeToolName(value: string): string {
  const sanitized = value.replace(/[^a-zA-Z0-9_-]/g, "_");
  return /^[a-zA-Z]/.test(sanitized) ? sanitized : `mcp_${sanitized}`;
}

function serverToolAllowed(config: McpServerConfig, toolName: string): boolean {
  const allow = config.tools ?? ["*"];
  return allow.includes("*") || allow.includes(toolName);
}

function expandEnvString(value: string): string {
  return value.replace(/\$\{([A-Z0-9_]+)\}/gi, (_match, name: string) => process.env[name] ?? "");
}

function expandEnvArray(values: string[] | undefined): string[] | undefined {
  return values?.map(expandEnvString);
}

function expandEnvRecord(values: Record<string, string> | undefined): Record<string, string> | undefined {
  if (!values) return undefined;
  return Object.fromEntries(Object.entries(values).map(([key, value]) => [key, expandEnvString(value)]));
}

function mergeEnv(extraEnv: Record<string, string> | undefined): Record<string, string> | undefined {
  const env: Record<string, string> = {};
  for (const [key, value] of Object.entries(process.env)) {
    if (value !== undefined) env[key] = value;
  }
  return { ...env, ...expandEnvRecord(extraEnv) };
}

function schemaForTool(inputSchema: unknown) {
  if (
    inputSchema &&
    typeof inputSchema === "object" &&
    (inputSchema as { type?: unknown }).type === "object"
  ) {
    return inputSchema as ReturnType<typeof Type.Object>;
  }

  return Type.Object({}, { additionalProperties: true });
}

function contentToText(content: unknown): string {
  if (!Array.isArray(content)) return JSON.stringify(content, null, 2);

  return content
    .map((item) => {
      if (!item || typeof item !== "object") return String(item);
      const typed = item as Record<string, unknown>;

      if (typed.type === "text") return String(typed.text ?? "");
      if (typed.type === "resource") return JSON.stringify(typed.resource ?? typed, null, 2);
      if (typed.type === "resource_link") return JSON.stringify(typed, null, 2);
      if (typed.type === "image") return `[image: ${typed.mimeType ?? "unknown mime type"}]`;
      if (typed.type === "audio") return `[audio: ${typed.mimeType ?? "unknown mime type"}]`;
      return JSON.stringify(typed, null, 2);
    })
    .join("\n");
}

async function readConfigFile(path: string): Promise<McpConfig | undefined> {
  if (!existsSync(path)) return undefined;

  const raw = await readFile(path, "utf8");
  return JSON.parse(raw) as McpConfig;
}

async function readConfigs(cwd: string): Promise<{ paths: string[]; config: McpConfig }> {
  const paths = [
    join(homedir(), ".copilot", "mcp-config.json"),
    join(homedir(), ".pi", "agent", "mcp.json"),
    join(cwd, CONFIG_FILE),
  ];
  const merged: McpConfig = { mcpServers: {}, mcpMetadata: {} };
  const loadedPaths: string[] = [];

  for (const path of paths) {
    const config = await readConfigFile(path);
    if (!config) continue;

    loadedPaths.push(path);
    Object.assign(merged.mcpServers!, config.mcpServers ?? {});
    Object.assign(merged.mcpMetadata!, config.mcpMetadata ?? {});
  }

  return { paths: loadedPaths, config: merged };
}

async function connectServer(name: string, config: McpServerConfig, cwd: string): Promise<ConnectedServer> {
  const [{ Client }, { StdioClientTransport }, { StreamableHTTPClientTransport }] = await Promise.all([
    import("@modelcontextprotocol/sdk/client/index.js"),
    import("@modelcontextprotocol/sdk/client/stdio.js"),
    import("@modelcontextprotocol/sdk/client/streamableHttp.js"),
  ]);

  const client = new Client(
    { name: `pi-mcp-${name}`, version: "0.1.0" },
    { capabilities: {} },
  );

  let transport: { close(): Promise<void> };
  if ("url" in config) {
    const headers = expandEnvRecord(config.headers);
    transport = new StreamableHTTPClientTransport(new URL(expandEnvString(config.url)), {
      requestInit: headers ? { headers } : undefined,
    });
  } else {
    transport = new StdioClientTransport({
      command: expandEnvString(config.command),
      args: expandEnvArray(config.args) ?? [],
      env: mergeEnv(config.env),
      cwd: config.cwd ?? cwd,
      stderr: "pipe",
    });
  }

  await client.connect(transport);
  const listed = await client.listTools();
  const tools = listed.tools
    .filter((tool) => serverToolAllowed(config, tool.name))
    .map((tool) => ({
      name: tool.name,
      piName: sanitizeToolName(`mcp_${name}_${tool.name}`),
      description: tool.description,
    }));

  return { name, config, client, transport, tools };
}

export default function mcpExtension(pi: ExtensionAPI) {
  const serverConfigs = new Map<string, McpServerConfig>();
  const serverMetadata = new Map<string, McpServerMetadata>();
  const servers = new Map<string, ConnectedServer>();
  const registeredToolNames = new Set<string>();
  let configPaths: string[] = [];
  let currentCwd = process.cwd();
  let lastErrors: string[] = [];

  const updateStatus = (ctx?: { hasUI?: boolean; ui?: { setStatus(key: string, value: string): void } }) => {
    if (!ctx?.hasUI) return;
    ctx.ui?.setStatus("mcp", `mcp:${servers.size}/${serverConfigs.size}${lastErrors.length ? `/${lastErrors.length} errors` : ""}`);
  };

  const registerMcpTool = (server: ConnectedServer, mcpTool: { name: string; description?: string; inputSchema?: unknown }) => {
    const piName = sanitizeToolName(`mcp_${server.name}_${mcpTool.name}`);
    if (registeredToolNames.has(piName)) return;
    registeredToolNames.add(piName);

    pi.registerTool({
      name: piName,
      label: `MCP ${server.name}/${mcpTool.name}`,
      description: mcpTool.description ?? `Call MCP tool ${mcpTool.name} on server ${server.name}`,
      promptSnippet: `Call MCP tool ${server.name}/${mcpTool.name}`,
      promptGuidelines: [
        `Use ${piName} only when the user asks for data or actions from the ${server.name} MCP server.`,
      ],
      parameters: schemaForTool(mcpTool.inputSchema),
      async execute(_toolCallId, params, signal) {
        const current = servers.get(server.name);
        if (!current) {
          return {
            isError: true,
            content: [{ type: "text", text: `MCP server not connected: ${server.name}. Start it with mcp_start_server.` }],
            details: { server: server.name, tool: mcpTool.name } as Record<string, unknown>,
          };
        }

        const result = await current.client.callTool(
          { name: mcpTool.name, arguments: params as Record<string, unknown> },
          undefined,
          signal ? { signal } : undefined,
        );

        const text = "content" in result ? contentToText(result.content) : JSON.stringify(result, null, 2);
        return {
          isError: "isError" in result ? Boolean(result.isError) : false,
          content: [{ type: "text", text }],
          details: { server: server.name, tool: mcpTool.name, result } as Record<string, unknown>,
        };
      },
    });
  };

  async function loadConfig(cwd: string) {
    currentCwd = cwd;
    lastErrors = [];
    serverConfigs.clear();
    serverMetadata.clear();
    const loaded = await readConfigs(cwd);
    configPaths = loaded.paths;

    for (const [name, metadata] of Object.entries(loaded.config.mcpMetadata ?? {})) {
      serverMetadata.set(name, metadata);
    }

    if (!loaded.config.mcpServers) return;

    for (const [name, config] of Object.entries(loaded.config.mcpServers)) {
      serverConfigs.set(name, config);
    }
  }

  async function startServer(name: string, ctx?: { hasUI?: boolean; ui?: { setStatus(key: string, value: string): void } }) {
    const existing = servers.get(name);
    if (existing) return existing;

    const config = serverConfigs.get(name);
    if (!config) throw new Error(`No MCP server named ${name} in ${configPaths.join(", ") || CONFIG_FILE}`);

    const server = await connectServer(name, config, currentCwd);
    servers.set(name, server);

    const listed = await server.client.listTools();
    for (const tool of listed.tools.filter((tool) => serverToolAllowed(config, tool.name))) {
      registerMcpTool(server, tool);
    }

    updateStatus(ctx);
    return server;
  }

  function suggestedServers(prompt: string) {
    const lower = prompt.toLowerCase();
    return Array.from(serverConfigs.entries())
      .filter(([name, config]) => !servers.has(name) && [...(config.suggest ?? []), ...(serverMetadata.get(name)?.suggest ?? []), ...defaultSuggestTerms(name)].some((term) => lower.includes(term.toLowerCase())))
      .map(([name, config]) => {
        const description = config.description ?? serverMetadata.get(name)?.description ?? defaultDescription(name);
        return `${name}${description ? ` (${description})` : ""}`;
      });
  }

  pi.registerTool({
    name: "mcp_status",
    label: "MCP Status",
    description: "List configured and connected MCP servers and tools",
    promptSnippet: "List configured and connected MCP servers and available tools",
    parameters: Type.Object({}),
    async execute() {
      const configured = Array.from(serverConfigs.entries()).map(([name, config]) => ({
        server: name,
        connected: servers.has(name),
        autoStart: Boolean(config.autoStart),
        description: config.description ?? serverMetadata.get(name)?.description ?? defaultDescription(name),
        suggestedBy: [...(config.suggest ?? []), ...(serverMetadata.get(name)?.suggest ?? []), ...defaultSuggestTerms(name)],
      }));
      const connected = Array.from(servers.values()).map((server) => ({
        server: server.name,
        tools: server.tools.map((tool) => ({ name: tool.name, piName: tool.piName, description: tool.description })),
      }));

      return {
        content: [{ type: "text", text: JSON.stringify({ configPaths, configured, connected, errors: lastErrors }, null, 2) }],
        details: { configPaths, configured, connected, errors: lastErrors },
      };
    },
  });

  pi.registerTool({
    name: "mcp_start_server",
    label: "MCP Start Server",
    description: "Start a configured MCP server on demand and register its tools",
    promptSnippet: "Start a configured MCP server when needed",
    promptGuidelines: [
      "Use mcp_start_server when the user asks for live data from a configured MCP server that is not connected yet.",
      "After starting a server, use mcp_call_tool or the newly registered server-specific MCP tools to query it.",
    ],
    parameters: Type.Object({
      server: Type.String({ description: "MCP server name from .mcp.json" }),
    }),
    async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
      try {
        const server = await startServer(params.server, ctx);
        return {
          content: [{ type: "text", text: `Started MCP server ${params.server}. Tools: ${server.tools.map((tool) => `${tool.name} (${tool.piName})`).join(", ")}` }],
          details: { server: params.server, tools: server.tools } as Record<string, unknown>,
        };
      } catch (error) {
        const message = error instanceof Error ? error.message : String(error);
        lastErrors.push(`${params.server}: ${message}`);
        return {
          isError: true,
          content: [{ type: "text", text: message }],
          details: { server: params.server, error: message, configuredServers: Array.from(serverConfigs.keys()) } as Record<string, unknown>,
        };
      }
    },
  });

  pi.registerTool({
    name: "mcp_call_tool",
    label: "MCP Call Tool",
    description: "Call a tool on a connected MCP server by server and tool name",
    promptSnippet: "Call a connected MCP server tool by name",
    promptGuidelines: [
      "Use mcp_call_tool as a fallback when a server-specific MCP tool is unavailable or was registered after startup.",
    ],
    parameters: Type.Object({
      server: Type.String({ description: "MCP server name from .mcp.json" }),
      tool: Type.String({ description: "MCP tool name exposed by that server" }),
      arguments: Type.Optional(Type.Record(Type.String(), Type.Unknown(), { description: "Tool arguments" })),
    }),
    async execute(_toolCallId, params, signal) {
      const server = servers.get(params.server);
      if (!server) {
        return {
          isError: true,
          content: [{ type: "text", text: `MCP server not connected: ${params.server}. Start it with mcp_start_server.` }],
          details: { configuredServers: Array.from(serverConfigs.keys()), connectedServers: Array.from(servers.keys()), errors: lastErrors } as Record<string, unknown>,
        };
      }

      const result = await server.client.callTool(
        { name: params.tool, arguments: params.arguments ?? {} },
        undefined,
        signal ? { signal } : undefined,
      );

      const text = "content" in result ? contentToText(result.content) : JSON.stringify(result, null, 2);
      return {
        isError: "isError" in result ? Boolean(result.isError) : false,
        content: [{ type: "text", text }],
        details: { server: params.server, tool: params.tool, result } as Record<string, unknown>,
      };
    },
  });

  pi.registerCommand("mcp-status", {
    description: "Show configured and connected MCP servers",
    handler: async (_args, ctx) => {
      const lines = [
        `MCP config: ${configPaths.join(", ") || "not found"}`,
        ...Array.from(serverConfigs.entries()).map(([name, config]) => {
          const description = config.description ?? serverMetadata.get(name)?.description ?? defaultDescription(name);
          return `- ${name}: ${servers.has(name) ? "connected" : "stopped"}${description ? ` — ${description}` : ""}`;
        }),
        ...lastErrors.map((error) => `! ${error}`),
      ];
      ctx.ui.notify(lines.join("\n"), lastErrors.length ? "warning" : "info");
    },
  });

  async function startSelectedServers(names: string[], ctx: { hasUI?: boolean; ui?: { notify(message: string, level?: "info" | "warning" | "error" | "success"): void; setStatus(key: string, value: string): void } }) {
    if (names.length === 0) {
      ctx.ui?.notify("No MCP servers selected", "info");
      return;
    }

    const results: string[] = [];
    for (const name of names) {
      try {
        const server = await startServer(name, ctx);
        results.push(`✓ ${name}: ${server.tools.length} tool(s)`);
      } catch (error) {
        const message = error instanceof Error ? error.message : String(error);
        lastErrors.push(`${name}: ${message}`);
        results.push(`✗ ${name}: ${message}`);
      }
    }

    ctx.ui?.notify(results.join("\n"), results.some((line) => line.startsWith("✗")) ? "warning" : "info");
  }

  async function showStartPicker(ctx: Parameters<Parameters<typeof pi.registerCommand>[1]["handler"]>[1]) {
    if (ctx.mode !== "tui") {
      const choice = await ctx.ui.select("Start MCP server", Array.from(serverConfigs.keys()).filter((name) => !servers.has(name)));
      if (choice) await startSelectedServers([choice], ctx);
      return;
    }

    const candidates = Array.from(serverConfigs.keys()).filter((name) => !servers.has(name));
    if (candidates.length === 0) {
      ctx.ui.notify("All configured MCP servers are already connected", "info");
      return;
    }

    const selected = new Set<string>();
    const result = await ctx.ui.custom<string[] | undefined>((tui, theme, _kb, done) => {
      const items: SettingItem[] = candidates.map((name) => {
        const config = serverConfigs.get(name);
        const description = config?.description ?? serverMetadata.get(name)?.description ?? defaultDescription(name);
        return {
          id: name,
          label: description ? `${name} — ${description}` : name,
          currentValue: "skip",
          values: ["start", "skip"],
        };
      });

      const container = new Container();
      container.addChild(
        new (class {
          render(_width: number) {
            return [
              theme.fg("accent", theme.bold("Start MCP servers")),
              theme.fg("muted", "Toggle servers to start, then press Enter/Esc to close."),
              "",
            ];
          }
          invalidate() {}
        })(),
      );

      const settingsList = new SettingsList(
        items,
        Math.min(items.length + 5, 20),
        getSettingsListTheme(),
        (id, newValue) => {
          if (newValue === "start") selected.add(id);
          else selected.delete(id);
        },
        () => done(Array.from(selected)),
        { enableSearch: true },
      );

      container.addChild(settingsList);

      return {
        render(width: number) {
          return container.render(width);
        },
        invalidate() {
          container.invalidate();
        },
        handleInput(data: string) {
          settingsList.handleInput?.(data);
          tui.requestRender();
        },
      };
    });

    if (result) await startSelectedServers(result, ctx);
  }

  pi.registerCommand("mcp-start", {
    description: "Start one MCP server by name, or open a multi-select picker with no args",
    handler: async (args, ctx) => {
      const name = args.trim();
      if (!name) {
        await showStartPicker(ctx);
        return;
      }
      await startSelectedServers([name], ctx);
    },
  });

  pi.registerCommand("mcp-start-picker", {
    description: "Open a multi-select picker to start MCP servers",
    handler: async (_args, ctx) => {
      await showStartPicker(ctx);
    },
  });

  pi.on("session_start", async (_event, ctx) => {
    if (!ctx.isProjectTrusted()) return;
    await loadConfig(ctx.cwd);

    for (const [name, config] of serverConfigs.entries()) {
      if (!config.autoStart) continue;
      try {
        await startServer(name, ctx);
      } catch (error) {
        lastErrors.push(`${name}: ${error instanceof Error ? error.message : String(error)}`);
      }
    }

    updateStatus(ctx);
  });

  pi.on("before_agent_start", async (event) => {
    const suggestions = suggestedServers(event.prompt);
    if (suggestions.length === 0) return;

    return {
      message: {
        customType: "mcp-suggestion",
        display: true,
        content: `MCP suggestion: this request may need ${suggestions.join(", ")}. Use mcp_start_server to start one on demand; do not start MCP servers unless live MCP data is needed.`,
      },
    };
  });

  pi.on("session_shutdown", async () => {
    await Promise.allSettled(Array.from(servers.values()).map((server) => server.transport.close()));
    servers.clear();
  });
}
