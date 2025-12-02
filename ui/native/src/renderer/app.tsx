import { store } from "@maria/core/app/store.ts";
import Task from "@maria/core/routes/Task.tsx";
import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import { Provider } from "react-redux";
import { MemoryRouter, Route, Routes } from "react-router";
import Home from "./Home";
import "./index.css";
import { Layout } from "./layout";

const container = document.getElementById("root")!;

const root = createRoot(container);

root.render(
  <StrictMode>
    <Provider store={store}>
      <MemoryRouter initialEntries={["/"]}>
        <Routes>
          <Route element={<Layout />}>
            <Route index element={<Home />}></Route>
            <Route path="/tasks/:taskId" element={<Task />}></Route>
          </Route>
        </Routes>
      </MemoryRouter>
    </Provider>
  </StrictMode>,
);
