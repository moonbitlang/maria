import { createApi, fetchBaseQuery } from "@reduxjs/toolkit/query/react";
import { type SessionEvent } from "@/features/session/sessionSlice";

const BASE_URL = import.meta.env.API_BASE_URL || "http://localhost:8090/v1";

export type Task = {
  name: string;
  id: string;
};

// Define our single API slice object
export const apiSlice = createApi({
  // The cache reducer expects to be added at `state.api` (already default - this is optional)
  reducerPath: "api",
  baseQuery: fetchBaseQuery({ baseUrl: BASE_URL }),
  // The "endpoints" represent operations and requests for this server
  endpoints: (builder) => ({
    tasks: builder.query<{ tasks: Task[] }, void>({
      query: () => "tasks",
    }),

    newTask: builder.mutation<{ task: Task }, string>({
      query: (content) => ({
        url: "task",
        method: "POST",
        body: JSON.stringify({
          model: "anthropic/claude-sonnet-4",
          message: {
            role: "user",
            content,
          },
        }),
      }),
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

    events: builder.query<SessionEvent[], string>({
      queryFn: () => ({ data: [] }),
      async onCacheEntryAdded(
        id,
        { updateCachedData, cacheDataLoaded, cacheEntryRemoved },
      ) {
        // create a sse connection when the cache subscription starts
        const source = new EventSource(`${BASE_URL}/task/${id}/events`);
        try {
          // wait for the initial query to resolve before proceeding
          await cacheDataLoaded;

          source.addEventListener("maria", (event: MessageEvent<string>) => {
            try {
              const data = JSON.parse(event.data);
              if (typeof data === "object" && data !== null && "msg" in data) {
                switch (data.msg) {
                  case "RequestCompleted":
                  case "PostToolCall":
                  case "MessageAdded": {
                    updateCachedData((draft) => {
                      draft.push(data);
                    });
                    return;
                  }
                  default:
                }
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
  useTasksQuery,
  useEventsQuery,
  useNewTaskMutation,
  usePostMessageMutation,
} = apiSlice;
