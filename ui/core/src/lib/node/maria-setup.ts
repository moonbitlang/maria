import cp from "child_process";
import { getDaemonJson, type DaemonJson } from "./daemon-json";

let setupMariaPromise: Promise<DaemonJson> | undefined = undefined;

export async function setupMariaProcess(mariaPath: string) {
  if (setupMariaPromise) {
    return await setupMariaPromise;
  }
  setupMariaPromise = doSetupMariaProcess(mariaPath);
  return await setupMariaPromise;
}

async function doSetupMariaProcess(mariaPath: string): Promise<DaemonJson> {
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

  // daemon.json is guaranteed to exist after the daemon starts
  const daemonJson = await getDaemonJson();
  return daemonJson!;
}
