import { createApi, fetchBaseQuery } from "@reduxjs/toolkit/query/react";
import type {
  BaseQueryFn,
  FetchArgs,
  FetchBaseQueryError,
} from "@reduxjs/toolkit/query";
import {
  type DaemonTaskChangeEvent,
  type DaemonTaskSyncEvent,
  type NamedId,
  type TaskEvent,
  type TaskOverview,
} from "@/lib/types";
import {
  pushEventForTask,
  removeFromInputQueueForTask,
  setTask,
  setTasks,
} from "@/features/session/tasksSlice";
import { selectApiBaseUrl } from "@/features/config/configSlice";
import type { RootState } from "@/app/store";

const dynamicBaseQuery: BaseQueryFn<
  string | FetchArgs,
  unknown,
  FetchBaseQueryError
> = async (args, api, extraOptions) => {
  const baseUrl = selectApiBaseUrl(api.getState() as RootState);
  const rawBaseQuery = fetchBaseQuery({ baseUrl });
  return rawBaseQuery(args, api, extraOptions);
};

// Define our single API slice object
export const apiSlice = createApi({
  // The cache reducer expects to be added at `state.api` (already default - this is optional)
  reducerPath: "api",
  baseQuery: dynamicBaseQuery,
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
        { cacheDataLoaded, cacheEntryRemoved, dispatch, getState },
      ) {
        const baseUrl = selectApiBaseUrl(getState() as RootState);
        const source = new EventSource(`${baseUrl}/events`);
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
        { cacheDataLoaded, cacheEntryRemoved, dispatch, getState },
      ) {
        // create a sse connection when the cache subscription starts
        const baseUrl = selectApiBaseUrl(getState() as RootState);
        const source = new EventSource(`${baseUrl}/task/${id}/events`);
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
