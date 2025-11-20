import { createContext, useContext } from "react";

const root = document.getElementById("root")!;

const dataCwd = root.getAttribute("data-cwd");

let cwd: string | undefined = undefined;

if (dataCwd && dataCwd.length > 0) {
  cwd = dataCwd;
}

export const CwdContext = createContext<string | undefined>(cwd);

export function useCwd() {
  const context = useContext(CwdContext);
  return context;
}
