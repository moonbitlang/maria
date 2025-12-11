import fsp from "fs/promises";
import os from "os";
import path from "path";
import type { ResultTuple } from "../types";

type DaemonJson = {
  pid: number;
  port: number;
};

async function getDaemonJson(): Promise<ResultTuple<DaemonJson>> {
  try {
    const daemonJsonPath = path.join(os.homedir(), ".moonagent", "daemon.json");
    const daemonJson: DaemonJson = JSON.parse(
      await fsp.readFile(daemonJsonPath, "utf-8"),
    );
    return [daemonJson, undefined];
  } catch (error) {
    return [undefined, error as Error];
  }
}

export async function getApi(): Promise<ResultTuple<string>> {
  const [json, error] = await getDaemonJson();
  if (error) {
    return [undefined, error];
  } else {
    return [`http://localhost:${json.port}/v1`, undefined];
  }
}

export async function shutdown(): Promise<ResultTuple<undefined>> {
  try {
    const [api, error] = await getApi();
    if (error) {
      return [undefined, error];
    }
    const res = await fetch(`${api}/shutdown`, {
      method: "POST",
    });
    if (!res.ok) {
      return [
        undefined,
        new Error(
          `Shutdown request failed with status ${res.status}: ${res.statusText}`,
        ),
      ];
    }
    return [undefined, undefined];
  } catch (error) {
    return [undefined, error as Error];
  }
}
