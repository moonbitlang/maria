import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import "./index.css";
import Home from "@maria/core/routes/Home.js";
import { Provider } from "react-redux";
import { store } from "@maria/core/app/store.ts";
import { BrowserRouter, Route, Routes } from "react-router";
import { Layout } from "./layout";
import Task from "@maria/core/routes/Task.tsx";

const container = document.getElementById("root")!;

const root = createRoot(container);

root.render(
  <StrictMode>
    <Provider store={store}>
      {
        <BrowserRouter>
          <Routes>
            <Route element={<Layout />}>
              <Route index element={<Home />}></Route>
              <Route path="/tasks/:taskId" element={<Task />}></Route>
            </Route>
          </Routes>
        </BrowserRouter>
      }
    </Provider>
  </StrictMode>,
);
