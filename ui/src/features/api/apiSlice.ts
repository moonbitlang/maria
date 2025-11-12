import { createApi, fetchBaseQuery } from "@reduxjs/toolkit/query/react";
import type { SessionEvent } from "@/features/session/sessionSlice";

const BASE_URL = "http://localhost:3001/v1";

// Define our single API slice object
export const apiSlice = createApi({
  // The cache reducer expects to be added at `state.api` (already default - this is optional)
  reducerPath: "api",
  baseQuery: fetchBaseQuery({ baseUrl: BASE_URL }),
  // The "endpoints" represent operations and requests for this server
  endpoints: (builder) => ({
    postMessage: builder.mutation<void, string>({
      query: (message) => ({
        url: "message",
        method: "POST",
        body: JSON.stringify({
          role: "user",
          message,
        }),
      }),
    }),

    getEvents: builder.query<SessionEvent[], void>({
      queryFn: () => ({ data: [] }),
      async onCacheEntryAdded(
        _arg,
        { updateCachedData, cacheDataLoaded, cacheEntryRemoved },
      ) {
        // create a sse connection when the cache subscription starts
        const source = new EventSource(`${BASE_URL}/events`);
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

export const { usePostMessageMutation, useGetEventsQuery } = apiSlice;
