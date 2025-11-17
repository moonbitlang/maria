import { useAppSelector } from "@/app/hooks";
import { AgentTodos } from "@/components/agent-todos";
import {
  PromptInput,
  PromptInputSubmit,
  PromptInputTextarea,
  PromptInputToolbar,
  PromptInputTools,
} from "@/components/ai/prompt-input";
import { EventsDisplay } from "@/components/events-display";
import { ScrollArea } from "@/components/ui/scroll-area";
import { Separator } from "@/components/ui/separator";
import {
  useEventsQuery,
  usePostMessageMutation,
  useTaskQuery,
} from "@/features/api/apiSlice";
import {
  selectTask,
  selectTaskInput,
  setActiveTaskId,
  setInputForTask,
  defaultTask,
  selectConversationStatus,
  addToInputQueueForTask,
  selectInputQueue,
  removeNthFromInputQueueForTask,
} from "@/features/session/tasksSlice";
import { Trash2 } from "lucide-react";
import { Fragment, useEffect } from "react";
import { useDispatch } from "react-redux";
import { useParams } from "react-router";

function useSetActiveTaskId(taskId: string) {
  const dispatch = useDispatch();

  useEffect(() => {
    dispatch(setActiveTaskId(taskId));
  }, [taskId, dispatch]);
}

function TaskInput({ taskId }: { taskId: string }) {
  const dispatch = useDispatch();
  const input = useAppSelector((state) => selectTaskInput(state, taskId))!;
  const inputQueue = useAppSelector((state) =>
    selectInputQueue(state, taskId),
  )!;
  const conversationStatus = useAppSelector((state) =>
    selectConversationStatus(state, taskId),
  )!;
  const [postMessage] = usePostMessageMutation();

  function setInput(value: string) {
    dispatch(setInputForTask({ taskId, input: value }));
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    switch (conversationStatus) {
      case "generating": {
        // queue the input
        dispatch(addToInputQueueForTask({ taskId, input: input.trim() }));
        break;
      }
      case "idle": {
        await postMessage({ taskId, content: input.trim() });
        break;
      }
    }
    setInput("");
  };

  const handleRemoveFromQueue = (index: number) => {
    dispatch(removeNthFromInputQueueForTask({ taskId, n: index }));
  };

  return (
    <div className="p-4 flex flex-col">
      {inputQueue.length > 0 && (
        <div className="max-w-4xl w-full mx-auto mb-3 min-h-0">
          <div className="text-xs text-muted-foreground/70 mb-1.5 px-1">
            {inputQueue.length} queued{" "}
            {inputQueue.length === 1 ? "message" : "messages"}
          </div>
          <ScrollArea className="max-h-24 bg-secondary/40 overflow-y-scroll rounded border border-border/40">
            {inputQueue.map((item, index) => (
              <Fragment key={index}>
                <div className="group flex items-center gap-2 px-3 py-1 hover:bg-secondary/60 text-sm">
                  <div className="flex-1 min-w-0">
                    <p className="truncate text-foreground/90">{item}</p>
                  </div>
                  <button
                    onClick={() => handleRemoveFromQueue(index)}
                    className="shrink-0 opacity-100 md:opacity-0 md:group-hover:opacity-100 text-muted-foreground hover:text-foreground cursor-pointer"
                    aria-label="Remove from queue"
                  >
                    <Trash2 className="h-3.5 w-3.5" />
                  </button>
                </div>
                {index < inputQueue.length - 1 && (
                  <Separator className="bg-border/50" />
                )}
              </Fragment>
            ))}
          </ScrollArea>
        </div>
      )}

      <PromptInput className="max-w-4xl mx-auto" onSubmit={handleSubmit}>
        <PromptInputTextarea
          className="text-lg md:text-lg"
          value={input}
          onFocus={(e) =>
            e.target.scrollIntoView({ behavior: "smooth", block: "center" })
          }
          onChange={(e) => setInput(e.target.value)}
          placeholder={"Input your task..."}
        />
        <PromptInputToolbar>
          <PromptInputTools></PromptInputTools>
          <PromptInputSubmit
            disabled={!input.trim()}
            status="ready"
            className="cursor-pointer"
          ></PromptInputSubmit>
        </PromptInputToolbar>
      </PromptInput>
    </div>
  );
}

export default function Task() {
  const params = useParams();

  // TODO: 404 error
  const taskId = params.taskId!;
  useSetActiveTaskId(taskId);

  const { data, isLoading, isSuccess } = useTaskQuery(taskId);

  const { data: events } = useEventsQuery(taskId, { skip: !isSuccess });

  const task = useAppSelector((state) => selectTask(state, taskId));

  if (isLoading) {
    return <div>Loading...</div>;
  }

  if (isSuccess) {
    const apiTask = data.task;
    const currentTask = task ?? defaultTask(apiTask.id, apiTask.name);

    const { todos } = currentTask;

    return (
      <div className="flex-1 min-h-0 flex flex-col justify-end relative">
        <AgentTodos todos={todos} />
        <EventsDisplay events={events ?? []} />
        <TaskInput taskId={taskId} />
      </div>
    );
  }
}
