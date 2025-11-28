import {
  PromptInput,
  PromptInputButton,
  PromptInputSubmit,
  PromptInputTextarea,
  PromptInputToolbar,
  PromptInputTools,
} from "./ui/shadcn-io/ai/prompt-input";

interface TaskPromptInputProps {
  value: string;
  onChange: (value: string) => void;
  onSubmit: (e: React.FormEvent) => void | Promise<void>;
  placeholder?: string;
  disabled?: boolean;
  className?: string;
  inputTools?: React.ReactNode;
}

export function TaskPromptInput({
  value,
  onChange,
  onSubmit,
  placeholder = "Input your task...",
  disabled = false,
  className = "",
  inputTools,
}: TaskPromptInputProps) {
  const tools = inputTools ? inputTools : <PromptInputTools></PromptInputTools>;
  return (
    <PromptInput
      className={`max-w-4xl mx-auto shadow-lg hover:shadow-xl transition-shadow ${className}`}
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
          disabled={disabled || !value.trim()}
          status="ready"
          className="cursor-pointer transition-all"
        ></PromptInputSubmit>
      </PromptInputToolbar>
    </PromptInput>
  );
}
