import { createApi, fetchBaseQuery } from "@reduxjs/toolkit/query/react";
import {
  type DaemonTaskChangeEvent,
  type DaemonTaskSyncEvent,
  type NamedId,
  type TaskEvent,
  type TaskOverview,
  type TodoWriteTool,
} from "@/lib/types";
import {
  setConverstationStatusForTask,
  setTask,
  setTasks,
  updateTodosForTask,
} from "@/features/session/tasksSlice";

const BASE_URL =
  import.meta.env.VITE_API_BASE_URL || "http://localhost:8090/v1";

// Define our single API slice object
export const apiSlice = createApi({
  // The cache reducer expects to be added at `state.api` (already default - this is optional)
  reducerPath: "api",
  baseQuery: fetchBaseQuery({ baseUrl: BASE_URL }),
  tagTypes: ["Tasks"],
  // The "endpoints" represent operations and requests for this server
  endpoints: (builder) => ({
    task: builder.query<{ task: TaskOverview }, string>({
      query: (id) => `task/${id}`,
    }),

    newTask: builder.mutation<{ task: NamedId }, string>({
      query: (content) => ({
        url: "task",
        method: "POST",
        body: JSON.stringify({
          name: content,
          model: "anthropic/claude-sonnet-4.5",
          message: {
            role: "user",
            content,
          },
        }),
      }),
      invalidatesTags: ["Tasks"],
    }),

    postMessage: builder.mutation<void, { taskId: string; content: string }>({
      query: ({ taskId, content }) => ({
        url: `task/${taskId}/message`,
        method: "POST",
        body: JSON.stringify({
          message: {
            role: "user",
            content,
          },
        }),
      }),
    }),

    events: builder.query<undefined, void>({
      queryFn: () => ({ data: undefined }),
      keepUnusedDataFor: 0,
      async onCacheEntryAdded(
        _arg,
        { cacheDataLoaded, cacheEntryRemoved, dispatch },
      ) {
        const source = new EventSource(`${BASE_URL}/events`);
        try {
          await cacheDataLoaded;

          source.addEventListener(
            "daemon.tasks.synchronized",
            (event: MessageEvent<string>) => {
              const { tasks } = JSON.parse(event.data) as DaemonTaskSyncEvent;
              dispatch(setTasks(tasks));
            },
          );

          source.addEventListener(
            "daemon.tasks.changed",
            (event: MessageEvent<string>) => {
              const { task } = JSON.parse(event.data) as DaemonTaskChangeEvent;
              dispatch(setTask(task));
            },
          );
        } catch {
          // noop if cacheEntryRemoved resolves first
        }
        // cacheEntryRemoved will resolve when the cache subscription is no longer active
        await cacheEntryRemoved;
        // perform cleanup steps once the `cacheEntryRemoved` promise resolves
        source.close();
      },
    }),

    taskEvents: builder.query<TaskEvent[], string>({
      queryFn: () => ({ data: [] }),
      keepUnusedDataFor: 0,
      async onCacheEntryAdded(
        id,
        { updateCachedData, cacheDataLoaded, cacheEntryRemoved, dispatch },
      ) {
        // create a sse connection when the cache subscription starts
        const source = new EventSource(`${BASE_URL}/task/${id}/events`);
        try {
          // wait for the initial query to resolve before proceeding
          await cacheDataLoaded;

          source.addEventListener("maria", (event: MessageEvent<string>) => {
            try {
              const data = JSON.parse(event.data) as TaskEvent;
              switch (data.msg) {
                case "RequestCompleted":
                case "PostToolCall":
                case "MessageAdded": {
                  if (
                    data.msg === "PostToolCall" &&
                    data.name === "todo_write"
                  ) {
                    const result = (data as TodoWriteTool).result;
                    dispatch(
                      updateTodosForTask({
                        taskId: id,
                        todos: result.todos,
                      }),
                    );
                  }

                  dispatch(
                    setConverstationStatusForTask({
                      taskId: id,
                      status: "generating",
                    }),
                  );

                  updateCachedData((draft) => {
                    draft.push(data);
                  });

                  return;
                }
                case "PostConversation": {
                  dispatch(
                    setConverstationStatusForTask({
                      taskId: id,
                      status: "idle",
                    }),
                  );
                  return;
                }
                default:
              }
            } catch (e) {
              console.error("Failed to parse SSE event data", e);
            }
          });
        } catch {
          // no-op in case `cacheEntryRemoved` resolves before `cacheDataLoaded`,
          // in which case `cacheDataLoaded` will throw
        }
        // cacheEntryRemoved will resolve when the cache subscription is no longer active
        await cacheEntryRemoved;
        // perform cleanup steps once the `cacheEntryRemoved` promise resolves
        source.close();
      },
    }),
  }),
});

export const {
  useTaskQuery,
  useEventsQuery,
  useTaskEventsQuery,
  useNewTaskMutation,
  usePostMessageMutation,
} = apiSlice;
