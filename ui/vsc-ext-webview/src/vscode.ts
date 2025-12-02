import * as comlink from "comlink";
import * as api from "../../vsc-common/api";
import * as endpoint from "../../vsc-common/endpoint";

declare global {
  function acquireVsCodeApi(): endpoint.Endpoint;
}

class VscodeApiWrapper {
  vscode: endpoint.Endpoint | undefined;

  constructor() {
    if (typeof acquireVsCodeApi === "function") {
      this.vscode = acquireVsCodeApi();
    }
  }

  postMessage(message: unknown) {
    if (this.vscode) {
      this.vscode.postMessage(message);
    } else {
      console.log(message);
    }
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

export const vscode = comlink.wrap<api.VscodeApi>(consumeEndpoint);
