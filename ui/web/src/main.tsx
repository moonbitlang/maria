import { store } from "@maria/core/app/store.ts";
import Home from "@maria/core/routes/Home.tsx";
import Task from "@maria/core/routes/Task.tsx";
import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import { Provider } from "react-redux";
import { BrowserRouter, Route, Routes } from "react-router";
import "./index.css";
import { Layout } from "./layout";

const container = document.getElementById("root")!;

const root = createRoot(container);

root.render(
  <StrictMode>
    <Provider store={store}>
      <BrowserRouter>
        <Routes>
          <Route element={<Layout />}>
            <Route index element={<Home />}></Route>
            <Route path="/tasks/:taskId" element={<Task />}></Route>
          </Route>
        </Routes>
      </BrowserRouter>
    </Provider>
  </StrictMode>,
);
