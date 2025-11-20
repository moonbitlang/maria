import { consumeEndpoint, provideEndpoint } from "@/lib/vscode";
import * as comlink from "comlink";
import * as api from "../../../common/api";
import { useEffect, useState } from "react";
import { Outlet } from "react-router";
import { VscodeContext } from "@/hooks/use-vscode";

export default function VscodeLayout() {
  const [vscode, setVscode] = useState<api.VscodeApi | undefined>(undefined);
  useEffect(() => {
    const webviewApi: api.WebviewApi = {
      hello() {
        return 42;
      },
    };

    comlink.expose(webviewApi, provideEndpoint);
    const vscode = comlink.wrap<api.VscodeApi>(consumeEndpoint);
    setVscode(vscode);
  }, []);
  return (
    <VscodeContext.Provider value={vscode}>
      <div className="flex flex-col min-h-0 h-full overflow-x-hidden">
        <Outlet />
      </div>
    </VscodeContext.Provider>
  );
}
