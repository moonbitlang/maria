import { createAppSlice } from "@/app/createAppSlice";
import type { TaskEvent, TaskSliceState, Todo } from "./taskSlice";
import type { PayloadAction } from "@reduxjs/toolkit";
import type { ChatStatus } from "ai";
type TasksSliceState = {
  tasks: Record<string, TaskSliceState>;
};

const initialState: TasksSliceState = {
  tasks: {},
};

export const tasksSlice = createAppSlice({
  name: "tasks",
  initialState,
  selectors: {
    selectTask(state: TasksSliceState, taskId: string) {
      return state.tasks[taskId];
    },
  },
  reducers: {
    addEventToTask(
      state,
      action: PayloadAction<{ taskId: string; event: TaskEvent }>,
    ) {
      const { taskId, event } = action.payload;
      const task = state.tasks[taskId];
      if (task) {
        task.events.push(event);
      }
    },

    updateTodosForTask(
      state,
      action: PayloadAction<{ taskId: string; todos: Todo[] }>,
    ) {
      const { taskId, todos } = action.payload;
      const task = state.tasks[taskId];
      if (task) {
        task.todos = todos;
      }
    },

    setChatStatusForTask(
      state,
      action: PayloadAction<{ taskId: string; status: ChatStatus }>,
    ) {
      const { taskId, status } = action.payload;
      const task = state.tasks[taskId];
      if (task) {
        task.chatStatus = status;
      }
    },
  },
});

export const { addEventToTask, setChatStatusForTask, updateTodosForTask } =
  tasksSlice.actions;

export const { selectTask } = tasksSlice.selectors;
