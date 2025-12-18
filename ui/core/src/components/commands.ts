/* eslint-disable @typescript-eslint/no-explicit-any */
import type * as monaco from "monaco-editor-core";

type Handler = (...args: any[]) => any;

const commands: Record<string, Handler> = {};

export function registerCommand(
  id: string,
  callback: Handler,
): monaco.IDisposable {
  commands[id] = callback;
  return {
    dispose: () => {
      delete commands[id];
    },
  };
}

export function executeCommand(id: string, ...args: any[]): any {
  const handler = commands[id];
  if (!handler) {
    console.error(`Command ${id} not found`);
    return;
  }
  return handler(...args);
}
