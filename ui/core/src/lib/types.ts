import type * as comlink from "comlink";
import type { OpenDialogReturnValue } from "electron";

export type QueuedMessage = {
  id: string;
  content: string;
};

export type Task = TaskOverview & {
  todos: Todo[];
  chatInput: string;
  inputQueue: QueuedMessage[];
  events: TaskEvent[];
  eventIds: Record<number, true>;
};

export type Status = "idle" | "generating";

export type TaskOverview = {
  id: string;
  name: string;
  status: Status;
  created: number;
  cwd: string;
};

type TaskEventBase = {
  id: number;
};

export type TaskEvent = TaskEventBase &
  (
    | RequestCompletedEvent
    | PreToolCallEvent
    | PostToolCallEvent
    | MessageAddedEvent
    | PostConversationEvent
    | MessageUnqueuedEvent
    | TodoUpdatedEvent
  );

type TodoUpdatedEvent = {
  msg: "TodoUpdated";
  todo: {
    todos: Todo[];
    created_at: string;
    updated_at: string;
  };
};

type MessageUnqueuedEvent = {
  msg: "MessageUnqueued";
  message: { id: string };
};

type PostConversationEvent = {
  msg: "PostConversation";
};

type ToolCallFunction = {
  name: string;
  arguments: string;
};

type ToolCall = {
  id: string;
  function: ToolCallFunction;
};

export type RequestCompletedEvent = {
  msg: "RequestCompleted";
  message: {
    content: string;
    role: "assistant";
    tool_calls: ToolCall[];
  };
};

export type ExecuteCommandTool = {
  name: "execute_command";
  result: [
    "Completed",
    {
      command: string;
      status: number;
      stdout: string;
      stderr: string;
      max_output_lines: number;
    },
  ];
  error?: unknown;
};

export type ListFilesTool = {
  name: "list_files";
  result: {
    path: string;
    entries: { name: string; kind: string; is_hidden: boolean }[];
    total_count: number;
    file_count: number;
    directory_count: number;
  };
};

export type ReadFileTool = {
  name: "read_file";
  result: {
    path: string;
    content: string;
    start_line: number;
    end_line: number;
  };
};

export type MetaWriteToFileTool = {
  name: "meta_write_to_file";
  result: { path: string; message: string; diff?: string };
};

export type Todo = {
  content: string;
  created_at: string;
  id: string;
  priority: "High" | "Medium" | "Low";
  status: "Pending" | "Completed" | "InProgress";
  updated_at: string;
};

type UnknownTool = {
  name: string;
};

export type PreToolCallEvent = {
  msg: "PreToolCall";
  tool_call: ToolCall;
};

type PostToolCallBase = {
  msg: "PostToolCall";
  tool_call: ToolCall;
  text: string;
  result?: unknown;
  error?: string;
};

// TODO: search_files
export type PostToolCallEvent = PostToolCallBase &
  (
    | ExecuteCommandTool
    | ListFilesTool
    | ReadFileTool
    | MetaWriteToFileTool
    | UnknownTool
  );

type MessageContentPart = {
  text: string;
};

type MessageBase = {
  content: MessageContentPart[] | string;
};

type SystemMessage = {
  role: "system";
};

type UserMessage = {
  role: "user";
};

export type AssistantMessage = {
  role: "assistant";
  tool_calls: ToolCall[];
};

export type ToolMessage = {
  role: "tool";
  tool_call_id: string;
};

export type MessageAddedEvent = {
  msg: "MessageAdded";
  message: MessageBase &
    (SystemMessage | UserMessage | AssistantMessage | ToolMessage);
};

export type DaemonTaskSyncEvent = {
  tasks: TaskOverview[];
};

export type DaemonTaskChangeEvent = {
  task: TaskOverview;
};

export type WebRAL = {
  platform: "web";
};

export type VscodeApi = {
  getUrl(): string;
};

export type WebviewApi = {
  navigate(path: string): void;
};

export type VSCWebviewRAL = {
  platform: "vsc-webview";
  vscodeApi: comlink.Remote<VscodeApi>;
};

export type ElectronAPI = {
  selectDirectory: () => Promise<OpenDialogReturnValue>;
  getUrl: () => Promise<string>;
  mariaReady: () => Promise<void>;
  reloadApp: () => Promise<void>;
  openPathInFileExplorer: (path: string) => Promise<void>;
};

export type ElectronRAL = {
  platform: "electron";
  electronAPI: ElectronAPI;
};

export type RAL = WebRAL | ElectronRAL | VSCWebviewRAL;
