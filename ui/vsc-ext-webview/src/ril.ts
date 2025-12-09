import * as ral from "@maria/core/lib/ral.ts";
import type { VSCWebviewRAL } from "@maria/core/lib/types.js";

const _ril: VSCWebviewRAL = {
  platform: "vsc-webview",
};

export function install(): void {
  ral.install(_ril);
}
