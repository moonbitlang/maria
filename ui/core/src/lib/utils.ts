import { clsx, type ClassValue } from "clsx";
import { twMerge } from "tailwind-merge";
import type { ChatDynamicVariable, ResultTuple } from "./types";

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}
export function base(path: string): string | undefined {
  return path.split(/\/|\\/).at(-1);
}

export function jsonParseSafe<T>(str: string): ResultTuple<T> {
  try {
    return [JSON.parse(str) as T, undefined];
  } catch (error) {
    return [undefined, error as Error];
  }
}

export function composeMessage(
  input: string,
  dynamicVariables: ChatDynamicVariable[],
): string {
  const chars = input.split("");
  for (const v of dynamicVariables) {
    switch (v.info.kind) {
      case "command": {
        continue;
      }
      case "file": {
        const { name, uri } = v.info;
        const fileLink = `[${name}](${uri})`;
        chars.splice(v.start, v.end - v.start, fileLink);
        break;
      }
      case "symbol": {
        const {
          symbolRange: {
            startLineNumber,
            startColumn,
            endLineNumber,
            endColumn,
          },
          name,
          uri,
        } = v.info;
        const symbolLink = `[${name}](${uri}#${startLineNumber}:${startColumn}-${endLineNumber}:${endColumn})`;
        chars.splice(v.start, v.end - v.start, symbolLink);
        break;
      }
    }
  }
  return chars.join("");
}
