import { useEffect, type FormEvent } from "react";
import { TaskPromptInput } from "@maria/core/components/task-prompt-input.tsx";
import { useNewTaskMutation } from "@maria/core/features/api/apiSlice.ts";
import { useNavigate } from "react-router";
import { useAppDispatch, useAppSelector } from "@maria/core/app/hooks.ts";
import { setActiveTaskId } from "@maria/core/features/session/tasksSlice.ts";
import {
  PromptInputButton,
  PromptInputTools,
} from "@maria/core/components/ui/shadcn-io/ai/prompt-input.js";
import { Folder, X } from "lucide-react";
import {
  Tooltip,
  TooltipContent,
  TooltipTrigger,
} from "@maria/core/components/ui/tooltip.js";
import {
  selectCwd,
  selectInput,
  setCwd,
  setInput,
} from "@maria/core/features/session/homeSlice.js";
import { base } from "@maria/core/lib/utils.js";

export default function Home() {
  const input = useAppSelector(selectInput);
  const cwd = useAppSelector(selectCwd);
  const baseCwd = cwd ? base(cwd) : undefined;
  const navigate = useNavigate();
  const [postNewTask] = useNewTaskMutation();
  const dispatch = useAppDispatch();

  useEffect(() => {
    dispatch(setActiveTaskId(undefined));
  }, [dispatch]);

  const handleSubmit = async (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    dispatch(setInput("")); // Clear input field
    dispatch(setCwd(undefined)); // Clear cwd
    const { data } = await postNewTask({ message: input, cwd });
    if (data) {
      const { id } = data.task;
      navigate(`/tasks/${id}`);
    }
  };

  return (
    <div className="flex-1 min-h-0 flex flex-col justify-end m-auto w-full max-w-4xl relative">
      <div className="p-4">
        <TaskPromptInput
          value={input}
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
              </Tooltip>
            </PromptInputTools>
          }
        />
      </div>
    </div>
  );
}
