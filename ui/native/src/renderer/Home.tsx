import { useAppDispatch, useAppSelector } from "@maria/core/app/hooks.ts";
import {
  TaskPromptInput,
  type TaskPromptInputHandle,
} from "@maria/core/components/task-prompt-input.tsx";
import {
  PromptInputButton,
  PromptInputTools,
} from "@maria/core/components/ui/shadcn-io/ai/prompt-input.js";
import {
  Tooltip,
  TooltipContent,
  TooltipTrigger,
} from "@maria/core/components/ui/tooltip.js";
import { WebSearchToggleTool } from "@maria/core/components/web-search-toggle-tool.js";
import { useNewTaskMutation } from "@maria/core/features/api/apiSlice.ts";
import {
  selectCwd,
  selectInput,
  selectWebSearchEnabled,
  setCwd,
  setInput,
  toggleWebSearchEnabled,
} from "@maria/core/features/session/homeSlice.js";
import {
  setActiveTaskId,
  setTask,
} from "@maria/core/features/session/tasksSlice.ts";
import { base } from "@maria/core/lib/utils.js";
import { Folder, X } from "lucide-react";
import { useEffect, useRef } from "react";
import { useNavigate } from "react-router";

export default function Home() {
  const input = useAppSelector(selectInput);
  const cwd = useAppSelector(selectCwd);
  const webSearchEnabled = useAppSelector(selectWebSearchEnabled);
  const baseCwd = cwd ? base(cwd) : undefined;
  const navigate = useNavigate();
  const ref = useRef<TaskPromptInputHandle>(null);
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
    dispatch(setCwd(undefined)); // Clear cwd
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
              <Tooltip>
                <TooltipTrigger asChild>
                  <PromptInputButton
                    className="cursor-pointer"
                    onClick={async () => {
                      const result = await window.electronAPI.selectDirectory();
                      if (
                        result.canceled === false &&
                        result.filePaths.length > 0
                      ) {
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
                <WebSearchToggleTool
                  onClick={() => {
                    dispatch(toggleWebSearchEnabled());
                  }}
                  webSearchEnabled={webSearchEnabled}
                />
              </Tooltip>
            </PromptInputTools>
          }
        />
      </div>
    </div>
  );
}
