import { useEffect, useState } from "react";
import {
  PromptInput,
  PromptInputSubmit,
  PromptInputTextarea,
  PromptInputToolbar,
  PromptInputTools,
} from "@/components/ai/prompt-input";
import { useNewTaskMutation } from "@/features/api/apiSlice";
import { useNavigate } from "react-router";
import { useAppDispatch } from "@/app/hooks";
import { newTask, setActiveTaskId } from "@/features/session/tasksSlice";

function Home() {
  const [input, setInput] = useState("");
  const navigate = useNavigate();
  const [postNewTask] = useNewTaskMutation();
  const dispatch = useAppDispatch();

  useEffect(() => {
    dispatch(setActiveTaskId(undefined));
  }, [dispatch]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setInput("");
    const res = await postNewTask(input);
    if (res.data) {
      const { id, name } = res.data.task;
      dispatch(newTask({ id: id, name }));
      navigate(`tasks/${id}`);
    }
  };

  return (
    <div className="flex-1 min-h-0 flex flex-col justify-end m-auto w-full max-w-4xl relative">
      <div className="p-4">
        <PromptInput
          className="max-w-4xl mx-auto shadow-lg hover:shadow-xl transition-shadow"
          onSubmit={handleSubmit}
        >
          <PromptInputTextarea
            className="text-base md:text-base min-h-[52px]"
            value={input}
            onFocus={(e) =>
              e.target.scrollIntoView({ behavior: "smooth", block: "center" })
            }
            onChange={(e) => setInput(e.target.value)}
            placeholder="Input your task..."
          />
          <PromptInputToolbar>
            <PromptInputTools></PromptInputTools>
            <PromptInputSubmit
              disabled={!input.trim()}
              status="ready"
              className="cursor-pointer transition-all"
            ></PromptInputSubmit>
          </PromptInputToolbar>
        </PromptInput>
      </div>
    </div>
  );
}

export default Home;
