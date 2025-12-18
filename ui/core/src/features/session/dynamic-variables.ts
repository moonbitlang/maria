import type { ChatDynamicVariable } from "../../lib/types";

type HasDynamicVariables = {
  dynamicVariables: ChatDynamicVariable[];
};

export function get<T extends HasDynamicVariables>(
  obj: T,
): ChatDynamicVariable[] {
  return obj.dynamicVariables;
}

export function add<T extends HasDynamicVariables>(
  obj: T,
  variable: ChatDynamicVariable,
): void {
  obj.dynamicVariables.push(variable);
}

export function updateRanges<T extends HasDynamicVariables>(
  obj: T,
  newRanges: { start: number; end: number }[],
): void {
  const currentVariables = obj.dynamicVariables;
  if (newRanges.length !== currentVariables.length) {
    return;
  }
  const newVariables = [];
  for (let i = 0; i < newRanges.length; i++) {
    const range = newRanges[i];
    const variable = currentVariables[i];
    variable.start = range.start;
    variable.end = range.end;
    if (range.start === range.end) {
      continue;
    }
    newVariables.push(variable);
  }
  obj.dynamicVariables = newVariables;
}
