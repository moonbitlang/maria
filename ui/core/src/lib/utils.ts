import { clsx, type ClassValue } from "clsx";
import { twMerge } from "tailwind-merge";
import type { ResultTuple } from "./types";

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
