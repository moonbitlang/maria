import type { ChatStatus } from "ai";
import { Clock, Folder } from "lucide-react";
import { Fragment, useEffect, useRef } from "react";
import { useDispatch } from "react-redux";
import { useParams } from "react-router";
import { useAppSelector } from "../app/hooks.ts";
import { AgentTodos } from "../components/agent-todos.tsx";
import { EventsDisplay } from "../components/events-display.tsx";
import {
  TaskPromptInput,
  type TaskPromptInputHandle,
} from "../components/task-prompt-input.tsx";
import { ScrollArea } from "../components/ui/scroll-area.tsx";
import { Separator } from "../components/ui/separator.tsx";
import {
  PromptInputButton,
  PromptInputTools,
} from "../components/ui/shadcn-io/ai/prompt-input.tsx";
import {
  Tooltip,
  TooltipContent,
  TooltipTrigger,
} from "../components/ui/tooltip.tsx";
import { WebSearchToggleTool } from "../components/web-search-toggle-tool.tsx";
import {
  usePostCancelMutation,
  usePostMessageMutation,
  useTaskEventsQuery,
  useTaskQuery,
} from "../features/api/apiSlice.ts";
import {
  addDynamicVariablesForTask,
  addToInputQueueForTask,
  selectConversationStatus,
  selectDynamicVariablesForTask,
  selectInputQueue,
  selectTaskCwd,
  selectTaskEvents,
  selectTaskInput,
  selectTaskTodos,
  selectWebSearchEnabledForTask,
  setActiveTaskId,
  setInputForTask,
  setStatusForTask,
  toggleWebSearchForTask,
  updateDynamicVariableRangesForTask,
} from "../features/session/tasksSlice.ts";
import { RAL } from "../lib/ral.ts";
import type { QueuedMessage } from "../lib/types.ts";
import { base, composeMessage } from "../lib/utils.ts";

function useSetActiveTaskId(taskId: string) {
  const dispatch = useDispatch();

  useEffect(() => {
    dispatch(setActiveTaskId(taskId));
  }, [taskId, dispatch]);
}

function PromptInput({ taskId }: { taskId: string }) {
  const dispatch = useDispatch();
  const webSearchEnabled =
    useAppSelector((state) => selectWebSearchEnabledForTask(state, taskId)) ??
    false;
  const ref = useRef<TaskPromptInputHandle>(null);
  const [postMessage] = usePostMessageMutation();
  const [postCancel] = usePostCancelMutation();
  const input = useAppSelector((state) => selectTaskInput(state, taskId)) ?? "";
  const dynamicVariables =
    useAppSelector((state) => selectDynamicVariablesForTask(state, taskId)) ??
    [];

  useEffect(() => {
    ref.current?.focus();
  });

  const taskStatus =
    useAppSelector((state) => selectConversationStatus(state, taskId)) ??
    "idle";

  let chatStatus: ChatStatus;

  if (
    taskStatus === "idle" ||
    (taskStatus === "generating" && input.trim() !== "")
  ) {
    chatStatus = "ready";
  } else {
    chatStatus = "streaming";
  }

  function setInput(input: string) {
    dispatch(setInputForTask({ taskId, input }));
  }

  async function addMessage() {
    const content = composeMessage(input.trim(), dynamicVariables);
    const { data, error } = await postMessage({
      taskId,
      content,
      web_search: webSearchEnabled,
    });
    if (data) {
      const { id, queued } = data;
      if (queued) {
        dispatch(addToInputQueueForTask({ taskId, message: { id, content } }));
      }
    } else if (error) {
      console.error(error);
    }
    ref.current?.clear();
    setInput("");
  }

  async function handleSubmit() {
    if (taskStatus === "idle") {
      await addMessage();
    } else if (taskStatus === "generating" && input.trim() !== "") {
      // on user preference
      // 1. either we queue the message
      await addMessage();
      // 2. or we cancel the current generation and send the new message immediately
    } else if (taskStatus === "generating") {
      const { data, error } = await postCancel({ taskId });
      // either success or error, we set status back to idle
      if (data !== undefined || error !== undefined) {
        dispatch(setStatusForTask({ taskId, status: "idle" }));
      }
    }
  }

  return (
    <TaskPromptInput
      ref={ref}
      onChange={setInput}
      onSubmit={handleSubmit}
      onAddDynamicVariable={(v) => {
        dispatch(addDynamicVariablesForTask({ taskId, variable: v }));
      }}
      dynamicVariables={dynamicVariables}
      onUpdateDynamicVariableRanges={(newRanges) => {
        dispatch(updateDynamicVariableRangesForTask({ taskId, newRanges }));
      }}
      chatStatus={chatStatus}
      placeholder={
        taskStatus === "generating"
          ? "Agent is working..."
          : "Input your task..."
      }
      inputTools={
        <PromptInputTools>
          <OpenCwd taskId={taskId} />
          <WebSearchToggleTool
            webSearchEnabled={webSearchEnabled}
            onClick={() => {
              dispatch(toggleWebSearchForTask({ taskId }));
            }}
          />
        </PromptInputTools>
      }
    />
  );
}

