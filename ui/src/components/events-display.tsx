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
              switch (event.message.role) {
                case "system": {
                  // dont render system messages
                  return <></>;
                }
                case "assistant": {
                  // dont render assistant messages, they are rendered on RequestCompleted
                  return <></>;
                }
                case "tool": {
                  // dont render tool messages, they are rendered on PostToolCall
                  return <></>;
                }
                case "user": {
                  const contents =
                    typeof event.message.content === "string"
                      ? [event.message.content]
                      : event.message.content.map((part) => part.text);

                  return (
                    <Message from="user">
                      <MessageContent>
                        <Response parseIncompleteMarkdown={false}>
                          {contents.join("").trim()}
                        </Response>
                      </MessageContent>
                    </Message>
                  );
                }
              }
              return <></>;
            }
            case "PostToolCall": {
              const output = (
                <Response parseIncompleteMarkdown={false}>
                  {["````markdown", event.text, "````"].join("\n")}
                </Response>
              );
              if (event.result) {
                return (
                  <Tool>
                    <ToolHeader type={event.name} state="output-available" />
                    <ToolContent>
                      <ToolOutput output={output} errorText={undefined} />
                    </ToolContent>
                  </Tool>
                );
              } else if (event.error) {
                // toolcall error
                return (
                  <Tool>
                    <ToolHeader type={event.name} state="output-error" />
                    <ToolContent>
                      <ToolOutput
                        output={output}
                        errorText={`Tool call error: <${event.name}>`}
                      />
                    </ToolContent>
                  </Tool>
                );
              } else {
                return (
                  <Tool>
                    <ToolHeader type={event.name} state="output-available" />
                    <ToolContent>
                      <ToolOutput
                        output={output}
                        errorText={`Tool call error: <${event.name}>`}
                      />
                    </ToolContent>
                  </Tool>
                );
              }
            }
            case "RequestCompleted": {
              const content = event.message.content.trim();
              if (content === "") {
                return <></>;
              }
              return (
                <Message from={event.message.role}>
                  <MessageContent>
                    <Response parseIncompleteMarkdown={false}>
                      {event.message.content.trim()}
                    </Response>
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
