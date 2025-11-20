import { createContext, useContext } from "react";

const root = document.getElementById("root")!;

const dataTaskId = root.getAttribute("data-task-id");

let taskId: string | undefined = undefined;

if (dataTaskId && dataTaskId.length > 0) {
  taskId = dataTaskId;
}

export const RootTaskIdContext = createContext<string | undefined>(taskId);

export function useRootTaskId() {
  const context = useContext(RootTaskIdContext);
  return context;
}
