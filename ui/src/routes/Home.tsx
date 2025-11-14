import { useState } from "react";
import { Layout } from "@/components/layout";
import { EventsDisplay } from "@/components/events-display";
import { AgentTodos } from "@/components/agent-todos";
import {
  useGetEventsQuery,
  usePostMessageMutation,
} from "@/features/api/apiSlice";
import {
  PromptInput,
  PromptInputSubmit,
  PromptInputTextarea,
  PromptInputToolbar,
  PromptInputTools,
} from "@/components/ai/prompt-input";
import { useAppSelector } from "@/app/hooks";
import { selectTodos } from "@/features/session/sessionSlice";

function ChatView() {
  const [input, setInput] = useState("");
  const todos = useAppSelector(selectTodos);

  const [postMessage] = usePostMessageMutation();

  const { data } = useGetEventsQuery();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setInput("");
    await postMessage(input);
  };

  return (
    <>
      <AgentTodos todos={todos} />
      <div className="flex-1 min-h-0 overflow-y-auto">
        <EventsDisplay events={data ?? []} />
      </div>
      <div className="p-4">
        <PromptInput onSubmit={handleSubmit}>
          <PromptInputTextarea
            className="text-lg md:text-lg"
            value={input}
            onChange={(e) => setInput(e.currentTarget.value)}
            placeholder={"Input your task..."}
          />
          <PromptInputToolbar>
            <PromptInputTools></PromptInputTools>
            <PromptInputSubmit
              disabled={!input.trim()}
              className="cursor-pointer"
            ></PromptInputSubmit>
          </PromptInputToolbar>
        </PromptInput>
      </div>
    </>
  );
}

function Home() {
  return (
    <Layout>
      <ChatView />
    </Layout>
  );
}

export default Home;
