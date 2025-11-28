import { clsx, type ClassValue } from "clsx";
import { twMerge } from "tailwind-merge";

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}
export function base(path: string): string | undefined {
  return path.split(/\/|\\/).at(-1);
}
