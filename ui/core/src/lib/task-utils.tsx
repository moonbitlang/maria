import type { Status } from "@maria/core/lib/types.ts";
import { CheckCircle2, Loader2 } from "lucide-react";

export function getTaskIcon(status: Status) {
  switch (status) {
    case "generating":
      return <Loader2 className="ml-auto h-4 w-4 animate-spin" />;
    case "idle":
      return <CheckCircle2 className="ml-auto h-4 w-4 text-green-600" />;
  }
}
