import { useAppSelector } from "@/app/hooks";
import { selectTasks } from "@/features/session/tasksSlice";
import type { TaskOverview } from "@/lib/types";
import {
  Card,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { ScrollArea } from "@/components/ui/scroll-area";
import { Clock, Folder } from "lucide-react";
import { useNavigate } from "react-router";
import { getTaskIcon } from "@/lib/task-utils";

function formatDate(timestamp: number) {
  const date = new Date(timestamp * 1000);
  const now = new Date();
  const diffInMs = now.getTime() - date.getTime();
  const diffInMinutes = Math.floor(diffInMs / 60000);
  const diffInHours = Math.floor(diffInMs / 3600000);
  const diffInDays = Math.floor(diffInMs / 86400000);

  if (diffInMinutes < 1) return "just now";
  if (diffInMinutes < 60) return `${diffInMinutes}m ago`;
  if (diffInHours < 24) return `${diffInHours}h ago`;
  if (diffInDays < 7) return `${diffInDays}d ago`;

  return date.toLocaleDateString();
}

export default function AllTasks() {
  const tasks: TaskOverview[] = useAppSelector(selectTasks);
  const navigate = useNavigate();

  const handleTaskClick = (taskId: string) => {
    navigate(`/tasks/${taskId}`);
  };

  return (
    <div className="flex-1 min-h-0 flex flex-col m-auto w-full max-w-4xl">
      <ScrollArea className="flex-1">
        <div className="p-6 space-y-4">
          <div>
            <h1 className="text-3xl font-bold tracking-tight">All Tasks</h1>
            <p className="text-muted-foreground mt-2">
              {tasks.length === 0
                ? "No tasks yet."
                : `${tasks.length} ${
                    tasks.length === 1 ? "task" : "tasks"
                  } in total`}
            </p>
          </div>

          {
            <div className="space-y-3">
              {tasks.map((task) => (
                <Card
                  key={task.id}
                  className="cursor-pointer transition-colors hover:bg-accent/50"
                  onClick={() => handleTaskClick(task.id)}
                >
                  <CardHeader>
                    <div className="flex items-start justify-between gap-4">
                      <div className="flex-1 min-w-0">
                        <CardTitle className="text-lg line-clamp-2">
                          {task.name}
                        </CardTitle>
                        <CardDescription className="mt-2 flex flex-wrap items-center gap-3">
                          <span className="flex items-center gap-1">
                            <Clock className="h-3 w-3" />
                            {formatDate(task.created)}
                          </span>
                          <span className="flex items-center gap-1">
                            <Folder className="h-3 w-3" />
                            <span
                              className="truncate max-w-[200px]"
                              title={task.cwd}
                            >
                              {task.cwd}
                            </span>
                          </span>
                        </CardDescription>
                      </div>
                      {getTaskIcon(task.status)}
                    </div>
                  </CardHeader>
                </Card>
              ))}
            </div>
          }
        </div>
      </ScrollArea>
    </div>
  );
}
