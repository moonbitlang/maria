import {
  SidebarInset,
  SidebarProvider,
  SidebarTrigger,
} from "@/components/ui/sidebar";
import { AppSidebar } from "@/components/app-sidebar";
import { Outlet } from "react-router";
import { useEventsQuery } from "@/features/api/apiSlice";

export function Layout() {
  useEventsQuery();
  return (
    <SidebarProvider>
      <AppSidebar className="overflow-x-hidden" />
      <SidebarInset className="flex flex-col h-dvh overflow-x-hidden">
        {/* TODO: hide the header on desktop screen, move it to sidebar */}
        <header className="sticky top-0 z-10 flex items-center border-b bg-background/95 backdrop-blur supports-backdrop-filter:bg-background/60 md:hidden">
          <div className="flex items-center gap-3 px-4 py-3 w-full">
            <SidebarTrigger className="scale-150" />
            <h1 className="font-semibold text-xl tracking-tight">Moon Agent</h1>
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
        <div className="flex-1 min-h-0 flex flex-col">
          <Outlet />
        </div>
      </SidebarInset>
    </SidebarProvider>
  );
}
