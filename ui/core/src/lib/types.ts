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
  name: string | null;
  status: Status;
  created: number;
  cwd: string;
};

export type TaskEvent = {
  id: number;
  desc: TaskEventDesc;
};

export type TaskEventDesc =
  | AssistantMessageEvent
  | PreToolCallEvent
  | PostToolCallEvent
  | UserMessageEvent
  | PostConversationEvent
  | MessageUnqueuedEvent;

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

export type AssistantMessageEvent = {
  msg: "AssistantMessage";
  content: string;
  tool_calls: ToolCall[];
  usage?: {
    completion_tokens: number;
    prompt_tokens: number;
    prompt_tokens_details?: {
      cached_tokens: number;
    };
    total_tokens: number;
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

export type TodoTool = {
  name: "todo";
  result: [
    "Read" | "Write",
    {
      todos: Todo[];
    },
  ];
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
  rendered?: string;
  text?: string;
  result?: unknown;
  error?: unknown;
};

// TODO: search_files
export type PostToolCallEvent = PostToolCallBase &
  (
    | ExecuteCommandTool
    | ListFilesTool
    | ReadFileTool
    | MetaWriteToFileTool
    | TodoTool
    | UnknownTool
  );

export type AssistantMessage = {
  role: "assistant";
  tool_calls: ToolCall[];
};

export type ToolMessage = {
  role: "tool";
  tool_call_id: string;
};

export type UserMessageEvent = {
  msg: "UserMessage";
  content: string;
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
  getDynamicVariables(query: string): Promise<ChatDynamicVariableInfo[]>;
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

export type ResultTuple<T> = [T, undefined] | [undefined, Error];

export const CompletionItemKind = {
  Method: 0,
  Function: 1,
  Constructor: 2,
  Field: 3,
  Variable: 4,
  Class: 5,
  Struct: 6,
  Interface: 7,
  Module: 8,
  Property: 9,
  Event: 10,
  Operator: 11,
  Unit: 12,
  Value: 13,
  Constant: 14,
  Enum: 15,
  EnumMember: 16,
  Keyword: 17,
  Text: 18,
  Color: 19,
  File: 20,
  Reference: 21,
  Customcolor: 22,
  Folder: 23,
  TypeParameter: 24,
  User: 25,
  Issue: 26,
  Tool: 27,
  Snippet: 28,
} as const;

export type CompletionItemKind =
  (typeof CompletionItemKind)[keyof typeof CompletionItemKind];

type ChatDynamicVariableInfoBase = {
  name: string;
  itemKind: CompletionItemKind;
};

export type ChatDynamicVariableInfo = ChatDynamicVariableInfoBase &
  (
    | {
        kind: "command";
      }
    | {
        kind: "file" | "symbol";
        uri: string;
      }
  );

export type ChatDynamicVariable = {
  info: ChatDynamicVariableInfo;
  start: number;
  end: number;
};
