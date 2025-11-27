export function rootData(key: string): string | undefined {
  const root = document.getElementById("root")!;
  const dataValue = root.getAttribute(`data-${key}`);
  if (dataValue && dataValue.length > 0) {
    return dataValue;
  }
  return undefined;
}
