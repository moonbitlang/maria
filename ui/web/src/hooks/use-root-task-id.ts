import { rootData } from "@/lib/utils";
import { createContext, useContext } from "react";

const taskId = rootData("task-id");

export const RootTaskIdContext = createContext<string | undefined>(taskId);

export function useRootTaskId() {
  const context = useContext(RootTaskIdContext);
  return context;
}
