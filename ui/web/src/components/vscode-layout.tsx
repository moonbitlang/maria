import { consumeEndpoint, provideEndpoint } from "@/lib/vscode";
import * as comlink from "comlink";
import * as api from "../../../common/api";
import { useEffect, useState } from "react";
import { Outlet, useNavigate } from "react-router";
import { VscodeContext } from "@/hooks/use-vscode";
import { useEventsQuery } from "@/features/api/apiSlice";

export default function VscodeLayout() {
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
      <div className="flex flex-col min-h-0 h-full overflow-x-hidden">
        <Outlet />
      </div>
    </VscodeContext.Provider>
  );
}
