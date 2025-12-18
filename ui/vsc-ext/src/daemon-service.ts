import { setupMariaProcess } from "@maria/core/lib/node/maria-setup.js";
import { getApi } from "@maria/core/lib/node/maria-util.js";
import { TaskOverview } from "@maria/core/lib/types.js";
import { get } from "./global-state";

export class DaemonService {
  _api: string;

  private static _instance: DaemonService;

  static async instance() {
    if (!this._instance) {
      const context = get("context")!;
      const mariaPath = context.asAbsolutePath(`bin/${process.platform}/maria`);
      const [_, error] = await setupMariaProcess(mariaPath);
      if (error) {
        // TODO: Handle error properly
        throw new Error("Failed to setup Maria process: " + error.message);
      }
      const [api, apiError] = await getApi();
      if (apiError) {
        // TODO: Handle error properly
        throw new Error("Failed to get Maria API: " + apiError.message);
      }
      this._instance = new DaemonService(api);
    }
    return this._instance;
  }

  private constructor(api: string) {
    this._api = api;
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

  get api() {
    return this._api;
  }
}
