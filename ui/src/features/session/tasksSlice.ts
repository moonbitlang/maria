import { createAppSlice } from "@/app/createAppSlice";
import type { RootState } from "@/app/store";
import type {
  Status,
  NamedId,
  TaskOverview,
  Todo,
  TaskEvent,
} from "@/lib/types";
import { type PayloadAction, createSelector } from "@reduxjs/toolkit";

type QueuedMessage = {
  id: string;
  content: string;
};

type Task = TaskOverview & {
  todos: Todo[];
  chatInput: string;
  inputQueue: QueuedMessage[];
  events: TaskEvent[];
  eventIds: Record<number, true>;
};

export function defaultTask(
  params: NamedId & Partial<Omit<Task, "name" | "id">>,
): Task {
  return {
    todos: [],
    chatInput: "",
    status: "idle",
    inputQueue: [],
    events: [],
    eventIds: {},
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
        state.tasks[id] = defaultTask({
          name,
          id,
          status: "generating",
        });
      }
    },

    setTask(state, action: PayloadAction<TaskOverview>) {
      const t = action.payload;
      const task = state.tasks[t.id];
      if (task) {
        task.name = t.name;
        task.status = t.status;
      } else {
        state.tasks[t.id] = defaultTask(t);
      }
    },

    setTasks(state, action: PayloadAction<TaskOverview[]>) {
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
      action: PayloadAction<{ taskId: string; message: QueuedMessage }>,
    ) {
      const { taskId, message } = action.payload;
      const task = state.tasks[taskId];
      if (task) {
        task.inputQueue.push(message);
      }
    },

    removeFromInputQueueForTask(
      state,
      action: PayloadAction<{ taskId: string; id: string }>,
    ) {
      const { taskId, id } = action.payload;
      const task = state.tasks[taskId];
      if (task) {
        task.inputQueue = task.inputQueue.filter(
          (message) => message.id !== id,
        );
      }
    },

    pushEventForTask(
      state,
      action: PayloadAction<{ taskId: string; event: TaskEvent }>,
    ) {
      const { taskId, event } = action.payload;
      const task = state.tasks[taskId];
      if (task) {
        if (task.eventIds[event.id]) {
          return;
        }
        task.events.push(event);
        task.eventIds[event.id] = true;
      }
    },
  },

  selectors: {
    selectTask(state: TasksSliceState, taskId: string): Task | undefined {
      return state.tasks[taskId];
    },

    selectTaskEvents(
      state: TasksSliceState,
      taskId: string,
    ): TaskEvent[] | undefined {
      return state.tasks[taskId]?.events;
    },

    selectActiveTaskId(state: TasksSliceState): string | undefined {
      return state.activeTask;
    },

    selectTaskTodos(
      state: TasksSliceState,
      taskId: string,
    ): Todo[] | undefined {
      return state.tasks[taskId]?.todos;
    },

    selectTaskInput(
      state: TasksSliceState,
      taskId: string,
    ): string | undefined {
      return state.tasks[taskId]?.chatInput;
    },

    selectConversationStatus(
      state: TasksSliceState,
      taskId: string,
    ): Status | undefined {
      return state.tasks[taskId]?.status;
    },

    selectInputQueue(
      state: TasksSliceState,
      taskId: string,
    ): QueuedMessage[] | undefined {
      const task = state.tasks[taskId];
      return task?.inputQueue;
    },
  },
});

export const {
  newTask,
  setTask,
  setTasks,
  updateTodosForTask,
  setActiveTaskId,
  setInputForTask,
  addToInputQueueForTask,
  removeFromInputQueueForTask,
  pushEventForTask,
} = tasksSlice.actions;

export const {
  selectTask,
  selectActiveTaskId,
  selectTaskInput,
  selectConversationStatus,
  selectInputQueue,
  selectTaskEvents,
  selectTaskTodos,
} = tasksSlice.selectors;

// Memoized selector to prevent unnecessary re-renders
export const selectTasks = createSelector(
  [(state: RootState) => state.tasks.tasks],
  (tasks) => Object.values(tasks),
);
