import { VscodeApi, WebviewApi } from "@maria/core/lib/types.js";
import * as comlink from "comlink";
import * as vscode from "vscode";
import * as endpoint from "../../vsc-common/endpoint";
import { DaemonService } from "./daemon-service";
import * as globalState from "./global-state";

function getNonce() {
  let text = "";
  const possible =
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
  for (let i = 0; i < 32; i++) {
    text += possible.charAt(Math.floor(Math.random() * possible.length));
  }
  return text;
}

export class MoonBitAgentViewProvider implements vscode.WebviewViewProvider {
  public static readonly viewType = "moonbit-agent.view";
  private _context: vscode.ExtensionContext;

  private _daemonService: DaemonService;

  private _taskId: string | undefined;

  private _cwd: string | undefined;

  private _view: vscode.WebviewView | undefined;

  private static _instance: MoonBitAgentViewProvider;

  static async instance(cwd: string): Promise<MoonBitAgentViewProvider> {
    if (!this._instance) {
      const daemonService = await DaemonService.instance();
      const context = globalState.get("context")!;
      const taskId = await daemonService.getTaskIdOfDir(cwd);
      this._instance = new MoonBitAgentViewProvider(
        context,
        daemonService,
        cwd,
        taskId,
      );
    }
    return this._instance;
  }

  constructor(
    context: vscode.ExtensionContext,
    daemonService: DaemonService,
    cwd: string | undefined,
    taskId: string | undefined,
  ) {
    this._context = context;
    this._daemonService = daemonService;
    this._taskId = taskId;
    this._cwd = cwd;
  }

  private _getHtmlForWebview(webview: vscode.Webview) {
    // Get the local path to main script run in the webview, then convert it to a uri we can use in the webview.
    const scriptUri = webview.asWebviewUri(
      vscode.Uri.joinPath(this._context.extensionUri, "webview", "index.js"),
    );
    const styleUri = webview.asWebviewUri(
      vscode.Uri.joinPath(this._context.extensionUri, "webview", "index.css"),
    );
    // Use a nonce to only allow a specific script to be run.
    const nonce = getNonce();

    return /*html*/ `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">

  <!--
    Use a content security policy to only allow loading styles from our extension directory,
    and only allow scripts that have a specific nonce.
    (See the 'webview-sample' extension sample for img-src content security policy examples)
  -->
  <meta http-equiv="Content-Security-Policy" content="default-src 'none'; connect-src http:; font-src ${
    webview.cspSource
  } unsafe-inline; style-src ${
    webview.cspSource
  } 'unsafe-inline'; script-src 'nonce-${nonce}'; worker-src blob:;">

  <meta name="viewport" content="width=device-width, initial-scale=1.0">

  <link href="${styleUri}" rel="stylesheet">
  <style>html, body, #root { height: 100%; margin: 0; }</style>
  <script type="module" nonce="${nonce}" src="${scriptUri}"></script>

  <title>MoonBit Agent</title>
</head>
<body>
  <div id="root" data-task-id="${this._taskId ?? ""}" data-cwd="${
    this._cwd ?? ""
  }"></div>
</body>
</html>`;
  }

  resolveWebviewView(
    webviewView: vscode.WebviewView,
    _context: vscode.WebviewViewResolveContext,
    _token: vscode.CancellationToken,
  ): Thenable<void> | void {
    this._view = webviewView;

    this._view.webview.options = {
      enableScripts: true,
    };

    this._view.webview.html = this._getHtmlForWebview(this._view.webview);

    const listeners: Array<(event: unknown) => void> = [];

    this._view.webview.onDidReceiveMessage((message) => {
      for (const listener of listeners) {
        listener({ data: message });
      }
    });

    const endpointProvider: endpoint.EndpointProvider = {
      addEventListener(_type, listener) {
        listeners.push(listener);
      },
    };

    const provideEndpoint = endpoint.newEndpoint(
      endpointProvider,
      webviewView.webview.postMessage.bind(webviewView.webview),
      "vscode-provider",
    );

    const consumeEndpoint = endpoint.newEndpoint(
      endpointProvider,
      webviewView.webview.postMessage.bind(webviewView.webview),
      "webview-provider",
    );

    const vscodeApi: VscodeApi = {
      getUrl: () => {
        return this._daemonService.api;
      },
    };
    const webviewApi = comlink.wrap<WebviewApi>(consumeEndpoint);
    globalState.set("webviewApi", webviewApi);
    comlink.expose(vscodeApi, provideEndpoint);
  }
}
