import { useAppSelector } from "../app/hooks.ts";
import { AgentTodos } from "../components/agent-todos.tsx";
import { TaskPromptInput } from "../components/task-prompt-input.tsx";
import { EventsDisplay } from "../components/events-display.tsx";
import { ScrollArea } from "../components/ui/scroll-area.tsx";
import { Separator } from "../components/ui/separator.tsx";
import {
  useTaskEventsQuery,
  usePostMessageMutation,
  useTaskQuery,
  usePostCancelMutation,
} from "../features/api/apiSlice.ts";
import {
  selectTaskInput,
  setActiveTaskId,
  setInputForTask,
  selectConversationStatus,
  addToInputQueueForTask,
  selectInputQueue,
  selectTaskTodos,
  selectTaskEvents,
  setStatusForTask,
  selectTaskCwd,
} from "../features/session/tasksSlice.ts";
import { Clock, Folder } from "lucide-react";
import { Fragment, useEffect } from "react";
import { useDispatch } from "react-redux";
import { useParams } from "react-router";
import type { ChatStatus } from "ai";
import {
  PromptInputButton,
  PromptInputTools,
} from "../components/ui/shadcn-io/ai/prompt-input.tsx";
import {
  Tooltip,
  TooltipContent,
  TooltipTrigger,
} from "../components/ui/tooltip.tsx";
import { base } from "../lib/utils.ts";

function useSetActiveTaskId(taskId: string) {
  const dispatch = useDispatch();

  useEffect(() => {
    dispatch(setActiveTaskId(taskId));
  }, [taskId, dispatch]);
}

function Input({ taskId }: { taskId: string }) {
  const dispatch = useDispatch();

  const input = useAppSelector((state) => selectTaskInput(state, taskId))!;
  const cwd = useAppSelector((state) => selectTaskCwd(state, taskId))!;
  const baseCwd = base(cwd);
  const inputQueue = useAppSelector((state) =>
    selectInputQueue(state, taskId),
  )!;
  const taskStatus = useAppSelector((state) =>
    selectConversationStatus(state, taskId),
  )!;
  const chatStatus: ChatStatus =
    taskStatus === "generating" ? "streaming" : "ready";
  const [postMessage] = usePostMessageMutation();
  const [postCancel] = usePostCancelMutation();

  function setInput(value: string) {
    dispatch(setInputForTask({ taskId, input: value }));
  }

  const handleReadySubmit = async () => {
    const content = input.trim();
    const { data, error } = await postMessage({
      taskId,
      content,
    });
    if (data) {
      const { id, queued } = data;
      if (queued) {
        dispatch(addToInputQueueForTask({ taskId, message: { id, content } }));
      }
    } else if (error) {
      console.error(error);
    }
    setInput("");
  };

  const handleStreamingSubmit = async () => {
    const { data, error } = await postCancel({ taskId });
    // either success or error, we set status back to idle
    if (data === null || error !== undefined) {
      dispatch(setStatusForTask({ taskId, status: "idle" }));
    }
  };

  return (
    <div className="p-4 flex flex-col">
      {inputQueue.length > 0 && (
        <div className="max-w-4xl w-full mx-auto mb-2 min-h-0 animate-in fade-in slide-in-from-bottom-0 duration-300">
          <div className="flex items-center gap-2 text-sm font-medium text-muted-foreground mb-2 px-1">
            <Clock className="h-3.5 w-3.5" />
            <span>
              {inputQueue.length} queued{" "}
              {inputQueue.length === 1 ? "message" : "messages"}
            </span>
          </div>
          <ScrollArea className="max-h-32 bg-muted/30 overflow-y-auto rounded-lg border border-border/50 shadow-sm">
            {inputQueue.map(({ id, content }, index) => (
              <Fragment key={id}>
                <div className="group flex items-center gap-3 px-2 py-1 hover:bg-muted/60 transition-colors">
                  <div className="flex-1 min-w-0">
                    <p className="truncate text-foreground/80 leading-relaxed">
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
      )}

      <TaskPromptInput
        value={input}
        onChange={setInput}
        onReadySubmit={handleReadySubmit}
        onStreamingSubmit={handleStreamingSubmit}
        status={chatStatus}
        placeholder={
          taskStatus === "generating"
            ? "Agent is working..."
            : "Input your task..."
        }
        inputTools={
          <PromptInputTools>
            <Tooltip>
              <TooltipTrigger asChild>
                <PromptInputButton>
                  <Folder size={16} />
                  {baseCwd && <span>{baseCwd}</span>}
                </PromptInputButton>
              </TooltipTrigger>
              <TooltipContent>
                <p>{cwd}</p>
              </TooltipContent>
            </Tooltip>
          </PromptInputTools>
        }
      />
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
    return null;
  }

  if (isSuccess) {
    return (
      <div className="flex-1 min-h-0 flex flex-col justify-end relative">
        <Todos taskId={taskId} />
        <Events taskId={taskId} />
        <Input taskId={taskId} />
      </div>
    );
  }
}
