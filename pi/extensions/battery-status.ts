import { execFile } from "node:child_process";
import { promisify } from "node:util";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const execFileAsync = promisify(execFile);
const STATUS_KEY = "battery";
const UPDATE_INTERVAL_MS = 60_000;

let batteryPercent: number | undefined;
let batteryCharging = false;

async function refreshBattery(): Promise<void> {
	try {
		const { stdout } = await execFileAsync("pmset", ["-g", "batt"]);
		const pctMatch = stdout.match(/(\d+)%/);
		batteryPercent = pctMatch ? Number.parseInt(pctMatch[1], 10) : undefined;
		// Word-boundary regex to avoid matching "discharging"
		batteryCharging = /\bcharging\b/.test(stdout);
	} catch {
		batteryPercent = undefined;
		batteryCharging = false;
	}
}

export default function (pi: ExtensionAPI) {
	let interval: NodeJS.Timeout | undefined;
	let generation = 0;

	pi.on("session_start", (_event, ctx) => {
		if (interval) clearInterval(interval);
		const currentGeneration = ++generation;

		const update = async () => {
			await refreshBattery();
			if (currentGeneration !== generation) return;

			const theme = ctx.ui.theme;
			if (batteryPercent == null || Number.isNaN(batteryPercent)) {
				ctx.ui.setStatus(STATUS_KEY, undefined);
				return;
			}

			// Green above 20%, red at or below 20%. No yellow — hard to read on dark themes.
			const color = batteryPercent <= 20 ? "error" : "success";
			const icon = batteryCharging ? "⚡" : "🔋";
			ctx.ui.setStatus(STATUS_KEY, theme.fg(color, `${icon} ${batteryPercent}%`));
		};

		// Never hold up session creation/reload while pmset runs.
		void update();
		interval = setInterval(() => void update(), UPDATE_INTERVAL_MS);
		interval.unref();
	});

	pi.on("session_shutdown", () => {
		generation++;
		if (interval) clearInterval(interval);
		interval = undefined;
		batteryPercent = undefined;
		batteryCharging = false;
	});
}