function OpenCwd({ taskId }: { taskId: string }) {
  const cwd = useAppSelector((state) => selectTaskCwd(state, taskId)) ?? "";
  const baseCwd = base(cwd);
  const ral = RAL();
  const content =
    ral.platform === "electron" ? (
      <p>
        Open <code>{cwd}</code>
      </p>
    ) : (
      <p>
        <code>{cwd}</code>
      </p>
    );
  return (
    <Tooltip>
      <TooltipTrigger asChild>
        <PromptInputButton
          className="cursor-pointer"
          onClick={async () => {
            if (ral.platform === "electron") {
              await ral.electronAPI.openPathInFileExplorer(cwd);
            }
          }}
        >
          <Folder size={16} />
          {baseCwd && <span>{baseCwd}</span>}
        </PromptInputButton>
      </TooltipTrigger>
      <TooltipContent>{content}</TooltipContent>
    </Tooltip>
  );
}

function QueuedMessages({ inputQueue }: { inputQueue: QueuedMessage[] }) {
  if (inputQueue.length === 0) {
    return null;
  }

  return (
    <div className="animate-in fade-in slide-in-from-bottom-0 mx-auto mb-2 min-h-0 w-full max-w-4xl duration-300">
      <div className="text-muted-foreground mb-2 flex items-center gap-2 px-1 text-sm font-medium">
        <Clock className="h-3.5 w-3.5" />
        <span>
          {inputQueue.length} queued{" "}
          {inputQueue.length === 1 ? "message" : "messages"}
        </span>
      </div>
      <ScrollArea className="bg-muted/30 border-border/50 max-h-32 overflow-y-auto rounded-lg border shadow-sm">
        {inputQueue.map(({ id, content }, index) => (
          <Fragment key={id}>
            <div className="group hover:bg-muted/60 flex items-center gap-3 px-2 py-1 transition-colors">
              <div className="min-w-0 flex-1">
                <p className="text-foreground/80 truncate leading-relaxed">
                  {content}
                </p>
              </div>
            </div>
            {index < inputQueue.length - 1 && (
              <Separator className="bg-border/30" />
            )}
          </Fragment>
        ))}
      </ScrollArea>
    </div>
  );
}

function Input({ taskId }: { taskId: string }) {
  const inputQueue =
    useAppSelector((state) => selectInputQueue(state, taskId)) ?? [];

  return (
    <div className="flex flex-col p-4">
      <QueuedMessages inputQueue={inputQueue} />
      <PromptInput taskId={taskId} />
    </div>
  );
}

function Todos({ taskId }: { taskId: string }) {
  const todos = useAppSelector((state) => selectTaskTodos(state, taskId));
  return <AgentTodos todos={todos} />;
}

function Events({ taskId }: { taskId: string }) {
  const events = useAppSelector((state) => selectTaskEvents(state, taskId));
  return <EventsDisplay events={events ?? []} />;
}

export default function Task() {
  const params = useParams();

  // TODO: 404 error
  const taskId = params.taskId!;
  useSetActiveTaskId(taskId);

  const { isLoading, isSuccess } = useTaskQuery(taskId);

  useTaskEventsQuery(taskId, { skip: !isSuccess });

  if (isLoading) {
    return (
      <div className="relative flex min-h-0 flex-1 flex-col justify-end">
        <Input taskId={taskId} />
      </div>
    );
  }

  if (isSuccess) {
    return (
      <div className="relative flex min-h-0 flex-1 flex-col justify-end">
        <Todos taskId={taskId} />
        <Events taskId={taskId} />
        <Input taskId={taskId} />
      </div>
    );
  }
}
