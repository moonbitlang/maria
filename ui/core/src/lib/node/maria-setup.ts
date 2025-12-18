import cp from "child_process";
import type { ResultTuple } from "../types";

let setupMariaPromise: Promise<ResultTuple<undefined>> | undefined = undefined;

export async function setupMariaProcess(
  mariaPath: string,
  env?: NodeJS.ProcessEnv,
) {
  if (setupMariaPromise) {
    return await setupMariaPromise;
  }
  setupMariaPromise = doSetupMariaProcess(mariaPath, env ?? process.env);
  return await setupMariaPromise;
}

async function doSetupMariaProcess(
  mariaPath: string,
  env: NodeJS.ProcessEnv,
): Promise<ResultTuple<undefined>> {
  const exitCode = await new Promise<number | null>((resolve, reject) => {
    const maria = cp.spawn(mariaPath, ["daemon", "--port", "0", "--detach"], {
      stdio: "ignore",
      env,
    });

    maria.on("error", reject);
    maria.on("exit", (code) => {
      resolve(code);
    });
  });

  if (exitCode !== 0) {
    if (
      process.env["OPENAI_API_KEY"] === undefined &&
      process.env["OPENROUTER_API_KEY"] === undefined
    ) {
      return [
        undefined,
        new Error(
          "OPENAI_API_KEY or OPENROUTER_API_KEY is not set in the shell environment",
        ),
      ];
    }
    return [undefined, new Error(`Maria daemon exited with code ${exitCode}`)];
  }
  return [undefined, undefined];
}
