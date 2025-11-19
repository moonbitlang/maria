import * as React from "react";
import { SquareTerminal } from "lucide-react";

import {
  Sidebar,
  SidebarContent,
  SidebarFooter,
  SidebarGroup,
  SidebarHeader,
  SidebarMenu,
  SidebarMenuButton,
  SidebarMenuItem,
  SidebarRail,
  useSidebar,
} from "@/components/ui/sidebar";
import { NavTasks } from "./nav-tasks";
import { Link } from "react-router";
import { useAppSelector } from "@/app/hooks";
import { selectActiveTaskId } from "@/features/session/tasksSlice";

export function AppSidebar({ ...props }: React.ComponentProps<typeof Sidebar>) {
  const activeTaskId = useAppSelector(selectActiveTaskId);
  const { isMobile, setOpenMobile } = useSidebar();

  return (
    <Sidebar collapsible="icon" {...props}>
      <SidebarHeader></SidebarHeader>
      <SidebarContent>
        <SidebarGroup>
          <SidebarMenu>
            <SidebarMenuItem key="New Task">
              <SidebarMenuButton
                className="text-base"
                tooltip="New Task"
                isActive={activeTaskId === undefined}
                onClick={() => {
                  if (isMobile) {
                    setOpenMobile(false);
                  }
                }}
                asChild
              >
                <Link to="/">
                  <SquareTerminal />
                  <span>New Task</span>
                </Link>
              </SidebarMenuButton>
            </SidebarMenuItem>
          </SidebarMenu>
        </SidebarGroup>
        <NavTasks />
      </SidebarContent>
      <SidebarFooter></SidebarFooter>
      <SidebarRail />
    </Sidebar>
  );
}
