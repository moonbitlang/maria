import { useEffect } from "react";
import { useNavigate } from "react-router";
import { useAppDispatch, useAppSelector } from "../app/hooks.ts";
import { TaskPromptInput } from "../components/task-prompt-input.tsx";
import { useNewTaskMutation } from "../features/api/apiSlice.ts";
import { selectInput, setInput } from "../features/session/homeSlice.ts";
import { setActiveTaskId } from "../features/session/tasksSlice.ts";

type HomeProps = {
  cwd?: string;
};

export default function Home({ cwd }: HomeProps) {
  const input = useAppSelector(selectInput);
  const navigate = useNavigate();
  const [postNewTask] = useNewTaskMutation();
  const dispatch = useAppDispatch();

  useEffect(() => {
    dispatch(setActiveTaskId(undefined));
  }, [dispatch]);

  const handleSubmit = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    dispatch(setInput("")); // Clear input field
    const res = await postNewTask({ message: input, cwd });
    if (res.data) {
      const { id } = res.data.task;
      navigate(`/tasks/${id}`);
    }
  };

  return (
    <div className="relative m-auto flex min-h-0 w-full max-w-4xl flex-1 flex-col justify-end">
      <div className="p-4">
        <TaskPromptInput
          value={input}
          onChange={(value) => dispatch(setInput(value))}
          onSubmit={handleSubmit}
          placeholder="Input your task..."
        />
      </div>
    </div>
  );
}
