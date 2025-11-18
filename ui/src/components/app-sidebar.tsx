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
import { useNavigate } from "react-router";
import { useAppSelector } from "@/app/hooks";
import { selectActiveTaskId, selectTasks } from "@/features/session/tasksSlice";

export function AppSidebar({ ...props }: React.ComponentProps<typeof Sidebar>) {
  const navigate = useNavigate();
  const activeTaskId = useAppSelector(selectActiveTaskId);
  const tasks = useAppSelector(selectTasks);
  const { isMobile, setOpenMobile } = useSidebar();

  return (
    <Sidebar collapsible="icon" {...props}>
      <SidebarHeader></SidebarHeader>
      <SidebarContent>
        <SidebarGroup>
          <SidebarMenu>
            <SidebarMenuItem key="New Task">
              <SidebarMenuButton
                tooltip="New Task"
                isActive={activeTaskId === undefined}
                onClick={(e) => {
                  e.preventDefault();
                  navigate("/");
                  if (isMobile) {
                    setOpenMobile(false);
                  }
                }}
                asChild
              >
                <a href="/">
                  <SquareTerminal />
                  <span>New Task</span>
                </a>
              </SidebarMenuButton>
            </SidebarMenuItem>
          </SidebarMenu>
        </SidebarGroup>
        <NavTasks tasks={tasks} />
      </SidebarContent>
      <SidebarFooter></SidebarFooter>
      <SidebarRail />
    </Sidebar>
  );
}
