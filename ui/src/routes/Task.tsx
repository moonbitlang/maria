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
import { useEventsQuery, useTaskQuery } from "@/features/api/apiSlice";
import {
  selectTask,
  selectTaskInput,
  selectTaskChatStatus,
  setActiveTaskId,
  setInputForTask,
  defaultTask,
} from "@/features/session/tasksSlice";
import { useEffect } from "react";
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
  const chatStatus = useAppSelector((state) =>
    selectTaskChatStatus(state, taskId),
  )!;

  function setInput(value: string) {
    dispatch(setInputForTask({ taskId, input: value }));
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setInput("");
  };

  return (
    <div className="p-4">
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
            disabled={chatStatus !== "ready" && !input.trim()}
            status={chatStatus}
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
