import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Client } from "@modelcontextprotocol/sdk/client/index.js";
import { StdioClientTransport } from "@modelcontextprotocol/sdk/client/stdio.js";
import { Type } from "typebox";

const LINEAR_MCP_URL = process.env.LINEAR_MCP_URL ?? "https://mcp.linear.app/mcp";
const TOOL_PREFIX = "linear_";

type McpContent =
	| { type: "text"; text: string }
	| { type: string; [key: string]: unknown };

function asPiContent(content: unknown): Array<{ type: "text"; text: string }> {
	if (!Array.isArray(content)) {
		return [{ type: "text", text: JSON.stringify(content ?? null, null, 2) }];
	}

	return content.map((item: McpContent) => {
		if (item && item.type === "text" && typeof item.text === "string") {
			return { type: "text", text: item.text };
		}
		return { type: "text", text: JSON.stringify(item, null, 2) };
	});
}

function toolSchema(inputSchema: unknown) {
	if (inputSchema && typeof inputSchema === "object") {
		return inputSchema as ReturnType<typeof Type.Object>;
	}
	return Type.Object({});
}

export default async function (pi: ExtensionAPI) {
	let client: Client | undefined;
	let transport: StdioClientTransport | undefined;

	async function getClient() {
		if (client) return client;

		transport = new StdioClientTransport({
			command: "npx",
			args: ["-y", "mcp-remote@0.1.38", LINEAR_MCP_URL, "--silent"],
		});

		client = new Client({ name: "pi-linear-mcp", version: "0.1.0" });
		await client.connect(transport);
		return client;
	}

	try {
		const mcp = await getClient();
		const { tools } = await mcp.listTools();

		for (const tool of tools) {
			const piToolName = `${TOOL_PREFIX}${tool.name}`;
			pi.registerTool({
				name: piToolName,
				label: `Linear: ${tool.name}`,
				description: tool.description ?? `Call Linear MCP tool ${tool.name}`,
				parameters: toolSchema(tool.inputSchema),
				async execute(_toolCallId, params) {
					const activeClient = await getClient();
					const result = await activeClient.callTool({
						name: tool.name,
						arguments: params as Record<string, unknown>,
					});

					return {
						content: asPiContent(result.content),
						details: {
							mcpTool: tool.name,
							isError: result.isError ?? false,
						},
					};
				},
			});
		}

		pi.registerCommand("linear-mcp", {
			description: "Show Linear MCP connection status and registered tools",
			handler: async (_args, ctx) => {
				ctx.ui.notify(`Linear MCP connected. Registered ${tools.length} tools with prefix ${TOOL_PREFIX}.`, "info");
			},
		});

		pi.on("session_shutdown", () => {
			// StdioClientTransport.close() can wait several seconds for mcp-remote.
			// Do not block /new or /reload while the old helper process exits.
			void client?.close().catch(() => undefined);
			client = undefined;
			transport = undefined;
		});
	} catch (error) {
		pi.registerCommand("linear-mcp", {
			description: "Show Linear MCP connection status",
			handler: async (_args, ctx) => {
				const message = error instanceof Error ? error.message : String(error);
				ctx.ui.notify(`Linear MCP failed to load: ${message}`, "error");
			},
		});
	}
}
