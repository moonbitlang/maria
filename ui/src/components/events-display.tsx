import { Message, MessageContent } from "@/components/ai/message";
import {
  Conversation,
  ConversationContent,
  ConversationScrollButton,
} from "./ui/shadcn-io/ai/conversation";
import type { SessionEvent } from "@/features/session/sessionSlice";
import {
  Tool,
  ToolContent,
  ToolHeader,
  ToolOutput,
} from "@/components/ai/tool";
import { Response } from "@/components/ai/response";

interface EventsDisplayProps {
  events: SessionEvent[];
}

export function EventsDisplay(props: EventsDisplayProps) {
  const { events } = props;

  if (events.length === 0) {
    return null;
  }

  return (
    <Conversation className="h-full">
      <ConversationContent className="w-full max-w-4xl mx-auto px-4">
        {events.map((event) => {
          switch (event.msg) {
            case "MessageAdded": {
              return <></>;
            }
            case "PostToolCall": {
              if (event.result) {
                return <Tool></Tool>;
              } else if (event.error) {
                // toolcall error
                return (
                  <Tool>
                    <ToolHeader
                      type={`tool-${event.name}`}
                      state="output-error"
                    />
                    <ToolContent>
                      <ToolOutput
                        output
                        errorText={`Tool call error: <${event.name}>`}
                      />
                    </ToolContent>
                  </Tool>
                );
              } else {
                return <></>;
              }
            }
            case "RequestCompleted": {
              return (
                <Message from={event.message.role as "user" | "assistant"}>
                  <MessageContent>
                    <Response>{event.message.content}</Response>
                  </MessageContent>
                </Message>
              );
            }
            default: {
              return <></>;
            }
          }
        })}
      </ConversationContent>
      <ConversationScrollButton />
    </Conversation>
  );
}
