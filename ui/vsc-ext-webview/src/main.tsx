import { makeStore } from "@maria/core/app/store.ts";
import { initialState } from "@maria/core/features/session/homeSlice.js";
import type { WebviewApi } from "@maria/core/lib/types.js";
import Home from "@maria/core/routes/Home.tsx";
import Task from "@maria/core/routes/Task.tsx";
import * as comlink from "comlink";
import { StrictMode, useEffect } from "react";
import { createRoot } from "react-dom/client";
import { Provider } from "react-redux";
import { MemoryRouter, Route, Routes, useNavigate } from "react-router";
import "./index.css";
import Layout from "./layout";
import { install } from "./ril";
import { rootData } from "./utils";
import { provideEndpoint } from "./vscode";

install();

const taskId = rootData("task-id");
const cwd = rootData("cwd");

let initialEntries = ["/"];

if (taskId) {
  initialEntries = [`/tasks/${taskId}`];
}

document.getElementById("_defaultStyles")?.remove();

const container = document.getElementById("root")!;

const root = createRoot(container);

function App() {
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
    <StrictMode>
      <Provider store={makeStore({ home: { ...initialState, cwd } })}>
        <MemoryRouter initialEntries={initialEntries} initialIndex={0}>
          <Routes>
            <Route element={<Layout />}>
              <Route index element={<Home />}></Route>
              <Route path="/tasks/:taskId" element={<Task />}></Route>
            </Route>
          </Routes>
        </MemoryRouter>
      </Provider>
    </StrictMode>
  );
}

root.render(<App />);
