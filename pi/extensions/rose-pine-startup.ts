import type { ExtensionAPI, Theme } from "@earendil-works/pi-coding-agent";
import { VERSION } from "@earendil-works/pi-coding-agent";
import { truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";

const DAY_THEME = "rose-pine-dawn";
const NIGHT_THEME = "rose-pine";
const DAY_START_HOUR = 7;
const NIGHT_START_HOUR = 19;
const MIN_TWO_COLUMN_WIDTH = 72;
const LOGO_WIDTH = 18;
const COLUMN_GAP = 4;

function themeForTime(date = new Date()): string {
	const hour = date.getHours();
	return hour >= DAY_START_HOUR && hour < NIGHT_START_HOUR ? DAY_THEME : NIGHT_THEME;
}

function getLogo(theme: Theme): string[] {
	const accent = (text: string) => theme.fg("accent", text);
	const eye = `${theme.fg("text", "█")}${theme.fg("dim", "▌")}`;

	return [
		`     ${eye}  ${eye}`,
		`  ${accent("██████████████")}`,
		`     ${accent("██")}    ${accent("██")}`,
		`     ${accent("██")}    ${accent("██")}`,
		`     ${accent("██")}    ${accent("██")}`,
		`     ${accent("██")}    ${accent("██")}`,
	];
}

function compactNames(names: string[], limit = 3): string {
	const unique = [...new Set(names)].sort((a, b) => a.localeCompare(b));
	if (unique.length === 0) return "none";
	const visible = unique.slice(0, limit).join(" · ");
	return unique.length > limit ? `${visible}  +${unique.length - limit}` : visible;
}

function sourceLabel(source: string): string {
	const cleaned = source.replace(/^(?:npm|git):/, "");
	if (!cleaned.includes("/")) return cleaned;

	const parts = cleaned.replaceAll("\\", "/").split("/").filter(Boolean);
	const leaf = (parts.at(-1) ?? cleaned).replace(/\.(?:[cm]?[jt]sx?)$/, "");
	return leaf === "index" ? (parts.at(-2) ?? leaf) : leaf;
}

function getResourceGroups(pi: ExtensionAPI) {
	const commands = pi.getCommands();
	const tools = pi.getAllTools();
	const extensionSources = [
		...commands
			.filter((command) => command.source === "extension")
			.map((command) =>
				command.sourceInfo.source === "auto" ? command.sourceInfo.path : command.sourceInfo.source,
			),
		...tools
			.filter((tool) => !["builtin", "sdk"].includes(tool.sourceInfo.source))
			.map((tool) => (tool.sourceInfo.source === "auto" ? tool.sourceInfo.path : tool.sourceInfo.source)),
	].map(sourceLabel);

	return {
		extensions: compactNames(extensionSources),
		skills: compactNames(
			commands
				.filter((command) => command.source === "skill")
				.map((command) => command.name.replace(/^skill:/, "")),
		),
		prompts: compactNames(commands.filter((command) => command.source === "prompt").map((command) => command.name)),
		tools: `${pi.getActiveTools().length} active · ${tools.length} available`,
	};
}

function labeledLine(theme: Theme, label: string, value: string): string {
	return `${theme.fg("muted", label.padEnd(11))}${theme.fg("text", value)}`;
}

function padToWidth(line: string, width: number): string {
	return line + " ".repeat(Math.max(0, width - visibleWidth(line)));
}

function createHeader(pi: ExtensionAPI, theme: Theme) {
	const resources = getResourceGroups(pi);

	return {
		render(width: number): string[] {
			const logo = getLogo(theme);
			const details = [
				`${theme.bold(theme.fg("accent", "PI"))}${theme.fg("dim", `  v${VERSION}`)}`,
				theme.fg("muted", "A small, sharp coding agent."),
				"",
				labeledLine(theme, "EXTENSIONS", resources.extensions),
				labeledLine(theme, "SKILLS", resources.skills),
				labeledLine(theme, "PROMPTS", resources.prompts),
				labeledLine(theme, "TOOLS", resources.tools),
				theme.fg("dim", "/ commands   ! shell   ctrl+p model"),
			];

			if (width < MIN_TWO_COLUMN_WIDTH) {
				return [...logo, "", ...details].map((line) => truncateToWidth(line, width, ""));
			}

			const rightWidth = Math.max(1, width - LOGO_WIDTH - COLUMN_GAP);
			const rowCount = Math.max(logo.length, details.length);
			const lines: string[] = [];
			for (let index = 0; index < rowCount; index += 1) {
				const left = padToWidth(logo[index] ?? "", LOGO_WIDTH);
				const right = truncateToWidth(details[index] ?? "", rightWidth, "…");
				lines.push(truncateToWidth(`${left}${" ".repeat(COLUMN_GAP)}${right}`, width, ""));
			}
			return lines;
		},
		invalidate() {},
	};
}

export default function rosePineStartup(pi: ExtensionAPI) {
	let interval: ReturnType<typeof setInterval> | undefined;
	let activeTheme: string | undefined;

	pi.on("session_start", (_event, ctx) => {
		if (ctx.mode !== "tui") return;

		const applyTimedTheme = () => {
			const nextTheme = themeForTime();
			if (nextTheme === activeTheme) return;
			const result = ctx.ui.setTheme(nextTheme);
			if (result.success) activeTheme = nextTheme;
		};

		applyTimedTheme();
		ctx.ui.setHeader((_tui, theme) => createHeader(pi, theme));
		interval = setInterval(applyTimedTheme, 60_000);
	});

	pi.on("session_shutdown", () => {
		if (interval) clearInterval(interval);
		interval = undefined;
		activeTheme = undefined;
	});
}
