import * as vscode from "vscode";
import { TaskOverview } from "../../common/types";

export class DaemonService {
  _port: number;
  _api: string;

  private static _instance: DaemonService;

  static instance(port: number = 8090) {
    if (!this._instance) {
      this._instance = new DaemonService(port);
    }
    return this._instance;
  }

  private constructor(port: number = 8090) {
    this._port = port;
    this._api = `http://localhost:${this._port}/v1`;
  }

  private async _getTasks(): Promise<TaskOverview[]> {
    const res = await fetch(`${this._api}/tasks`, { method: "GET" });
    const data = (await res.json()) as { tasks: TaskOverview[] };
    return data.tasks;
  }

  async getTaskIdOfDir(dir: string): Promise<string | undefined> {
    const tasks = await this._getTasks();

    let taskId: string | undefined = undefined;

    for (const task of tasks) {
      if (task.cwd === dir) {
        taskId = task.id;
      }
    }
    return taskId;
  }

  get port() {
    return this._port;
  }
}
