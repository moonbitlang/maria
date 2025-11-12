import { useState } from "react";
import { Layout } from "@/components/layout";
import { ChatPrompt } from "@/components/chat-prompt";
import { EventsDisplay } from "@/components/events-display";
import { useGetEventsQuery } from "@/features/api/apiSlice";

function ChatView() {
  const [input, setInput] = useState("");

  const { data } = useGetEventsQuery();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setInput("");
  };

  return (
    <div className="flex flex-1 flex-col min-h-0 relative gap-4">
      {/* Events display - full width container with scrollbar at edge */}
      <div className="flex-1 min-h-0 overflow-hidden">
        <EventsDisplay events={data ?? []} />
      </div>
      {/* Prompt input - fixed at bottom with width constraint */}
      <div className="w-full shrink-0 pb-4">
        <div className="w-full max-w-4xl mx-auto px-4">
          <ChatPrompt
            value={input}
            onChange={setInput}
            onSubmit={handleSubmit}
            disabled={!input.trim()}
            placeholder={"Input your task..."}
          />
        </div>
      </div>
    </div>
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
