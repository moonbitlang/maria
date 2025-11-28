import type { ChatStatus } from "ai";
import {
  PromptInput,
  PromptInputSubmit,
  PromptInputTextarea,
  PromptInputToolbar,
  PromptInputTools,
} from "./ui/shadcn-io/ai/prompt-input";
import { cn } from "../lib/utils";

interface TaskPromptInputProps {
  value: string;
  onChange: (value: string) => void;
  onReadySubmit: () => void;
  onStreamingSubmit?: () => void;
  placeholder?: string;
  className?: string;
  inputTools?: React.ReactNode;
  status?: ChatStatus;
}

export function TaskPromptInput({
  value,
  onChange,
  onReadySubmit,
  onStreamingSubmit,
  placeholder = "Input your task...",
  className = "",
  inputTools,
  status = "ready",
}: TaskPromptInputProps) {
  const tools = inputTools ? inputTools : <PromptInputTools></PromptInputTools>;
  let disabled;
  if (status === "ready" && value.trim() === "") {
    disabled = true;
  } else {
    disabled = false;
  }
  return (
    <PromptInput
      className={cn(
        `max-w-4xl mx-auto shadow-lg hover:shadow-xl transition-shadow`,
        className,
      )}
      onSubmit={(e) => {
        e.preventDefault();
        if (status === "ready") {
          onReadySubmit();
        } else if (status === "streaming" && onStreamingSubmit) {
          onStreamingSubmit();
        }
      }}
    >
      <PromptInputTextarea
        className="text-base md:text-base min-h-[52px]"
        value={value}
        onFocus={(e) =>
          e.target.scrollIntoView({ behavior: "smooth", block: "center" })
        }
        onChange={(e) => onChange(e.target.value)}
        placeholder={placeholder}
      />
      <PromptInputToolbar>
        {tools}
        <PromptInputSubmit
          disabled={disabled}
          status={status}
          className="cursor-pointer transition-all"
        ></PromptInputSubmit>
      </PromptInputToolbar>
    </PromptInput>
  );
}
