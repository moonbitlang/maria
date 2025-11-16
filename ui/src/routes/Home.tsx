import { useState } from "react";
import { EventsDisplay } from "@/components/events-display";
import { AgentTodos } from "@/components/agent-todos";
import {
  PromptInput,
  PromptInputSubmit,
  PromptInputTextarea,
  PromptInputToolbar,
  PromptInputTools,
} from "@/components/ai/prompt-input";
import { useAppSelector } from "@/app/hooks";
import { selectChatStatus, selectTodos } from "@/features/session/sessionSlice";
import { useNewTaskMutation } from "@/features/api/apiSlice";
import { useNavigate } from "react-router";

function ChatView() {
  const [input, setInput] = useState("");
  const todos = useAppSelector(selectTodos);
  const chatStatus = useAppSelector(selectChatStatus);
  const navigate = useNavigate();

  const [newTask] = useNewTaskMutation();

  // const { data } = useGetEventsQuery();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setInput("");
    const res = await newTask(input);
    if (res.data) {
      navigate(`task/${res.data.task.id}`);
    }
  };

  return (
    <div className="flex-1 min-h-0 flex flex-col m-auto w-full max-w-4xl relative">
      <AgentTodos todos={todos} />
      <EventsDisplay events={[]} />
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

function Home() {
  return <ChatView />;
}

export default Home;
