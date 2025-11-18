import { createAppSlice } from "@/app/createAppSlice";
import type { RootState } from "@/app/store";
import type { ConversationStatus, NamedId, Todo } from "@/lib/types";
import { type PayloadAction, createSelector } from "@reduxjs/toolkit";

// LocalStorage key for persisting input queues
const INPUT_QUEUE_STORAGE_KEY = "maria_input_queues";

// Helper functions for localStorage persistence
function saveInputQueue(taskId: string, inputQueue: string[]) {
  try {
    const stored = localStorage.getItem(INPUT_QUEUE_STORAGE_KEY);
    const queues = stored ? JSON.parse(stored) : {};
    queues[taskId] = inputQueue;
    localStorage.setItem(INPUT_QUEUE_STORAGE_KEY, JSON.stringify(queues));
  } catch (error) {
    console.error("Failed to save input queue to localStorage:", error);
  }
}

function loadInputQueue(taskId: string): string[] {
  try {
    const stored = localStorage.getItem(INPUT_QUEUE_STORAGE_KEY);
    if (stored) {
      const queues = JSON.parse(stored);
      return queues[taskId] || [];
    }
  } catch (error) {
    console.error("Failed to load input queue from localStorage:", error);
  }
  return [];
}

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
    todos: [],
    chatInput: "",
    conversationStatus: "idle",
    inputQueue: [],
    ...params,
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
        const inputQueue = loadInputQueue(id);
        state.tasks[id] = defaultTask({ name, id, inputQueue });
      }
    },

    setTasks(state, action: PayloadAction<NamedId[]>) {
      for (const t of action.payload) {
        if (!state.tasks[t.id]) {
          const inputQueue = loadInputQueue(t.id);
          state.tasks[t.id] = defaultTask({ ...t, inputQueue });
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
        saveInputQueue(taskId, task.inputQueue);
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
        saveInputQueue(taskId, task.inputQueue);
      }
    },
  },

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
} = tasksSlice.selectors;

// Memoized selector to prevent unnecessary re-renders
export const selectTasks = createSelector(
  [(state: RootState) => state.tasks.tasks],
  (tasks) => Object.values(tasks),
);
