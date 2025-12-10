import * as vscode from "vscode";
import { DaemonService } from "./daemon-service";
import * as globalState from "./global-state";

function getWebviewApi() {
  const webviewApi = globalState.get("webviewApi");
  if (webviewApi === undefined) {
    vscode.window.showErrorMessage("Moon Agent webview is not initialized.");
    return;
  }
  return webviewApi;
}

export async function taskView() {
  const webviewApi = getWebviewApi();
  const cwd = vscode.workspace.workspaceFolders?.[0].uri.fsPath;
  if (cwd === undefined) {
    await webviewApi?.navigate("/");
  } else {
    const daemonService = await DaemonService.instance();
    const taskId = await daemonService.getTaskIdOfDir(cwd);
    if (taskId === undefined) {
      await webviewApi?.navigate("/");
    } else {
      await webviewApi?.navigate(`/tasks/${taskId}`);
    }
  }
}
