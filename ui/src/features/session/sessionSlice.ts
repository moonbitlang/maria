import type { PayloadAction } from "@reduxjs/toolkit";
import { createAppSlice } from "@/app/createAppSlice";

export type SessionEvent =
  | RequestCompletedEvent
  | PostToolCallEvent
  | MessageAddedEvent;

type RequestCompletedEvent = {
  msg: "RequestCompleted";
  message: {
    content: string;
    role: string;
    tool_calls: {
      id: string;
      function: {
        name: string;
        arguments: string;
      };
    }[];
  };
};

type PostToolCallEvent = {
  msg: "PostToolCall";
  tool_call: {
    id: string;
    function: {
      name: string;
      arguments: string;
    };
  };
  name: string;
  text: string;
  result?: unknown;
  error?: unknown;
};

type MessageContent = {
  text: string;
};

type MessageAddedEvent = {
  msg: "MessageAdded";
  message: {
    role: string;
    content: MessageContent[];
  };
};

export type SessionSliceState = {
  events: SessionEvent[];
};

const initialState: SessionSliceState = {
  events: [],
};

export const sessionSlice = createAppSlice({
  name: "session",
  initialState,
  reducers: {
    addEvent(state, action: PayloadAction<SessionEvent>) {
      state.events.push(action.payload);
    },
  },
  selectors: {
    selectEvents: (state) => state.events,
  },
});

export const { addEvent } = sessionSlice.actions;
export const { selectEvents } = sessionSlice.selectors;
