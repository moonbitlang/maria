import { useEventsQuery } from "@maria/core/features/api/apiSlice.ts";
import type { WebviewApi } from "@maria/core/lib/types.js";
import * as comlink from "comlink";
import { useEffect } from "react";
import { Outlet, useNavigate } from "react-router";
import { provideEndpoint } from "./vscode";

export default function Layout() {
  useEventsQuery();

  const routerNav = useNavigate();
  useEffect(() => {
    const webviewApi: WebviewApi = {
      navigate(path: string) {
        routerNav(path);
      },
    };

    comlink.expose(webviewApi, provideEndpoint);
  }, [routerNav]);
  return (
    <div className="flex h-full min-h-0 flex-col overflow-x-hidden">
      <Outlet />
    </div>
  );
}
