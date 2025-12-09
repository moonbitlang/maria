import * as ral from "@maria/core/lib/ral.ts";
import type { ElectronRAL } from "@maria/core/lib/types.js";

const _ril: ElectronRAL = {
  platform: "electron",
  selectDirectory: window.electronAPI.selectDirectory,
};

export function install(): void {
  ral.install(_ril);
}
