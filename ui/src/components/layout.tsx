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
      <SidebarInset className="flex flex-col h-screen">
        {/* TODO: hide the header on desktop screen, move it to sidebar */}
        <header className="flex h-8 shrink-0 items-center px-4 py-3">
          <SidebarTrigger className="-ml-1" />
        </header>
        <main className="flex flex-1 flex-col min-h-0">{children}</main>
      </SidebarInset>
    </SidebarProvider>
  );
}
