import { useAppSelector } from "@/app/hooks";
import { AgentTodos } from "@/components/agent-todos";
import { TaskPromptInput } from "@/components/task-prompt-input";
import { EventsDisplay } from "@/components/events-display";
import { ScrollArea } from "@/components/ui/scroll-area";
import { Separator } from "@/components/ui/separator";
import { Skeleton } from "@/components/ui/skeleton";
import {
  useTaskEventsQuery,
  usePostMessageMutation,
  useTaskQuery,
} from "@/features/api/apiSlice";
import {
  selectTaskInput,
  setActiveTaskId,
  setInputForTask,
  selectConversationStatus,
  addToInputQueueForTask,
  selectInputQueue,
} from "@/features/session/tasksSlice";
import { Clock } from "lucide-react";
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
  const status = useAppSelector((state) =>
    selectConversationStatus(state, taskId),
  )!;
  const [postMessage] = usePostMessageMutation();

  function setInput(value: string) {
    dispatch(setInputForTask({ taskId, input: value }));
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
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
        onSubmit={handleSubmit}
        placeholder={
          status === "generating" ? "Agent is working..." : "Input your task..."
        }
      />
    </div>
  );
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
      <div className="flex-1 min-h-0 flex flex-col justify-end p-4">
        <div className="max-w-4xl mx-auto w-full space-y-4 mb-4">
          <div className="flex items-start gap-3">
            <Skeleton className="h-8 w-8 rounded-full shrink-0" />
            <div className="flex-1 space-y-2">
              <Skeleton className="h-4 w-3/4" />
              <Skeleton className="h-4 w-1/2" />
            </div>
          </div>
          <div className="flex items-start gap-3 flex-row-reverse">
            <Skeleton className="h-8 w-8 rounded-full shrink-0" />
            <div className="flex-1 space-y-2">
              <Skeleton className="h-4 w-2/3" />
              <Skeleton className="h-4 w-1/3" />
            </div>
          </div>
        </div>
        <div className="max-w-4xl mx-auto w-full">
          <Skeleton className="h-24 w-full rounded-xl" />
        </div>
      </div>
    );
  }

  if (isSuccess) {
    return (
      <div className="flex-1 min-h-0 flex flex-col justify-end relative">
        <AgentTodos taskId={taskId} />
        <EventsDisplay taskId={taskId} />
        <TaskInput taskId={taskId} />
      </div>
    );
  }
}
