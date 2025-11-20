import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import "./index.css";
import Home from "./routes/Home";
import { Provider } from "react-redux";
import { store } from "./app/store";
import { BrowserRouter, MemoryRouter, Route, Routes } from "react-router";
import { Layout } from "./components/layout";
import Task from "./routes/Task";
import VscodeLayout from "./components/vscode-layout";

const isInVscode = typeof acquireVsCodeApi === "function";

if (isInVscode) {
  document.getElementById("_defaultStyles")?.remove();
}

const container = document.getElementById("root")!;
const root = createRoot(container);

root.render(
  <StrictMode>
    <Provider store={store}>
      {isInVscode ? (
        <MemoryRouter initialEntries={["/"]} initialIndex={0}>
          <Routes>
            <Route element={<VscodeLayout />}>
              <Route index element={<Home />}></Route>
              <Route path="tasks/:taskId" element={<Task />}></Route>
            </Route>
          </Routes>
        </MemoryRouter>
      ) : (
        <BrowserRouter>
          <Routes>
            <Route element={<Layout />}>
              <Route index element={<Home />}></Route>
              <Route path="tasks/:taskId" element={<Task />}></Route>
            </Route>
          </Routes>
        </BrowserRouter>
      )}
    </Provider>
  </StrictMode>,
);
