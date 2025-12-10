import type { VscodeApi } from "@maria/core/lib/types.js";
import type * as comlink from "comlink";
import * as endpoint from "../../vsc-common/endpoint";

declare global {
  function acquireVsCodeApi(): endpoint.Endpoint;
  interface Window {
    vscodeApi: comlink.Remote<VscodeApi>;
  }
}

class VscodeApiWrapper {
  vscode: endpoint.Endpoint;

  constructor() {
    this.vscode = acquireVsCodeApi();
  }

  postMessage(message: unknown) {
    this.vscode.postMessage(message);
  }
}

const vscodeApi = new VscodeApiWrapper();

export const provideEndpoint: endpoint.Endpoint = endpoint.newEndpoint(
  window,
  vscodeApi.postMessage.bind(vscodeApi),
  "webview-provider",
);

export const consumeEndpoint: endpoint.Endpoint = endpoint.newEndpoint(
  window,
  vscodeApi.postMessage.bind(vscodeApi),
  "vscode-provider",
);
