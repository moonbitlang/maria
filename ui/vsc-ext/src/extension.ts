import * as vscode from "vscode";
import { MoonBitAgentViewProvider } from "./view";
import { DaemonService } from "./daemon-service";
export async function activate(context: vscode.ExtensionContext) {
  const daemonService = new DaemonService();
  const cwd = vscode.workspace.workspaceFolders?.[0].uri.fsPath;

  if (cwd === undefined) {
    vscode.window.showErrorMessage(
      "No workspace folder found. Please open a folder in VSCode to use MoonBit Agent.",
    );
    return;
  }

  const tasks = await daemonService.getTasks();

  let taskId: string | undefined = undefined;

  for (const task of tasks) {
    if (task.cwd === cwd) {
      taskId = task.id;
    }
  }

  const viewProvider = new MoonBitAgentViewProvider(context, taskId);

  context.subscriptions.push(
    vscode.window.registerWebviewViewProvider(
      MoonBitAgentViewProvider.viewType,
      viewProvider,
      { webviewOptions: { retainContextWhenHidden: true } },
    ),
  );
}

export function deactivate() {}
