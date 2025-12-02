import {
  CheckCircle2,
  FileIcon,
  FolderIcon,
  Terminal,
  XCircle,
} from "lucide-react";
import {
  type ExecuteCommandTool,
  type ListFilesTool,
  type MessageAddedEvent,
  type MetaWriteToFileTool,
  type PostToolCallEvent,
  type PreToolCallEvent,
  type ReadFileTool,
  type RequestCompletedEvent,
  type TaskEvent,
} from "../lib/types";
import { Badge } from "./ui/badge";
import { ScrollArea } from "./ui/scroll-area";
import { Separator } from "./ui/separator";
import { CodeBlock } from "./ui/shadcn-io/ai/code-block";
import {
  Conversation,
  ConversationContent,
  ConversationScrollButton,
} from "./ui/shadcn-io/ai/conversation";
import { Message, MessageContent } from "./ui/shadcn-io/ai/message";
import { Response } from "./ui/shadcn-io/ai/response";
import {
  Tool,
  ToolContent,
  ToolHeader,
  ToolInput,
  ToolOutput,
} from "./ui/shadcn-io/ai/tool";

interface EventsDisplayProps {
  events: TaskEvent[];
}

function ShowMessageAdded({ event }: { event: MessageAddedEvent }) {
  const { message } = event;
  switch (message.role) {
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
        typeof message.content === "string"
          ? [message.content]
          : message.content.map((part) => part.text);

      return (
        <Message from="user">
          <MessageContent>
            <Response className="dark" parseIncompleteMarkdown={false}>
              {contents.join("").trim()}
            </Response>
          </MessageContent>
        </Message>
      );
    }
  }
}

function ReadFile({ readFile }: { readFile: ReadFileTool }) {
  const { name, result } = readFile;
  const language = result.path.split(".").pop() || "plaintext";
  return (
    <Tool>
      <ToolHeader type={name} state="output-available" />
      <ToolContent>
        <ToolInput input={{ path: result.path }} />
        <ToolOutput
          output={<CodeBlock language={language} code={result.content} />}
          errorText={undefined}
        ></ToolOutput>
      </ToolContent>
    </Tool>
  );
}

function ListFiles({ listFiles }: { listFiles: ListFilesTool }) {
  const { name, result } = listFiles;
  const { entries, file_count, directory_count, total_count } = result;

  return (
    <Tool>
      <ToolHeader type={name} state="output-available" />
      <ToolContent>
        <ToolInput input={{ path: result.path }} />
        <ToolOutput
          output={
            <div className="flex flex-col gap-3 p-3">
              <div className="flex items-center gap-2">
                <Badge variant="secondary" className="font-normal">
                  {total_count} {total_count !== 1 ? "items" : "item"}
                </Badge>
                {directory_count > 0 && (
                  <Badge variant="outline" className="font-normal">
                    <FolderIcon className="mr-1" />
                    {directory_count}{" "}
                    {directory_count !== 1 ? "folders" : "folder"}
                  </Badge>
                )}
                {file_count > 0 && (
                  <Badge variant="outline" className="font-normal">
                    <FileIcon className="mr-1" />
                    {file_count} {file_count !== 1 ? "files" : "file"}
                  </Badge>
                )}
              </div>
              <ScrollArea className="max-h-[300px] rounded-md border">
                <div className="p-2">
                  {entries.map((e, i) => (
                    <div
                      key={i}
                      className="hover:bg-accent group flex items-center gap-2 rounded-md px-3 py-2 transition-colors"
                    >
                      {e.kind === "directory" ? (
                        <FolderIcon className="h-4 w-4 shrink-0 text-blue-500" />
                      ) : (
                        <FileIcon className="text-muted-foreground h-4 w-4 shrink-0" />
                      )}
                      <span className="truncate font-mono text-sm">
                        {e.name}
                      </span>
                    </div>
                  ))}
                </div>
              </ScrollArea>
            </div>
          }
          errorText={undefined}
        />
      </ToolContent>
    </Tool>
  );
}

function MetaWriteToFile({ event }: { event: MetaWriteToFileTool }) {
  const { name, result } = event;
  return (
    <Tool className="">
      <ToolHeader type={name} state="output-available" />
      <ToolContent>
        <ToolInput input={{ path: result.path }} />
        <ToolOutput
          errorText={undefined}
          output={
            <div className="p-3">
              <p className="text-foreground mb-3 text-base">{result.message}</p>
              {result.diff && (
                <CodeBlock
                  language="diff"
                  code={result.diff.trim()}
                ></CodeBlock>
              )}
            </div>
          }
        ></ToolOutput>
      </ToolContent>
    </Tool>
  );
}

