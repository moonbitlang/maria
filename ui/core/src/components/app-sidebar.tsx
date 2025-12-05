import { SquareTerminal } from "lucide-react";
import * as React from "react";

import { Link } from "react-router";
import type { Task } from "../lib/types";
import { NavTasks } from "./nav-tasks";
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

type AppSidebarProps = React.ComponentProps<typeof Sidebar> & {
  activeTaskId?: string;
  tasks: Task[];
  footer?: React.ReactNode;
};

export function AppSidebar(props: AppSidebarProps) {
  const { activeTaskId, tasks, footer, ...sidebarProps } = props;
  const { isMobile, setOpenMobile } = useSidebar();

  return (
    <Sidebar collapsible="icon" {...sidebarProps}>
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
      <SidebarFooter>{footer}</SidebarFooter>
      <SidebarRail />
    </Sidebar>
  );
}
