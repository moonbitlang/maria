import { getDaemonJson } from "@maria/core/lib/node/daemon-json.js";
import { shutdown } from "@maria/core/lib/node/maria-util.js";
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

  const currentVersion: string = context.extension.packageJSON.version;
  const previousVersion = context.globalState.get<string>("extensionVersion");

  if (!previousVersion || previousVersion !== currentVersion) {
    // shut down daemon on version change
    const daemonJson = await getDaemonJson();
    if (daemonJson) {
      await shutdown(daemonJson.port);
    }
  }

  await context.globalState.update("extensionVersion", currentVersion);

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
