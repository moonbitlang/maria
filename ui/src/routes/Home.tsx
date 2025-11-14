import { useState } from "react";
import { Layout } from "@/components/layout";
import { EventsDisplay } from "@/components/events-display";
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

function ChatView() {
  const [input, setInput] = useState("");

  const [postMessage] = usePostMessageMutation();

  const { data } = useGetEventsQuery();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setInput("");
    await postMessage(input);
  };

  return (
    <>
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
