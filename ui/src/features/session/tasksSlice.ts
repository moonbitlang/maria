import { createAppSlice } from "@/app/createAppSlice";
import type { ConversationStatus, NamedId, Todo } from "@/lib/types";
import type { PayloadAction } from "@reduxjs/toolkit";

type Task = NamedId & {
  todos: Todo[];
  chatInput: string;
  conversationStatus: ConversationStatus;
  inputQueue: string[];
};

export function defaultTask(
  params: NamedId & Partial<Omit<Task, "name" | "id">>,
): Task {
  return {
    name: params.name,
    id: params.id,
    todos: params.todos ?? [],
    chatInput: params.chatInput ?? "",
    conversationStatus: params.conversationStatus ?? "idle",
    inputQueue: params.inputQueue ?? [],
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
  reducers: {
    setActiveTaskId(state, action: PayloadAction<string | undefined>) {
      state.activeTask = action.payload;
    },

    newTask(state, action: PayloadAction<NamedId>) {
      const { id, name } = action.payload;
      if (!state.tasks[id]) {
        state.tasks[id] = defaultTask({ name, id });
      }
    },

    setTasks(state, action: PayloadAction<NamedId[]>) {
      for (const t of action.payload) {
        if (!state.tasks[t.id]) {
          state.tasks[t.id] = defaultTask(t);
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

    setConverstationStatusForTask(
      state,
      action: PayloadAction<{
        taskId: string;
        status: ConversationStatus;
      }>,
    ) {
      const { taskId, status } = action.payload;
      const task = state.tasks[taskId];
      if (task) {
        task.conversationStatus = status;
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

    addToInputQueueForTask(
      state,
      action: PayloadAction<{ taskId: string; input: string }>,
    ) {
      const { taskId, input } = action.payload;
      const task = state.tasks[taskId];
      if (task) {
        task.inputQueue.push(input);
      }
    },

    removeNthFromInputQueueForTask(
      state,
      action: PayloadAction<{ taskId: string; n: number }>,
    ) {
      const { taskId, n } = action.payload;
      const task = state.tasks[taskId];
      if (task) {
        task.inputQueue.splice(n, 1);
      }
    },
  },

  selectors: {
    selectTasks(state: TasksSliceState): Task[] {
      return Object.values(state.tasks);
    },

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

    selectConversationStatus(
      state: TasksSliceState,
      taskId: string,
    ): ConversationStatus | undefined {
      const task = state.tasks[taskId];
      return task?.conversationStatus;
    },

    selectInputQueue(
      state: TasksSliceState,
      taskId: string,
    ): string[] | undefined {
      const task = state.tasks[taskId];
      return task?.inputQueue;
    },
  },
});

export const {
  newTask,
  setTasks,
  updateTodosForTask,
  setActiveTaskId,
  setInputForTask,
  setConverstationStatusForTask,
  addToInputQueueForTask,
  removeNthFromInputQueueForTask,
} = tasksSlice.actions;

export const {
  selectTask,
  selectActiveTaskId,
  selectTaskInput,
  selectConversationStatus,
  selectInputQueue,
  selectTasks,
} = tasksSlice.selectors;
