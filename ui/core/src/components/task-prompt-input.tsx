import type { ChatStatus } from "ai";
import { cn } from "../lib/utils";
import {
  PromptInput,
  PromptInputSubmit,
  PromptInputTextarea,
  PromptInputToolbar,
  PromptInputTools,
} from "./ui/shadcn-io/ai/prompt-input";

interface TaskPromptInputProps {
  value: string;
  onChange: (value: string) => void;
  onSubmit: (e: React.FormEvent<HTMLFormElement>) => void;
  placeholder?: string;
  className?: string;
  inputTools?: React.ReactNode;
  chatStatus?: ChatStatus;
  ref?: React.Ref<HTMLTextAreaElement>;
}

export function TaskPromptInput({
  value,
  onChange,
  onSubmit,
  placeholder = "Input your task...",
  className = "",
  inputTools,
  chatStatus = "ready",
  ref,
}: TaskPromptInputProps) {
  const tools = inputTools ? inputTools : <PromptInputTools></PromptInputTools>;
  const disabled = chatStatus === "ready" && value.trim() === "";
  return (
    <PromptInput
      className={cn(
        `mx-auto max-w-4xl shadow-lg transition-shadow hover:shadow-xl`,
        className,
      )}
      onSubmit={onSubmit}
    >
      <PromptInputTextarea
        ref={ref}
        className="min-h-[52px] text-base md:text-base"
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
