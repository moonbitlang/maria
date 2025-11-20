import * as vscode from "vscode";
import { MoonBitAgentViewProvider } from "./view";
import { DaemonService } from "./daemon-service";
import { allTasksView, taskView } from "./commands";
export async function activate(context: vscode.ExtensionContext) {
  const daemonService = DaemonService.instance();
  const cwd = vscode.workspace.workspaceFolders?.[0].uri.fsPath;

  if (cwd === undefined) {
    throw new Error(
      "No workspace folder found. Please open a folder in VSCode to use MoonBit Agent.",
    );
  }

  const taskId = await daemonService.getTaskIdOfDir(cwd);

  const viewProvider = new MoonBitAgentViewProvider(context, cwd, taskId);

  context.subscriptions.push(
    vscode.window.registerWebviewViewProvider(
      MoonBitAgentViewProvider.viewType,
      viewProvider,
      { webviewOptions: { retainContextWhenHidden: true } },
    ),
    vscode.commands.registerCommand("moonbit-agent.allTasksView", allTasksView),
    vscode.commands.registerCommand("moonbit-agent.taskView", taskView),
  );
}

export function deactivate() {}
