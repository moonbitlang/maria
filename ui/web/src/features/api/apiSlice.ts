import { createApi, fetchBaseQuery } from "@reduxjs/toolkit/query/react";
import {
  type DaemonTaskChangeEvent,
  type DaemonTaskSyncEvent,
  type TaskEvent,
  type TaskOverview,
} from "@/lib/types";
import {
  pushEventForTask,
  removeFromInputQueueForTask,
  setTask,
  setTasks,
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
      async onQueryStarted(_arg, { queryFulfilled, dispatch }) {
        const res = await queryFulfilled;
        const task = res.data.task;
        dispatch(setTask(task));
      },
    }),

    newTask: builder.mutation<
      { task: TaskOverview },
      { message: string; cwd?: string }
    >({
      query: (params) => {
        const { message, cwd } = params;
        return {
          url: "task",
          method: "POST",
          body: JSON.stringify({
            name: message,
            model: "anthropic/claude-sonnet-4.5",
            message: {
              role: "user",
              content: message,
            },
            cwd,
          }),
        };
      },
      invalidatesTags: ["Tasks"],
    }),

    postMessage: builder.mutation<
      { id: string; queued: boolean },
      { taskId: string; content: string }
    >({
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
            "daemon.task.changed",
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

    taskEvents: builder.query<undefined, string>({
      queryFn: () => ({ data: undefined }),
      keepUnusedDataFor: 0,
      async onCacheEntryAdded(
        id,
        { cacheDataLoaded, cacheEntryRemoved, dispatch },
      ) {
        // create a sse connection when the cache subscription starts
        const source = new EventSource(`${BASE_URL}/task/${id}/events`);
        try {
          // wait for the initial query to resolve before proceeding
          await cacheDataLoaded;

          source.addEventListener("maria", (event: MessageEvent<string>) => {
            const data = JSON.parse(event.data) as TaskEvent;
            switch (data.msg) {
              case "RequestCompleted":
              case "PostToolCall":
              case "MessageAdded": {
                dispatch(pushEventForTask({ taskId: id, event: data }));

                return;
              }
              case "MessageUnqueued": {
                dispatch(
                  removeFromInputQueueForTask({
                    taskId: id,
                    id: data.message.id,
                  }),
                );
                return;
              }
              default:
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
