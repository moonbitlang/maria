import { Folder, X } from "lucide-react";
import { useEffect, useRef } from "react";
import { useNavigate } from "react-router";
import { useAppDispatch, useAppSelector } from "../app/hooks.ts";
import {
  TaskPromptInput,
  type TaskPromptInputHandle,
} from "../components/task-prompt-input.tsx";
import {
  PromptInputButton,
  PromptInputTools,
} from "../components/ui/shadcn-io/ai/prompt-input.js";
import {
  Tooltip,
  TooltipContent,
  TooltipTrigger,
} from "../components/ui/tooltip.js";
import { WebSearchToggleTool } from "../components/web-search-toggle-tool.js";
import { useNewTaskMutation } from "../features/api/apiSlice.ts";
import {
  selectCwd,
  selectInput,
  selectWebSearchEnabled,
  setCwd,
  setInput,
  toggleWebSearchEnabled,
} from "../features/session/homeSlice.js";
import { setActiveTaskId, setTask } from "../features/session/tasksSlice.ts";
import { RAL } from "../lib/ral";
import { base } from "../lib/utils.js";

function WDSelector({ cwd }: { cwd: string | undefined }) {
  const dispatch = useAppDispatch();
  const baseCwd = cwd ? base(cwd) : undefined;
  const ral = RAL();

  return ral.platform === "electron" ? (
    <Tooltip>
      <TooltipTrigger asChild>
        <PromptInputButton
          className="cursor-pointer"
          onClick={async () => {
            const result = await ral.selectDirectory();
            if (result.canceled === false && result.filePaths.length > 0) {
              dispatch(setCwd(result.filePaths[0]));
            }
          }}
        >
          <Folder size={16} />
          {baseCwd && <span>{baseCwd}</span>}
          {baseCwd && (
            <button
              className="hover:text-destructive"
              onClick={(e) => {
                e.stopPropagation();
                dispatch(setCwd(undefined));
              }}
            >
              <X />
            </button>
          )}
        </PromptInputButton>
      </TooltipTrigger>
      <TooltipContent>
        <p>Choose a working directory</p>
      </TooltipContent>
    </Tooltip>
  ) : null;
}

export default function Home() {
  const input = useAppSelector(selectInput);
  const webSearchEnabled = useAppSelector(selectWebSearchEnabled);
  const cwd = useAppSelector(selectCwd);
  const navigate = useNavigate();
  const ref = useRef<TaskPromptInputHandle>(null);
  const ral = RAL();
  const [postNewTask] = useNewTaskMutation();
  const dispatch = useAppDispatch();

  useEffect(() => {
    if (ref.current) {
      ref.current.focus();
    }
  });

  useEffect(() => {
    dispatch(setActiveTaskId(undefined));
  }, [dispatch]);

  const handleSubmit = async () => {
    dispatch(setInput("")); // Clear input field
    if (ral.platform !== "vsc-webview") {
      // dont clear cwd for vsc-webview, it is fixed per workspace
      dispatch(setCwd(undefined)); // Clear cwd
    }
    const { data } = await postNewTask({
      message: input,
      cwd,
      web_search: webSearchEnabled,
    });
    if (data) {
      const { id } = data.task;
      dispatch(setTask(data.task));
      navigate(`/tasks/${id}`);
    } else {
      // TODO: handle error case
    }
  };

  return (
    <div className="relative m-auto flex min-h-0 w-full max-w-4xl flex-1 flex-col justify-end">
      <div className="p-4">
        <TaskPromptInput
          ref={ref}
          onChange={(value) => dispatch(setInput(value))}
          onSubmit={handleSubmit}
          placeholder="Input your task..."
          inputTools={
            <PromptInputTools>
              <WDSelector cwd={cwd} />
              <WebSearchToggleTool
                onClick={() => {
                  dispatch(toggleWebSearchEnabled());
                }}
                webSearchEnabled={webSearchEnabled}
              />
            </PromptInputTools>
          }
        />
      </div>
    </div>
  );
}
