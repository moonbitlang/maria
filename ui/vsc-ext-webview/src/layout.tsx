import { useEventsQuery } from "@maria/core/features/api/apiSlice.ts";
import * as comlink from "comlink";
import { useEffect, useState } from "react";
import { Outlet, useNavigate } from "react-router";
import * as api from "../../vsc-common/api";
import { VscodeContext } from "./use-vscode";
import { consumeEndpoint, provideEndpoint } from "./vscode";

export default function Layout() {
  useEventsQuery();
  const [vscode, setVscode] = useState<api.VscodeApi | undefined>(undefined);
  const routerNav = useNavigate();
  useEffect(() => {
    const webviewApi: api.WebviewApi = {
      navigate(path: string) {
        routerNav(path);
      },
    };

    comlink.expose(webviewApi, provideEndpoint);
    const vscode = comlink.wrap<api.VscodeApi>(consumeEndpoint);
    setVscode(vscode);
  }, [routerNav]);
  return (
    <VscodeContext.Provider value={vscode}>
      <div className="flex h-full min-h-0 flex-col overflow-x-hidden">
        <Outlet />
      </div>
    </VscodeContext.Provider>
  );
}
