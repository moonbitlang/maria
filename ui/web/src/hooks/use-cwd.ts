import { rootData } from "@/lib/utils";
import { createContext, useContext } from "react";

const cwd = rootData("cwd");

export const CwdContext = createContext<string | undefined>(cwd);

export function useCwd() {
  const context = useContext(CwdContext);
  return context;
}
