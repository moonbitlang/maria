import * as vscode from "vscode";
import * as webview from "./view";
export function activate(context: vscode.ExtensionContext) {
  const viewProvider = new webview.MoonBitAgentViewProvider(context);

  context.subscriptions.push(
    vscode.window.registerWebviewViewProvider(
      webview.MoonBitAgentViewProvider.viewType,
      viewProvider,
    ),
  );
}

export function deactivate() {}
