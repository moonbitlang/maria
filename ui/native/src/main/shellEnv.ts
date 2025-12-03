// adopt from https://github.com/microsoft/vscode/blob/b03e656cfa33dfb86705f8631ff704c55d2ac660/src/vs/platform/shell/node/shellEnv.ts#
/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Microsoft Corporation. All rights reserved.
 *  Licensed under the MIT License. See License.txt in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

import { spawn } from "child_process";
import * as crypto from "crypto";
import * as os from "os";
import * as path from "path";

function withAsyncBody<T, E = Error>(
  bodyFn: (
    resolve: (value: T) => unknown,
    reject: (error: E) => unknown,
  ) => Promise<unknown>,
): Promise<T> {
  // eslint-disable-next-line no-async-promise-executor
  return new Promise<T>(async (resolve, reject) => {
    try {
      await bodyFn(resolve, reject);
    } catch (error) {
      reject(error);
    }
  });
}

let unixShellEnvPromise: Promise<typeof process.env> | undefined = undefined;

/**
 * Resolves the shell environment by spawning a shell. This call will cache
 * the shell spawning so that subsequent invocations use that cached result.
 *
 * Will throw an error if:
 * - we hit a timeout of `MAX_SHELL_RESOLVE_TIME`
 * - any other error from spawning a shell to figure out the environment
 */
export async function getResolvedShellEnv(): Promise<typeof process.env> {
  // Skip on windows
  if (os.platform() === "win32") {
    // return {};
    return process.env;
  }

  // Otherwise resolve (macOS, Linux)
  else {
    // Call this only once and cache the promise for
    // subsequent calls since this operation can be
    // expensive (spawns a process).
    if (!unixShellEnvPromise) {
      unixShellEnvPromise = withAsyncBody<NodeJS.ProcessEnv>(
        async (resolve, reject) => {
          let timeoutValue = 10000; // default to 10 seconds

          // Give up resolving shell env after some time
          const timeout = setTimeout(() => {
            reject(
              new Error(
                "Unable to resolve your shell environment in a reasonable time. Please review your shell configuration and restart.",
              ),
            );
          }, timeoutValue);

          // Resolve shell env and handle errors
          try {
            resolve(await doResolveUnixShellEnv());
          } catch (error) {
            reject(new Error("Unable to resolve your shell environment"));
          } finally {
            clearTimeout(timeout);
          }
        },
      );
    }

    return unixShellEnvPromise;
  }
}

async function doResolveUnixShellEnv(): Promise<typeof process.env> {
  const runAsNode = process.env["ELECTRON_RUN_AS_NODE"];

  const noAttach = process.env["ELECTRON_NO_ATTACH_CONSOLE"];

  const mark = crypto.randomUUID().replace(/-/g, "").substring(0, 12);
  const regex = new RegExp(mark + "({.*})" + mark);

  const env = {
    ...process.env,
    ELECTRON_RUN_AS_NODE: "1",
    ELECTRON_NO_ATTACH_CONSOLE: "1",
  };

  const systemShellUnix = os.userInfo().shell;

  return new Promise<typeof process.env>((resolve, reject) => {
    // handle popular non-POSIX shells
    const name = path.basename(systemShellUnix);
    let command: string, shellArgs: Array<string>;
    const extraArgs = "";
    if (/^(?:pwsh|powershell)(?:-preview)?$/.test(name)) {
      // Older versions of PowerShell removes double quotes sometimes so we use "double single quotes" which is how
      // you escape single quotes inside of a single quoted string.
      command = `& '${process.execPath}' ${extraArgs} -p '''${mark}'' + JSON.stringify(process.env) + ''${mark}'''`;
      shellArgs = ["-Login", "-Command"];
    } else if (name === "nu") {
      // nushell requires ^ before quoted path to treat it as a command
      command = `^'${process.execPath}' ${extraArgs} -p '"${mark}" + JSON.stringify(process.env) + "${mark}"'`;
      shellArgs = ["-i", "-l", "-c"];
    } else if (name === "xonsh") {
      // #200374: native implementation is shorter
      command = `import os, json; print("${mark}", json.dumps(dict(os.environ)), "${mark}")`;
      shellArgs = ["-i", "-l", "-c"];
    } else {
      command = `'${process.execPath}' ${extraArgs} -p '"${mark}" + JSON.stringify(process.env) + "${mark}"'`;

      if (name === "tcsh" || name === "csh") {
        shellArgs = ["-ic"];
      } else {
        shellArgs = ["-i", "-l", "-c"];
      }
    }

    const child = spawn(systemShellUnix, [...shellArgs, command], {
      detached: true,
      stdio: ["ignore", "pipe", "pipe"],
      env,
    });

    child.on("error", (err) => {
      reject(err);
    });

    const buffers: Buffer[] = [];
    child.stdout.on("data", (b) => buffers.push(b));

    const stderr: Buffer[] = [];
    child.stderr.on("data", (b) => stderr.push(b));

    child.on("close", (code, signal) => {
      const raw = Buffer.concat(buffers).toString("utf8");

      const stderrStr = Buffer.concat(stderr).toString("utf8");

      if (code || signal) {
        return reject(
          new Error(
            `Unexpected exit code from spawned shell (code ${code}, signal ${signal})`,
          ),
        );
      }

      const match = regex.exec(raw);
      const rawStripped = match ? match[1] : "{}";

      try {
        const env = JSON.parse(rawStripped);

        if (runAsNode) {
          env["ELECTRON_RUN_AS_NODE"] = runAsNode;
        } else {
          delete env["ELECTRON_RUN_AS_NODE"];
        }

        if (noAttach) {
          env["ELECTRON_NO_ATTACH_CONSOLE"] = noAttach;
        } else {
          delete env["ELECTRON_NO_ATTACH_CONSOLE"];
        }

        // https://github.com/microsoft/vscode/issues/22593#issuecomment-336050758
        delete env["XDG_RUNTIME_DIR"];

        resolve(env);
      } catch (err) {
        reject(err);
      }
    });
  });
}
