import * as ral from "@maria/core/lib/ral.ts";
import type { WebRAL } from "@maria/core/lib/types.js";

const _ril: WebRAL = {
  platform: "web",
};

export function install(): void {
  ral.install(_ril);
}
