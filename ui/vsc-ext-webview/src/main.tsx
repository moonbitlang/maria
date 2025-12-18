import { makeStore } from "@maria/core/app/store.ts";
import { Skeleton } from "@maria/core/components/ui/skeleton.js";
import * as homeSlice from "@maria/core/features/session/homeSlice.js";
import Home from "@maria/core/routes/Home.tsx";
import Task from "@maria/core/routes/Task.tsx";
import { StrictMode, Suspense, use, useEffect, useState } from "react";
import { createRoot } from "react-dom/client";
import { Provider } from "react-redux";
import { MemoryRouter, Route, Routes } from "react-router";
import "./index.css";
import Layout from "./layout";
import { install } from "./ril";
import { rootData } from "./utils";

install();

const taskId = rootData("task-id");
const cwd = rootData("cwd");

function updateBodyDarkClass() {
  const themeKind = document.body.dataset.vscodeThemeKind;
  const isDark =
    themeKind === "vscode-dark" || themeKind === "vscode-high-contrast";
  if (isDark) {
    document.body.classList.add("dark");
  } else {
    document.body.classList.remove("dark");
  }
}

updateBodyDarkClass();

const bodyObserver = new MutationObserver((mutations) => {
  for (const mutation of mutations) {
    if (
      mutation.type === "attributes" &&
      mutation.attributeName === "data-vscode-theme-kind" &&
      mutation.target instanceof HTMLBodyElement
    ) {
      updateBodyDarkClass();
    }
  }
});

bodyObserver.observe(document.body, {
  attributes: true,
  attributeFilter: ["data-vscode-theme-kind"],
});

const initialEntries = taskId === undefined ? ["/"] : [`/tasks/${taskId}`];

document.getElementById("_defaultStyles")?.remove();

const container = document.getElementById("root")!;

const mariaReadyPromise = (async () => {
  return await window.vscodeApi.getUrl();
})();

function LoadingFallback() {
  const [showLoading, setShowLoading] = useState(false);

  useEffect(() => {
    const timer = setTimeout(() => setShowLoading(true), 200);
    return () => clearTimeout(timer);
  }, []);

  if (!showLoading) {
    return null;
  }

  return (
    <div className="bg-background flex h-screen w-screen">
      {/* Sidebar skeleton */}
      <div className="border-sidebar-border bg-sidebar hidden w-64 flex-col gap-4 border-r p-4 md:flex">
        {/* Sidebar header */}
        <div className="flex items-center gap-2">
          <Skeleton className="h-8 w-8 rounded-md" />
          <Skeleton className="h-5 flex-1" />
        </div>
        <Skeleton className="h-10 w-full rounded-md" />

        {/* Task list */}
        <div className="flex-1 space-y-2">
          <Skeleton className="h-9 w-full rounded-md" />
          <Skeleton className="h-9 w-full rounded-md" />
          <Skeleton className="h-9 w-3/4 rounded-md" />
        </div>
      </div>

      {/* Main content area */}
      <div className="flex flex-1 flex-col">
        {/* Mobile header */}
        <div className="border-b p-3 md:hidden">
          <div className="flex items-center gap-3">
            <Skeleton className="h-6 w-6" />
            <Skeleton className="h-6 w-32" />
          </div>
        </div>

        {/* Chat area */}
        <div className="relative flex min-h-0 flex-1 flex-col">
          <div className="flex-1" />

          {/* Input area at bottom */}
          <div className="p-4">
            <div className="m-auto w-full max-w-4xl">
              <Skeleton className="h-24 w-full rounded-xl" />
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

function App() {
  const url = use(mariaReadyPromise);
  return (
    <Provider
      store={makeStore({
        home: { ...homeSlice.initialState, cwd },
        url: { url },
      })}
    >
      <MemoryRouter initialEntries={initialEntries} initialIndex={0}>
        <Routes>
          <Route element={<Layout />}>
            <Route index element={<Home />}></Route>
            <Route path="/tasks/:taskId" element={<Task />}></Route>
          </Route>
        </Routes>
      </MemoryRouter>
    </Provider>
  );
}

const root = createRoot(container);
root.render(
  <StrictMode>
    <Suspense fallback={<LoadingFallback />}>
      <App />
    </Suspense>
  </StrictMode>,
);
