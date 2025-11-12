import { createApi, fetchBaseQuery } from "@reduxjs/toolkit/query/react";

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
  }),
});

export const { usePostMessageMutation } = apiSlice;
