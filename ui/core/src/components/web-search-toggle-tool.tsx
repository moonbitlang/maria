import { Globe } from "lucide-react";
import { cn } from "../lib/utils";
import { PromptInputButton } from "./ui/shadcn-io/ai/prompt-input";
import { Tooltip, TooltipContent, TooltipTrigger } from "./ui/tooltip";

type WebSearchToggleToolProps = {
  webSearchEnabled: boolean;
  onClick: () => void;
};

function WebSearchToggleTool(props: WebSearchToggleToolProps) {
  const { webSearchEnabled, onClick } = props;
  return (
    <Tooltip>
      <TooltipTrigger asChild>
        <PromptInputButton className="cursor-pointer" onClick={onClick}>
          <Globe
            className={cn(webSearchEnabled ? "text-blue-500" : "")}
            size={16}
          />
        </PromptInputButton>
      </TooltipTrigger>
      <TooltipContent>
        <p>Web Search {webSearchEnabled ? "Enabled" : "Disabled"}</p>
      </TooltipContent>
    </Tooltip>
  );
}

export { WebSearchToggleTool };
