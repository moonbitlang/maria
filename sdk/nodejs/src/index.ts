import { spawn } from "child_process";
import { join, dirname } from "path";
import { fileURLToPath } from "url";
import { platform, arch } from "os";
import { Notification } from "./events";

function getSystem(): string {
  const platformName = platform().toLowerCase();
  const archName = arch().toLowerCase();
  return `${platformName}-${archName}`;
}

export class Maria {
  async *start(prompt: string): AsyncGenerator<Notification, void, unknown> {
    const system = getSystem();

    // Get the path to the bin directory relative to this file
    const __dirname = dirname(fileURLToPath(import.meta.url));
    const executablePath = join(__dirname, "..", "bin", `${system}.exe`);

    const process = spawn(executablePath, ["exec", prompt], {
      stdio: ["ignore", "pipe", "inherit"],
    });

    if (!process.stdout) {
      throw new Error("Failed to spawn Maria process: stdout is null");
    }

    let buffer = "";

    for await (const chunk of process.stdout) {
      buffer += chunk.toString();
      const lines = buffer.split("\n");
      buffer = lines.pop() || "";

      for (const line of lines) {
        if (line.trim()) {
          try {
            const notification: Notification = JSON.parse(line);
            yield notification;
          } catch (error) {
            throw new Error(`Failed to parse notification: ${line}`);
          }
        }
      }
    }

    // Process any remaining data in buffer
    if (buffer.trim()) {
      try {
        const notification: Notification = JSON.parse(buffer);
        yield notification;
      } catch (error) {
        throw new Error(`Failed to parse notification: ${buffer}`);
      }
    }

    const exitCode = await new Promise<number | null>((resolve) => {
      process.on("close", resolve);
    });

    if (exitCode !== 0) {
      throw new Error(`Maria process failed with exit code: ${exitCode}`);
    }
  }
}

export * from "./events";
