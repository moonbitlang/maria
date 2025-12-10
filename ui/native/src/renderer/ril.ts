import * as ral from "@maria/core/lib/ral.ts";
import type { ElectronRAL } from "@maria/core/lib/types.js";

const _ril: ElectronRAL = {
  platform: "electron",
  electronAPI: window.electronAPI,
};

export function install(): void {
  ral.install(_ril);
}
