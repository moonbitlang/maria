import { useEventsQuery } from "@maria/core/features/api/apiSlice.ts";
import { Outlet } from "react-router";

export default function Layout() {
  useEventsQuery();
  return (
    <div className="flex h-full min-h-0 flex-col overflow-x-hidden">
      <Outlet />
    </div>
  );
}
