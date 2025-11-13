import {
  PromptInput,
  PromptInputSubmit,
  PromptInputTextarea,
  PromptInputToolbar,
  PromptInputTools,
} from "@/components/ai/prompt-input";

interface ChatPromptProps {
  value: string;
  onChange: (value: string) => void;
  onSubmit: (e: React.FormEvent) => void;
  disabled?: boolean;
  placeholder?: string;
}

export function ChatPrompt({
  value,
  onChange,
  onSubmit,
  disabled = false,
  placeholder,
}: ChatPromptProps) {
  return (
    <PromptInput onSubmit={onSubmit}>
      <PromptInputTextarea
        className="text-lg md:text-lg"
        value={value}
        onChange={(e) => onChange(e.currentTarget.value)}
        placeholder={placeholder || "Type your message..."}
      />
      <PromptInputToolbar>
        <PromptInputTools></PromptInputTools>
        <PromptInputSubmit
          disabled={disabled}
          className="cursor-pointer"
        ></PromptInputSubmit>
      </PromptInputToolbar>
    </PromptInput>
  );
}
