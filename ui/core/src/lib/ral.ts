import type { RAL } from "./types";

let _ral: RAL | undefined;

export function RAL(): RAL {
  if (_ral === undefined) {
    throw new Error("No runtime abstraction layer installed");
  }
  return _ral;
}

export function install(ral: RAL): void {
  _ral = ral;
}
