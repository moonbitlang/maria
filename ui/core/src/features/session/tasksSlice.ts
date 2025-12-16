import type {
  PostToolCallEvent,
  Status,
  TaskEvent,
  TaskOverview,
  Todo,
  TodoTool,
} from "@maria/core/lib/types.ts";
import { type PayloadAction, createSelector } from "@reduxjs/toolkit";
import { createAppSlice } from "../../app/createAppSlice";
import type { RootState } from "../../app/store";

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
  webSearchEnabled: boolean;
};

export function defaultTask(params: TaskOverview): Task {
  return {
    todos: [],
    chatInput: "",
    inputQueue: [],
    events: [],
    eventIds: {},
    webSearchEnabled: false,
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

    setStatusForTask(
      state,
      action: PayloadAction<{ taskId: string; status: Status }>,
    ) {
      const { taskId, status } = action.payload;
      const task = state.tasks[taskId];
      if (task) {
        task.status = status;
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

    toggleWebSearchForTask(state, action: PayloadAction<{ taskId: string }>) {
      const { taskId } = action.payload;
      const task = state.tasks[taskId];
      if (task) {
        task.webSearchEnabled = !task.webSearchEnabled;
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

        if (event.desc.msg === "PostToolCall") {
          // We need to extract event.desc to a variable so that TypeScript can
          // narrow the type properly
          const desc: PostToolCallEvent = event.desc;
          // We need to test for the "result" field specifically for the
          // "todo" tool because the tool might fail and return an "error" field
          // instead.
          if (desc.name === "todo" && desc.result) {
            // Because `PostToolCallEvent` is a union type that includes
            // `UnknownTool`, and TypeScript always infers the type of
            // `desc` as (TodoTool | UnknownTool). So we need to use type
            // assertion here.
            const todoTool = desc as PostToolCallEvent & TodoTool;
            task.todos = todoTool.result[1].todos;
          }
          // search back for the respective PreToolCall event and change it to PostToolCall
          const toolCallId = desc.tool_call.id;
          let found = false;
          for (let i = task.events.length - 1; i >= 0; i--) {
            const e = task.events[i];
            if (
              e.desc.msg === "PreToolCall" &&
              e.desc.tool_call.id === toolCallId
            ) {
              // replace the PreToolCall event with PostToolCall event
              found = true;
              task.events[i] = event;
              task.eventIds[event.id] = true;
              break;
            }
          }
          if (!found) {
            task.events.push(event);
            task.eventIds[event.id] = true;
          }
        } else {
          task.events.push(event);
          task.eventIds[event.id] = true;
        }
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

    selectTaskCwd(state: TasksSliceState, taskId: string): string | undefined {
      return state.tasks[taskId]?.cwd;
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

    selectWebSearchEnabledForTask(
      state: TasksSliceState,
      taskId: string,
    ): boolean | undefined {
      return state.tasks[taskId]?.webSearchEnabled;
    },
  },
});

export const {
  setTask,
  setTasks,
  setActiveTaskId,
  setInputForTask,
  setStatusForTask,
  addToInputQueueForTask,
  removeFromInputQueueForTask,
  pushEventForTask,
  toggleWebSearchForTask,
} = tasksSlice.actions;

export const {
  selectTask,
  selectActiveTaskId,
  selectTaskInput,
  selectConversationStatus,
  selectInputQueue,
  selectTaskEvents,
  selectTaskTodos,
  selectTaskCwd,
  selectWebSearchEnabledForTask,
} = tasksSlice.selectors;

// Memoized selector to prevent unnecessary re-renders
export const selectTasks = createSelector(
  [(state: RootState) => state.tasks.tasks],
  (tasks) => Object.values(tasks).sort((a, b) => b.created - a.created),
);
