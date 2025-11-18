"use client";

import { CheckCircle2, ChevronRight, Loader2 } from "lucide-react";

import {
  SidebarGroup,
  SidebarGroupLabel,
  SidebarMenu,
  SidebarMenuButton,
  SidebarMenuItem,
  useSidebar,
} from "@/components/ui/sidebar";
import {
  Collapsible,
  CollapsibleContent,
  CollapsibleTrigger,
} from "@/components/ui/collapsible";
import { useNavigate } from "react-router";
import { useAppSelector } from "@/app/hooks";
import { selectActiveTaskId, selectTasks } from "@/features/session/tasksSlice";
import type { Status } from "@/lib/types";

function getTaskIcon(status: Status) {
  switch (status) {
    case "generating":
      return <Loader2 className="h-4 w-4 ml-auto animate-spin" />;
    case "idle":
      return <CheckCircle2 className="h-4 w-4 ml-auto text-green-600" />;
  }
}

export function NavTasks() {
  const tasks = useAppSelector(selectTasks);
  const activeTaskId = useAppSelector(selectActiveTaskId);
  const navigate = useNavigate();
  const { isMobile, setOpenMobile } = useSidebar();
  return (
    <Collapsible defaultOpen className="group/collapsible">
      <SidebarGroup className="group-data-[collapsible=icon]:hidden">
        <SidebarGroupLabel asChild>
          <CollapsibleTrigger className="cursor-pointer">
            Tasks
            <ChevronRight className="ml-auto transition-transform duration-200 group-data-[state=open]/collapsible:rotate-90" />
          </CollapsibleTrigger>
        </SidebarGroupLabel>
        <CollapsibleContent>
          <SidebarMenu>
            {tasks.map(({ name, id, status }) => {
              const url = `tasks/${id}`;
              const isActive = activeTaskId === id;
              return (
                <SidebarMenuItem key={id}>
                  <SidebarMenuButton
                    tooltip={name}
                    asChild
                    isActive={isActive}
                    onClick={(e) => {
                      e.preventDefault();
                      navigate(url);
                      if (isMobile) {
                        setOpenMobile(false);
                      }
                    }}
                  >
                    <a href={url}>
                      <span className="truncate">{name}</span>
                      {getTaskIcon(status)}
                    </a>
                  </SidebarMenuButton>
                </SidebarMenuItem>
              );
            })}
          </SidebarMenu>
        </CollapsibleContent>
      </SidebarGroup>
    </Collapsible>
  );
}
