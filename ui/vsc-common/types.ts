export type Status = "idle" | "generating";

export type TaskOverview = {
  id: string;
  name: string;
  status: Status;
  created: number;
  cwd: string;
};
