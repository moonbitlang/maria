import { createAppSlice } from "@/app/createAppSlice";
import type { NamedId, Todo } from "@/lib/types";
import type { PayloadAction } from "@reduxjs/toolkit";
import type { ChatStatus } from "ai";

type Task = NamedId & {
  todos: Todo[];
  chatStatus: ChatStatus;
  chatInput: string;
};

export function defaultTask(name: string, id: string): Task {
  return {
    name,
    id,
    todos: [],
    chatStatus: "ready",
    chatInput: "",
  };
}

type TasksSliceState = {
  activeTask: string | undefined;
  tasks: Record<string, Task>;
};

const initialState: TasksSliceState = {
  activeTask: undefined,
  tasks: {},
};

export const tasksSlice = createAppSlice({
  name: "tasks",
  initialState,
  selectors: {
    selectTask(state: TasksSliceState, taskId: string): Task | undefined {
      return state.tasks[taskId];
    },

    selectActiveTaskId(state: TasksSliceState): string | undefined {
      return state.activeTask;
    },

    selectTaskInput(
      state: TasksSliceState,
      taskId: string,
    ): string | undefined {
      const task = state.tasks[taskId];
      return task?.chatInput;
    },

    selectTaskChatStatus(
      state: TasksSliceState,
      taskId: string,
    ): ChatStatus | undefined {
      const task = state.tasks[taskId];
      return task?.chatStatus;
    },
  },
  reducers: {
    setActiveTaskId(state, action: PayloadAction<string | undefined>) {
      state.activeTask = action.payload;
    },

    newTask(state, action: PayloadAction<NamedId>) {
      const { id, name } = action.payload;
      if (!state.tasks[id]) {
        state.tasks[id] = defaultTask(name, id);
      }
    },

    setTasks(state, action: PayloadAction<NamedId[]>) {
      for (const { id, name } of action.payload) {
        if (!state.tasks[id]) {
          state.tasks[id] = defaultTask(name, id);
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

    setInputForTask(
      state,
      action: PayloadAction<{ taskId: string; input: string }>,
    ) {
      const { taskId, input } = action.payload;
      const task = state.tasks[taskId];
      if (task) {
        task.chatInput = input;
      }
    },
  },
});

export const {
  newTask,
  setTasks,
  setChatStatusForTask,
  updateTodosForTask,
  setActiveTaskId,
  setInputForTask,
} = tasksSlice.actions;

export const {
  selectTask,
  selectActiveTaskId,
  selectTaskInput,
  selectTaskChatStatus,
} = tasksSlice.selectors;
