import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import { Provider } from "react-redux";
import { store } from "@maria/core/app/store.ts";
import { MemoryRouter, Route, Routes } from "react-router";
import Layout from "./layout";
import "./index.css";
import { rootData } from "./utils";
import Task from "@maria/core/routes/Task.tsx";
import AllTasks from "./AllTasks";
import Home from "@maria/core/routes/Home.tsx";

const taskId = rootData("task-id");
const cwd = rootData("cwd");

let initialEntries = ["/"];

if (taskId) {
  initialEntries = [`/tasks/${taskId}`];
}

document.getElementById("_defaultStyles")?.remove();

const container = document.getElementById("root")!;

const root = createRoot(container);

root.render(
  <StrictMode>
    <Provider store={store}>
      <MemoryRouter initialEntries={initialEntries} initialIndex={0}>
        <Routes>
          <Route element={<Layout />}>
            <Route index element={<Home cwd={cwd} />}></Route>
            <Route path="/tasks/:taskId" element={<Task />}></Route>
            <Route path="/all-tasks" element={<AllTasks />}></Route>
          </Route>
        </Routes>
      </MemoryRouter>
    </Provider>
  </StrictMode>,
);
