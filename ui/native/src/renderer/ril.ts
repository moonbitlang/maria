import * as ral from "@maria/core/lib/ral.ts";
import type { RAL } from "@maria/core/lib/types.js";

const _ril: RAL = {
  platform: "electron",
};

export function install(): void {
  ral.install(_ril);
}
