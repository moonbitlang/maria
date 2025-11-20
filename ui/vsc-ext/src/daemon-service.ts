import { TaskOverview } from "../../common/types";

export class DaemonService {
  _port: number;
  _api: string;

  constructor(port: number = 8090) {
    this._port = port;
    this._api = `http://localhost:${this._port}/v1`;
  }

  async getTasks(): Promise<TaskOverview[]> {
    const res = await fetch(`${this._api}/tasks`, { method: "GET" });
    const data = (await res.json()) as { tasks: TaskOverview[] };
    return data.tasks;
  }

  get port() {
    return this._port;
  }
}
