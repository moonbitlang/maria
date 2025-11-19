import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import "./index.css";
import Home from "./routes/Home";
import { Provider } from "react-redux";
import { store } from "./app/store";
import { BrowserRouter, MemoryRouter, Route, Routes } from "react-router";
import { Layout } from "./components/layout";
import Task from "./routes/Task";

declare global {
  function acquireVsCodeApi(): void;
}

const isInVscode = typeof acquireVsCodeApi === "function";

if (isInVscode) {
  document.getElementById("_defaultStyles")?.remove();
}

const container = document.getElementById("root")!;
const root = createRoot(container);

const routes = (
  <Routes>
    <Route element={<Layout />}>
      <Route index element={<Home />}></Route>
      <Route path="tasks/:taskId" element={<Task />}></Route>
    </Route>
  </Routes>
);

root.render(
  <StrictMode>
    <Provider store={store}>
      {isInVscode ? (
        <MemoryRouter initialEntries={["/"]} initialIndex={0}>
          {routes}
        </MemoryRouter>
      ) : (
        <BrowserRouter>{routes}</BrowserRouter>
      )}
    </Provider>
  </StrictMode>,
);
