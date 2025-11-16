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
} from "@/components/ui/sidebar";
import { NavTasks } from "./nav-tasks";
import { useNavigate } from "react-router";
import { useTasksQuery } from "@/features/api/apiSlice";

export function AppSidebar({ ...props }: React.ComponentProps<typeof Sidebar>) {
  const navigate = useNavigate();
  const { data, isSuccess } = useTasksQuery();
  const tasks = isSuccess ? data.tasks : [];

  return (
    <Sidebar collapsible="icon" {...props}>
      <SidebarHeader></SidebarHeader>
      <SidebarContent>
        <SidebarGroup>
          <SidebarMenu>
            <SidebarMenuItem key={"New Task"}>
              <SidebarMenuButton
                tooltip={"New Task"}
                isActive={true}
                onClick={(e) => {
                  e.preventDefault();
                  navigate("/");
                }}
                asChild
              >
                <a href={"/"}>
                  <SquareTerminal />
                  <span>{"New Task"}</span>
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
