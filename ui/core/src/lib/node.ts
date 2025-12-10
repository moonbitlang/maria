import cp from "child_process";
import fs from "fs";
import os from "os";
import path from "path";

type DaemonJson = {
  pid: number;
  port: number;
};

let setupMariaPromise: Promise<DaemonJson> | undefined = undefined;

export async function setupMariaProcess(mariaPath: string) {
  if (setupMariaPromise) {
    return await setupMariaPromise;
  }
  setupMariaPromise = doSetupMariaProcess(mariaPath);
  return await setupMariaPromise;
}

async function doSetupMariaProcess(mariaPath: string) {
  const exitCode = await new Promise<number | null>((resolve, reject) => {
    const maria = cp.spawn(mariaPath, ["daemon", "--port", "0", "--detach"], {
      stdio: "ignore",
    });

    maria.on("error", reject);
    maria.on("exit", (code) => {
      resolve(code);
    });
  });

  if (exitCode !== 0) {
    if (
      process.env["OPENAI_API_KEY"] === undefined ||
      process.env["OPENROUTER_API_KEY"] === undefined
    ) {
      throw new Error(
        "OPENAI_API_KEY or OPENROUTER_API_KEY is not set in the shell environment",
      );
    }
    throw new Error(`Maria daemon exited with code ${exitCode}`);
  }

  const daemonJsonPath = path.join(os.homedir(), ".moonagent", "daemon.json");
  const daemonJson: DaemonJson = JSON.parse(
    fs.readFileSync(daemonJsonPath, "utf-8"),
  );
  return daemonJson;
}
