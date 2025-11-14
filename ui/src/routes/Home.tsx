import { useState, useEffect, useRef } from "react";
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
import {
  selectTodos,
  selectWaitingForEvent,
} from "@/features/session/sessionSlice";
import type { ChatStatus } from "ai";

function ChatView() {
  const [input, setInput] = useState("");
  const [keyboardOffset, setKeyboardOffset] = useState(0);
  const inputContainerRef = useRef<HTMLDivElement>(null);
  const todos = useAppSelector(selectTodos);
  const waitingForEvent = useAppSelector(selectWaitingForEvent);

  const status: ChatStatus = waitingForEvent ? "submitted" : "ready";

  const [postMessage] = usePostMessageMutation();

  const { data } = useGetEventsQuery();

  useEffect(() => {
    const handleResize = () => {
      if (window.visualViewport) {
        const viewportHeight = window.visualViewport.height;
        const windowHeight = window.innerHeight;
        const offset = windowHeight - viewportHeight;
        setKeyboardOffset(offset);
      }
    };

    if (window.visualViewport) {
      window.visualViewport.addEventListener("resize", handleResize);
      window.visualViewport.addEventListener("scroll", handleResize);
      handleResize();
    }

    return () => {
      if (window.visualViewport) {
        window.visualViewport.removeEventListener("resize", handleResize);
        window.visualViewport.removeEventListener("scroll", handleResize);
      }
    };
  }, []);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setInput("");
    await postMessage(input);
  };

  return (
    <div className="flex-1 min-h-0 flex flex-col m-auto w-full max-w-4xl relative">
      <AgentTodos todos={todos} />
      <div
        className="flex-1 min-h-0 overflow-y-auto"
        style={{
          paddingBottom:
            keyboardOffset > 0
              ? `${inputContainerRef.current?.offsetHeight || 0}px`
              : undefined,
        }}
      >
        <EventsDisplay events={data ?? []} />
      </div>
      <div
        ref={inputContainerRef}
        className="p-4 md:relative md:bottom-auto"
        style={
          keyboardOffset > 0
            ? {
                position: "fixed",
                bottom: `${keyboardOffset}px`,
                left: 0,
                right: 0,
                maxWidth: "56rem",
                margin: "0 auto",
                backgroundColor: "var(--background)",
                zIndex: 50,
              }
            : undefined
        }
      >
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
              disabled={waitingForEvent && !input.trim()}
              status={status}
              className="cursor-pointer"
            ></PromptInputSubmit>
          </PromptInputToolbar>
        </PromptInput>
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
