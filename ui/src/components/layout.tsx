import {
  SidebarInset,
  SidebarProvider,
  SidebarTrigger,
} from "@/components/ui/sidebar";
import { AppSidebar } from "@/components/app-sidebar";

export function Layout({ children }: { children: React.ReactNode }) {
  return (
    <SidebarProvider>
      <AppSidebar />
      <SidebarInset className="flex flex-col h-screen overflow-x-hidden">
        {/* TODO: hide the header on desktop screen, move it to sidebar */}
        <header className="flex items-center">
          <SidebarTrigger />
        </header>
        {/* <main className="flex-1 min-h-0 flex flex-col">
          <div className="flex-1 min-h-0 overflow-y-auto bg-red-50">
            <div className="bg-black overflow-x-auto">
              <div className="bg-yellow-50 w-[400px] h-[400px]">children</div>
            </div>
          </div>
          <div className="h-[100px] bg-blue-50"></div>
        </main> */}
        <main className="flex-1 min-h-0 flex flex-col">{children}</main>
      </SidebarInset>
    </SidebarProvider>
  );
}
