import type { Status } from "@maria/core/lib/types.ts";
import { CheckCircle2, Loader2 } from "lucide-react";

export function getTaskIcon(status: Status) {
  switch (status) {
    case "generating":
      return <Loader2 className="h-4 w-4 ml-auto animate-spin" />;
    case "idle":
      return <CheckCircle2 className="h-4 w-4 ml-auto text-green-600" />;
  }
}
