import * as vscode from "vscode";
import { taskView } from "./commands";
import { set } from "./global-state";
import { MoonBitAgentViewProvider } from "./view";
export async function activate(context: vscode.ExtensionContext) {
  set("context", context);
  const cwd = vscode.workspace.workspaceFolders?.[0].uri.fsPath;

  if (cwd === undefined) {
    throw new Error(
      "No workspace folder found. Please open a folder in VSCode to use Maria.",
    );
  }

  const viewProvider = await MoonBitAgentViewProvider.instance(cwd);

  context.subscriptions.push(
    vscode.window.registerWebviewViewProvider(
      MoonBitAgentViewProvider.viewType,
      viewProvider,
      { webviewOptions: { retainContextWhenHidden: true } },
    ),
    vscode.commands.registerCommand("moonbit-agent.taskView", taskView),
  );
}

export function deactivate() {}
