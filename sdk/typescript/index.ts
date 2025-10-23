import { spawn } from "node:child_process";
import { access, constants } from "node:fs/promises";
import { join } from "node:path";
import { arch, platform } from "node:os";
import { fileURLToPath } from "node:url";
import { dirname } from "node:path";
import type { Notification } from "./events.js";
import { parseNotification } from "./events.js";

function getSystem(): string {
    const platformName = platform().toLowerCase();
    const architecture = arch().toLowerCase();

    // Map Node.js platform/arch names to the expected format
    const platformMap: Record<string, string> = {
        "win32": "win32",
        "darwin": "darwin",
        "linux": "linux",
    };

    const archMap: Record<string, string> = {
        "x64": "x86_64",
        "arm64": "arm64",
        "ia32": "i386",
    };

    const mappedPlatform = platformMap[platformName] || platformName;
    const mappedArch = archMap[architecture] || architecture;

    return `${mappedPlatform}-${mappedArch}`;
}

export class Maria {
    async *start(prompt: string): AsyncGenerator<Notification, void, unknown> {
        const system = getSystem();
        const executableName = `${system}.exe`;

        // Try to find the executable in the package's bin directory
        const currentDir = dirname(fileURLToPath(import.meta.url));
        const executablePath = join(currentDir, "bin", executableName);

        // Check if executable exists and is accessible
        try {
            await access(executablePath, constants.F_OK | constants.X_OK);
        } catch (error) {
            throw new Error(
                `Maria executable not found at ${executablePath}. Make sure the correct binary is included for your platform.`,
            );
        }

        // Spawn the Maria process
        const child = spawn(executablePath, ["exec", prompt], {
            stdio: ["ignore", "pipe", "pipe"],
        });

        if (!child.stdout) {
            throw new Error("Failed to create stdout pipe for Maria process");
        }

        // Set up error handling
        const errorPromise = new Promise<void>((_, reject) => {
            child.on("error", (error: Error) => {
                reject(
                    new Error(
                        `Failed to start Maria process: ${error.message}`,
                    ),
                );
            });

            child.on("exit", (code: number | null) => {
                if (code !== 0) {
                    reject(new Error(`Maria process exited with code ${code}`));
                }
            });
        });

        // Read stdout line by line
        let buffer = "";

        try {
            for await (const chunk of child.stdout) {
                buffer += chunk.toString();

                // Process complete lines
                const lines = buffer.split("\n");
                buffer = lines.pop() || ""; // Keep the incomplete line in buffer

                for (const line of lines) {
                    if (line.trim()) {
                        try {
                            yield parseNotification(line.trim());
                        } catch (error) {
                            console.warn(
                                `Failed to parse notification: ${error}`,
                            );
                        }
                    }
                }
            }

            // Process any remaining data in buffer
            if (buffer.trim()) {
                try {
                    yield parseNotification(buffer.trim());
                } catch (error) {
                    console.warn(
                        `Failed to parse final notification: ${error}`,
                    );
                }
            }

            // Wait for the process to exit normally
            await new Promise<void>((resolve, reject) => {
                child.on("exit", (code: number | null) => {
                    if (code === 0) {
                        resolve();
                    } else {
                        reject(
                            new Error(`Maria process exited with code ${code}`),
                        );
                    }
                });
            });
        } catch (error) {
            // Kill the process if still running
            if (!child.killed) {
                child.kill();
            }
            throw error;
        }
    }
}

export * from "./events.js";
