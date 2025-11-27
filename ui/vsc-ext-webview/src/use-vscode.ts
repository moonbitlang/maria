import { createContext, useContext } from "react";
import * as api from "../../vsc-common/api";

export const VscodeContext = createContext<api.VscodeApi | undefined>(
  undefined,
);

export function useVscode() {
  const context = useContext(VscodeContext);
  if (context === undefined) {
    throw new Error("useVscode must be used within VscodeLayout");
  }
  return context;
}
