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
} from "./ui/sidebar";
import { NavTasks } from "./nav-tasks";
import { Link } from "react-router";
import type { Task } from "../lib/types";

type AppSidebarProps = React.ComponentProps<typeof Sidebar> & {
  activeTaskId?: string;
  tasks: Task[];
};

export function AppSidebar(props: AppSidebarProps) {
  const { activeTaskId, tasks } = props;
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
        <NavTasks activeTaskId={activeTaskId} tasks={tasks} />
      </SidebarContent>
      <SidebarFooter></SidebarFooter>
      <SidebarRail />
    </Sidebar>
  );
}
