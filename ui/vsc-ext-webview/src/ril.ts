import * as ral from "@maria/core/lib/ral.ts";
import type { VscodeApi, VSCWebviewRAL } from "@maria/core/lib/types.js";
import * as comlink from "comlink";
import { consumeEndpoint } from "./vscode";

window.vscodeApi = comlink.wrap<VscodeApi>(consumeEndpoint);

const _ril: VSCWebviewRAL = {
  platform: "vsc-webview",
  vscodeApi: window.vscodeApi,
};

export function install(): void {
  ral.install(_ril);
}
