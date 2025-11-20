import { useEffect, useState } from "react";
import { TaskPromptInput } from "@/components/task-prompt-input";
import { useNewTaskMutation } from "@/features/api/apiSlice";
import { useNavigate } from "react-router";
import { useAppDispatch } from "@/app/hooks";
import { setActiveTaskId } from "@/features/session/tasksSlice";
import { useRootTaskId } from "@/hooks/use-root-task-id";
import { useCwd } from "@/hooks/use-cwd";

function Home() {
  const [input, setInput] = useState("");
  const navigate = useNavigate();
  const [postNewTask] = useNewTaskMutation();
  const dispatch = useAppDispatch();
  const rootTaskId = useRootTaskId();
  const cwd = useCwd();

  useEffect(() => {
    if (rootTaskId) {
      navigate(`tasks/${rootTaskId}`);
    }
  }, [rootTaskId, navigate]);

  useEffect(() => {
    dispatch(setActiveTaskId(undefined));
  }, [dispatch]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setInput("");
    const res = await postNewTask({ message: input, cwd });
    if (res.data) {
      const { id } = res.data.task;
      navigate(`tasks/${id}`);
    }
  };

  return (
    <div className="flex-1 min-h-0 flex flex-col justify-end m-auto w-full max-w-4xl relative">
      <div className="p-4">
        <TaskPromptInput
          value={input}
          onChange={setInput}
          onSubmit={handleSubmit}
          placeholder="Input your task..."
        />
      </div>
    </div>
  );
}

export default Home;
