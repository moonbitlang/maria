import {
  ChatDynamicVariableInfo,
  CompletionItemKind,
  VscodeApi,
  WebviewApi,
} from "@maria/core/lib/types.js";
import * as comlink from "comlink";
import * as path from "path";
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
  } data: unsafe-inline; style-src ${
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
      getDynamicVariables: getDynamicVariables,
    };
    const webviewApi = comlink.wrap<WebviewApi>(consumeEndpoint);
    globalState.set("webviewApi", webviewApi);
    comlink.expose(vscodeApi, provideEndpoint);
  }
}

function toMonacoCompletionItemKind(
  kind: vscode.CompletionItemKind,
): CompletionItemKind {
  switch (kind) {
    case vscode.CompletionItemKind.Text:
      return CompletionItemKind.Text;
    case vscode.CompletionItemKind.Method:
      return CompletionItemKind.Method;
    case vscode.CompletionItemKind.Function:
      return CompletionItemKind.Function;
    case vscode.CompletionItemKind.Constructor:
      return CompletionItemKind.Constructor;
    case vscode.CompletionItemKind.Field:
      return CompletionItemKind.Field;
    case vscode.CompletionItemKind.Variable:
      return CompletionItemKind.Variable;
    case vscode.CompletionItemKind.Class:
      return CompletionItemKind.Class;
    case vscode.CompletionItemKind.Interface:
      return CompletionItemKind.Interface;
    case vscode.CompletionItemKind.Module:
      return CompletionItemKind.Module;
    case vscode.CompletionItemKind.Property:
      return CompletionItemKind.Property;
    case vscode.CompletionItemKind.Unit:
      return CompletionItemKind.Unit;
    case vscode.CompletionItemKind.Value:
      return CompletionItemKind.Value;
    case vscode.CompletionItemKind.Enum:
      return CompletionItemKind.Enum;
    case vscode.CompletionItemKind.Keyword:
      return CompletionItemKind.Keyword;
    case vscode.CompletionItemKind.Snippet:
      return CompletionItemKind.Snippet;
    case vscode.CompletionItemKind.Color:
      return CompletionItemKind.Color;
    case vscode.CompletionItemKind.Reference:
      return CompletionItemKind.Reference;
    case vscode.CompletionItemKind.File:
      return CompletionItemKind.File;
    case vscode.CompletionItemKind.Folder:
      return CompletionItemKind.Folder;
    case vscode.CompletionItemKind.EnumMember:
      return CompletionItemKind.EnumMember;
    case vscode.CompletionItemKind.Constant:
      return CompletionItemKind.Constant;
    case vscode.CompletionItemKind.Struct:
      return CompletionItemKind.Struct;
    case vscode.CompletionItemKind.Event:
      return CompletionItemKind.Event;
    case vscode.CompletionItemKind.Operator:
      return CompletionItemKind.Operator;
    case vscode.CompletionItemKind.TypeParameter:
      return CompletionItemKind.TypeParameter;
    case vscode.CompletionItemKind.User:
      return CompletionItemKind.User;
    case vscode.CompletionItemKind.Issue:
      return CompletionItemKind.Issue;
  }
}

function symbolKindToMonacoCompletionKind(
  kind: vscode.SymbolKind,
): CompletionItemKind {
  switch (kind) {
    case vscode.SymbolKind.File:
      return CompletionItemKind.File;
    case vscode.SymbolKind.Module:
      return CompletionItemKind.Module;
    case vscode.SymbolKind.Namespace:
      return CompletionItemKind.Module;
    case vscode.SymbolKind.Package:
      return CompletionItemKind.Module;
    case vscode.SymbolKind.Class:
      return CompletionItemKind.Class;
    case vscode.SymbolKind.Method:
      return CompletionItemKind.Method;
    case vscode.SymbolKind.Property:
      return CompletionItemKind.Property;
    case vscode.SymbolKind.Field:
      return CompletionItemKind.Field;
    case vscode.SymbolKind.Constructor:
      return CompletionItemKind.Constructor;
    case vscode.SymbolKind.Enum:
      return CompletionItemKind.Enum;
    case vscode.SymbolKind.Interface:
      return CompletionItemKind.Interface;
    case vscode.SymbolKind.Function:
      return CompletionItemKind.Function;
    case vscode.SymbolKind.Variable:
      return CompletionItemKind.Variable;
    case vscode.SymbolKind.Constant:
      return CompletionItemKind.Constant;
    case vscode.SymbolKind.String:
      return CompletionItemKind.Value;
    case vscode.SymbolKind.Number:
      return CompletionItemKind.Value;
    case vscode.SymbolKind.Boolean:
      return CompletionItemKind.Value;
    case vscode.SymbolKind.Array:
      return CompletionItemKind.Value;
    case vscode.SymbolKind.Object:
      return CompletionItemKind.Value;
    case vscode.SymbolKind.Key:
      return CompletionItemKind.Property;
    case vscode.SymbolKind.Null:
      return CompletionItemKind.Value;
    case vscode.SymbolKind.EnumMember:
      return CompletionItemKind.EnumMember;
    case vscode.SymbolKind.Struct:
      return CompletionItemKind.Struct;
    case vscode.SymbolKind.Event:
      return CompletionItemKind.Event;
    case vscode.SymbolKind.Operator:
      return CompletionItemKind.Operator;
    case vscode.SymbolKind.TypeParameter:
      return CompletionItemKind.TypeParameter;
  }
}

function fileUriToVscodeProtocol(
  uri: vscode.Uri,
  position?: vscode.Position,
): string {
  const fsPath = uri.fsPath;
  let pos = "";
  if (position) {
    pos = `:${position.line + 1}:${position.character + 1}`;
  }
  return `vscode://file${fsPath}${pos}`;
}

async function getDynamicVariables(
  query: string,
): Promise<ChatDynamicVariableInfo[]> {
  const pattern = query
    .split("")
    .map((char) => {
      const lower = char.toLowerCase();
      const upper = char.toUpperCase();
      return lower !== upper ? `[${lower}${upper}]` : char;
    })
    .join("");
  const files = await vscode.workspace.findFiles(`**/*${pattern}*`, null, 10);
  const workspaceSymbols = (await vscode.commands.executeCommand(
    "vscode.executeWorkspaceSymbolProvider",
    query,
  )) as vscode.SymbolInformation[];
  const fileVariables: ChatDynamicVariableInfo[] = files.map((file) => {
    return {
      kind: "file",
      name: path.basename(file.fsPath),
      itemKind: toMonacoCompletionItemKind(vscode.CompletionItemKind.File),
      uri: fileUriToVscodeProtocol(file),
    };
  });
  const symbolVariables: ChatDynamicVariableInfo[] = workspaceSymbols.map(
    (symbol) => {
      return {
        kind: "symbol",
        name: symbol.name,
        itemKind: symbolKindToMonacoCompletionKind(symbol.kind),
        uri: fileUriToVscodeProtocol(
          symbol.location.uri,
          symbol.location.range.start,
        ),
      };
    },
  );
  return [...fileVariables, ...symbolVariables];
}
