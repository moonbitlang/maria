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
  onSubmit: (e: React.FormEvent<HTMLFormElement>) => void;
  placeholder?: string;
  className?: string;
  inputTools?: React.ReactNode;
  chatStatus?: ChatStatus;
}

export function TaskPromptInput({
  value,
  onChange,
  onSubmit,
  placeholder = "Input your task...",
  className = "",
  inputTools,
  chatStatus = "ready",
}: TaskPromptInputProps) {
  const tools = inputTools ? inputTools : <PromptInputTools></PromptInputTools>;
  const disabled = chatStatus === "ready" && value.trim() === "";
  return (
    <PromptInput
      className={cn(
        `max-w-4xl mx-auto shadow-lg hover:shadow-xl transition-shadow`,
        className,
      )}
      onSubmit={onSubmit}
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
          status={chatStatus}
          className="cursor-pointer transition-all"
        ></PromptInputSubmit>
      </PromptInputToolbar>
    </PromptInput>
  );
}
