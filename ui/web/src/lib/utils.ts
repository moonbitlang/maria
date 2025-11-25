import { clsx, type ClassValue } from "clsx";
import { twMerge } from "tailwind-merge";

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

export function rootData(key: string): string | undefined {
  const root = document.getElementById("root")!;
  const dataValue = root.getAttribute(`data-${key}`);
  if (dataValue && dataValue.length > 0) {
    return dataValue;
  }
  return undefined;
}
