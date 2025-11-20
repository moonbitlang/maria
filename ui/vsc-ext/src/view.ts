import * as vscode from "vscode";

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

  private _view: vscode.WebviewView | undefined;

  constructor(context: vscode.ExtensionContext) {
    this._context = context;
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
  <meta http-equiv="Content-Security-Policy" content="default-src 'none'; connect-src http:; font-src ${webview.cspSource} unsafe-inline; style-src ${webview.cspSource} 'unsafe-inline'; script-src 'nonce-${nonce}'; worker-src blob:;">

  <meta name="viewport" content="width=device-width, initial-scale=1.0">

  <link href="${styleUri}" rel="stylesheet">
  <style>html, body, #root { height: 100%; margin: 0; }</style>
  <script type="module" nonce="${nonce}" src="${scriptUri}"></script>

  <title>MoonBit Agent</title>
</head>
<body>
  <div id="root"></div>
</body>
</html>`;
  }

  resolveWebviewView(
    webviewView: vscode.WebviewView,
    _context: vscode.WebviewViewResolveContext,
    _token: vscode.CancellationToken,
  ): Thenable<void> | void {
    this._view = webviewView;

    // TODO: start daemon and setup port mapping here
    this._view.webview.options = {
      enableScripts: true,
      portMapping: [{ extensionHostPort: 8090, webviewPort: 8090 }],
    };

    this._view.webview.html = this._getHtmlForWebview(this._view.webview);
  }
}
