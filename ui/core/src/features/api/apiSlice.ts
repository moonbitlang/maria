import {
  type DaemonTaskChangeEvent,
  type DaemonTaskSyncEvent,
  type TaskEvent,
  type TaskOverview,
} from "@maria/core/lib/types.ts";
import {
  createApi,
  fetchBaseQuery,
  type BaseQueryFn,
  type FetchArgs,
  type FetchBaseQueryError,
} from "@reduxjs/toolkit/query/react";
import type { RootState } from "../../app/store";
import {
  pushEventForTask,
  removeFromInputQueueForTask,
  setTask,
  setTasks,
} from "../session/tasksSlice";
import { selectUrl } from "../session/urlSlice";

const rawBaseQuery = fetchBaseQuery();

const dynamicBaseQuery: BaseQueryFn<
  string | FetchArgs,
  unknown,
  FetchBaseQueryError
> = async (args, api, extraOptions) => {
  const url = selectUrl(api.getState() as RootState);
  const urlEnd = typeof args === "string" ? args : args.url;
  // construct a dynamically generated portion of the url
  const adjustedUrl = `${url}/${urlEnd}`;
  const adjustedArgs =
    typeof args === "string" ? adjustedUrl : { ...args, url: adjustedUrl };
  // provide the amended url and other params to the raw base query
  return rawBaseQuery(adjustedArgs, api, extraOptions);
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

    newTask: builder.mutation<
      { task: TaskOverview },
      { message: string; cwd?: string; web_search: boolean }
    >({
      query: (params) => {
        const { message, cwd, web_search } = params;
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
            web_search,
          }),
        };
      },
      invalidatesTags: ["Tasks"],
    }),

    postMessage: builder.mutation<
      { id: string; queued: boolean },
      { taskId: string; content: string; web_search: boolean }
    >({
      query: ({ taskId, content, web_search }) => ({
        url: `task/${taskId}/message`,
        method: "POST",
        body: JSON.stringify({
          message: {
            role: "user",
            content,
          },
          web_search,
        }),
      }),
    }),

    postCancel: builder.mutation<null, { taskId: string }>({
      query: ({ taskId }) => ({
        url: `task/${taskId}/cancel`,
        method: "POST",
      }),
    }),

    events: builder.query<undefined, void>({
      queryFn: () => ({ data: undefined }),
      keepUnusedDataFor: 0,
      async onCacheEntryAdded(
        _arg,
        { cacheDataLoaded, cacheEntryRemoved, dispatch, getState },
      ) {
        const BASE_URL = selectUrl(getState() as RootState);
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
        { cacheDataLoaded, cacheEntryRemoved, dispatch, getState },
      ) {
        const BASE_URL = selectUrl(getState() as RootState);
        // create a sse connection when the cache subscription starts
        const source = new EventSource(`${BASE_URL}/task/${id}/events`);
        try {
          // wait for the initial query to resolve before proceeding
          await cacheDataLoaded;

          source.addEventListener("maria", (event: MessageEvent<string>) => {
            const data = JSON.parse(event.data) as TaskEvent;
            switch (data.msg) {
              case "RequestCompleted":
              case "PreToolCall":
              case "PostToolCall":
              case "TodoUpdated":
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
  usePostCancelMutation,
} = apiSlice;
