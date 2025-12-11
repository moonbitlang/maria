import fs from "fs";
import os from "os";
import path from "path";

export type DaemonJson = {
  pid: number;
  port: number;
};

export async function getDaemonJson(): Promise<DaemonJson | undefined> {
  try {
    const daemonJsonPath = path.join(os.homedir(), ".moonagent", "daemon.json");
    const daemonJson: DaemonJson = JSON.parse(
      fs.readFileSync(daemonJsonPath, "utf-8"),
    );
    return daemonJson;
  } catch {
    return undefined;
  }
}
