import type { PayloadAction } from "@reduxjs/toolkit";
import { createAppSlice } from "@/app/createAppSlice";

export type SessionEvent =
  | RequestCompletedEvent
  | PostToolCallEvent
  | MessageAddedEvent;

type ToolCallFunction = {
  name: string;
  arguments: string;
};

type ToolCall = {
  id: string;
  function: ToolCallFunction;
};

type RequestCompletedEvent = {
  msg: "RequestCompleted";
  message: {
    content: string;
    role: "assistant";
    tool_calls: ToolCall[];
  };
};

type ExecuteCommandTool = {
  name: "execute_command";
  result?: ["Completed", { command: string; status: number }];
  error?: unknown;
};

type ListFilesTool = {
  name: "list_files;";
  result?: { path: string };
  error?: unknown;
};

type ReadFileTool = {
  name: "read_file";
  result?: ["ReadFileResult", { path: string }];
  error?: unknown;
};

type replaceInFileTool = {
  name: "replace_in_file";
  result?: { path: string };
  error?: unknown;
};

type metaWriteToFileTool = {
  name: "meta_write_to_file";
  result?: { path: string };
  error?: unknown;
};

type UnknownTool = {
  name: string;
  result?: unknown;
  error?: unknown;
};

type PostToolCallBase = {
  msg: "PostToolCall";
  tool_call: ToolCall;
  text: string;
};

type PostToolCallEvent = PostToolCallBase &
  (
    | ExecuteCommandTool
    | ListFilesTool
    | ReadFileTool
    | replaceInFileTool
    | metaWriteToFileTool
    | UnknownTool
  );

type MessageContentPart = {
  text: string;
};

type SystemMessage = {
  role: "system";
  content: MessageContentPart[];
};

type UserMessage = {
  role: "user";
  content: MessageContentPart[];
};

type AssistantMessage = {
  role: "assistant";
  content: MessageContentPart[];
  tool_calls: ToolCall[];
};

type ToolMessage = {
  role: "tool";
  tool_call_id: string;
  content: MessageContentPart[];
};

type MessageAddedEvent = {
  msg: "MessageAdded";
  message: SystemMessage | UserMessage | AssistantMessage | ToolMessage;
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
