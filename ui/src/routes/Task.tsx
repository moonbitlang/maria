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
import {
  useEventsQuery,
  usePostMessageMutation,
} from "@/features/api/apiSlice";
import { selectTask } from "@/features/session/tasksSlice";
import { useState } from "react";
import { useParams } from "react-router";

export default function Task() {
  const params = useParams();

  // TODO: 404 error
  const taskId = params.taskId!;
  const task = useAppSelector((state) => selectTask(state, taskId))!;
  const [input, setInput] = useState("");
  // const todos = useAppSelector(selectTodos);
  const [postMessage] = usePostMessageMutation();
  const { data } = useEventsQuery(taskId);

  const { chatStatus, todos } = task;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setInput("");
    await postMessage({ taskId, content: input });
  };

  return (
    <div className="flex-1 min-h-0 flex flex-col justify-end m-auto w-full max-w-4xl relative">
      <AgentTodos todos={todos} />
      <EventsDisplay events={data ?? []} taskId={taskId} />
      <div className="p-4">
        <PromptInput onSubmit={handleSubmit}>
          <PromptInputTextarea
            className="text-lg md:text-lg"
            value={input}
            onFocus={(e) =>
              e.target.scrollIntoView({ behavior: "smooth", block: "center" })
            }
            onChange={(e) => setInput(e.currentTarget.value)}
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
    </div>
  );
}
