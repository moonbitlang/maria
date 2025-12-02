import { useAppSelector } from "@maria/core/app/hooks.ts";
import { AppSidebar } from "@maria/core/components/app-sidebar.tsx";
import {
  SidebarInset,
  SidebarProvider,
  SidebarTrigger,
} from "@maria/core/components/ui/sidebar.tsx";
import { useEventsQuery } from "@maria/core/features/api/apiSlice.ts";
import {
  selectActiveTaskId,
  selectTasks,
} from "@maria/core/features/session/tasksSlice.ts";
import { Outlet } from "react-router";

function Sidebar({ className }: { className?: string }) {
  const activeTaskId = useAppSelector(selectActiveTaskId);
  const tasks = useAppSelector(selectTasks);
  return (
    <AppSidebar
      className={className}
      activeTaskId={activeTaskId}
      tasks={tasks}
    />
  );
}

export function Layout() {
  useEventsQuery();
  return (
    <SidebarProvider>
      <Sidebar className="overflow-x-hidden" />
      <SidebarInset className="flex h-dvh flex-col overflow-x-hidden">
        {/* TODO: hide the header on desktop screen, move it to sidebar */}
        <header className="bg-background/95 supports-backdrop-filter:bg-background/60 sticky top-0 z-10 flex items-center border-b backdrop-blur md:hidden">
          <div className="flex w-full items-center gap-3 px-4 py-3">
            <SidebarTrigger className="scale-150" />
            <h1 className="text-xl font-semibold tracking-tight">
              MoonBit Agent
            </h1>
          </div>
        </header>
        {/* <main className="flex-1 min-h-0 flex flex-col">
          <div className="flex-1 min-h-0 overflow-y-auto bg-red-50">
            <div className="bg-black overflow-x-auto">
              <div className="bg-yellow-50 w-[400px] h-[400px]">children</div>
            </div>
          </div>
          <div className="h-[100px] bg-blue-50"></div>
        </main> */}
        <div className="flex min-h-0 flex-1 flex-col">
          <Outlet />
        </div>
      </SidebarInset>
    </SidebarProvider>
  );
}
