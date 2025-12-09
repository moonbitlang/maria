import { makeStore } from "@maria/core/app/store.js";
import { Skeleton } from "@maria/core/components/ui/skeleton.tsx";
import Home from "@maria/core/routes/Home.tsx";
import Task from "@maria/core/routes/Task.tsx";
import { StrictMode, Suspense, use, useEffect, useState } from "react";
import { createRoot } from "react-dom/client";
import { Provider } from "react-redux";
import { MemoryRouter, Route, Routes } from "react-router";
import "./index.css";
import { Layout } from "./layout";
import { install } from "./ril";

const mariaReadyPromise = (async () => {
  await window.electronAPI.mariaReady();
  return await window.electronAPI.getUrl();
})();

function App() {
  const url = use(mariaReadyPromise);

  return (
    <Provider store={makeStore({ url: { url } })}>
      <MemoryRouter initialEntries={["/"]}>
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

install();
const container = document.getElementById("root")!;

const root = createRoot(container);

root.render(
  <StrictMode>
    <Suspense fallback={<LoadingFallback />}>
      <App />
    </Suspense>
  </StrictMode>,
);
