import { createAppSlice } from "@/app/createAppSlice";
import type { NamedId, Todo } from "@/lib/types";
import type { PayloadAction } from "@reduxjs/toolkit";
import type { ChatStatus } from "ai";

type Task = NamedId & {
  todos: Todo[];
  chatStatus: ChatStatus;
};

type TasksSliceState = {
  activeTask: string | null;
  tasks: Record<string, Task>;
};

const initialState: TasksSliceState = {
  activeTask: null,
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
    newTask(state, action: PayloadAction<NamedId>) {
      const { id, name } = action.payload;
      if (!state.tasks[id]) {
        state.tasks[id] = {
          id,
          name,
          todos: [],
          chatStatus: "ready",
        };
      }
    },

    setTasks(state, action: PayloadAction<NamedId[]>) {
      for (const { id, name } of action.payload) {
        if (!state.tasks[id]) {
          state.tasks[id] = {
            id,
            name,
            todos: [],
            chatStatus: "ready",
          };
        }
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

export const { newTask, setTasks, setChatStatusForTask, updateTodosForTask } =
  tasksSlice.actions;

export const { selectTask } = tasksSlice.selectors;
