import { setupMariaProcess } from "@maria/core/lib/node.js";
import { TaskOverview } from "@maria/core/lib/types.js";
import { get } from "./global-state";

export class DaemonService {
  _port: number;
  _api: string;

  private static _instance: DaemonService;

  static async instance() {
    if (!this._instance) {
      const context = get("context")!;
      const mariaPath = context.asAbsolutePath("bin/maria");
      const daemonJson = await setupMariaProcess(mariaPath);
      this._instance = new DaemonService(daemonJson.port);
    }
    return this._instance;
  }

  private constructor(port: number) {
    this._port = port;
    this._api = `http://localhost:${this._port}/v1`;
  }

  private async _getTasks(): Promise<TaskOverview[]> {
    try {
      const res = await fetch(`${this._api}/tasks`, { method: "GET" });
      const data = (await res.json()) as { tasks: TaskOverview[] };
      return data.tasks;
    } catch {
      throw new Error(
        "Could not connect to daemon. Please ensure that the daemon is running.",
      );
    }
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

  get api() {
    return this._api;
  }
}