function CommandOutputSection({
  title,
  icon: Icon,
  content,
  variant = "default",
}: {
  title: string;
  icon: React.ComponentType<{ className?: string }>;
  content: string;
  variant?: "default" | "error";
}) {
  return (
    <>
      <Separator />
      <div className="space-y-2">
        <div
          className={`flex items-center gap-2 text-xs ${
            variant === "error" ? "text-destructive" : "text-muted-foreground"
          }`}
        >
          <Icon className="size-3" />
          <span>{title}</span>
        </div>
        <CodeBlock
          className="max-h-[300px] overflow-scroll"
          language="plaintext"
          code={content.trim()}
        />
      </div>
    </>
  );
}

function ExecuteCommand({ event }: { event: ExecuteCommandTool }) {
  const { name, result } = event;
  const [, details] = result;
  const isSuccess = details.status === 0;
  const hasStdout = details.stdout.trim().length > 0;
  const hasStderr = details.stderr?.trim().length > 0;
  const hasOutput = hasStdout || hasStderr;
  return (
    <Tool>
      <ToolHeader type={name} state="output-available" />
      <ToolContent>
        <ToolInput input={{ command: details.command }} />
        <ToolOutput
          errorText={undefined}
          output={
            <div className="space-y-3 p-3">
              {/* Status Header */}
              <div className="flex items-center gap-2">
                {isSuccess ? (
                  <CheckCircle2 className="h-4 w-4 shrink-0 text-green-500" />
                ) : (
                  <XCircle className="text-destructive h-4 w-4 shrink-0" />
                )}
                <Badge
                  variant={isSuccess ? "outline" : "destructive"}
                  className="font-mono"
                >
                  Exit Code: {details.status}
                </Badge>
              </div>

              {hasStdout && (
                <CommandOutputSection
                  title="Output"
                  icon={Terminal}
                  content={details.stdout}
                />
              )}

              {hasStderr && (
                <CommandOutputSection
                  title="Error Output"
                  icon={XCircle}
                  content={details.stderr}
                  variant="error"
                />
              )}

              {!hasOutput && isSuccess && (
                <p className="text-muted-foreground text-sm italic">
                  Command executed successfully with no output.
                </p>
              )}
            </div>
          }
        ></ToolOutput>
      </ToolContent>
    </Tool>
  );
}

function ShowPostToolCall({ event }: { event: PostToolCallEvent }) {
  const output = (
    <Response parseIncompleteMarkdown={false}>
      {["````markdown", event.text, "````"].join("\n")}
    </Response>
  );
  if (event.result) {
    switch (event.name) {
      case "read_file": {
        return <ReadFile readFile={event as ReadFileTool} />;
      }
      case "list_files": {
        return <ListFiles listFiles={event as ListFilesTool} />;
      }
      case "meta_write_to_file": {
        return <MetaWriteToFile event={event as MetaWriteToFileTool} />;
      }
      case "execute_command": {
        return <ExecuteCommand event={event as ExecuteCommandTool} />;
      }
      case "todo": {
        // No need to render anything for todo tool calls
        return <></>;
      }
    }
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
            output={undefined}
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

function ShowRequestCompleted({ event }: { event: RequestCompletedEvent }) {
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

function ShowPreToolCall({ event }: { event: PreToolCallEvent }) {
  return (
    <Tool>
      <ToolHeader
        type={event.tool_call.function.name}
        state="input-available"
      />
      <ToolContent>
        <ToolInput input={JSON.parse(event.tool_call.function.arguments)} />
      </ToolContent>
    </Tool>
  );
}

export function EventsDisplay(props: EventsDisplayProps) {
  const { events } = props;
  return (
    <Conversation className="min-h-0">
      <ConversationContent className="mx-auto max-w-4xl overflow-x-hidden">
        {events.map((event, i) => {
          switch (event.msg) {
            case "PreToolCall":
              return <ShowPreToolCall key={i} event={event} />;
            case "MessageAdded":
              return <ShowMessageAdded key={i} event={event} />;
            case "PostToolCall":
              return <ShowPostToolCall key={i} event={event} />;
            case "RequestCompleted":
              return <ShowRequestCompleted key={i} event={event} />;
            default: {
              return null;
            }
          }
        })}
      </ConversationContent>
      <ConversationScrollButton />
    </Conversation>
  );
}
