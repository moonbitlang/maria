"use client";

import { ChevronRight, Loader2 } from "lucide-react";

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
import { selectActiveTaskId } from "@/features/session/tasksSlice";
import type { TaskOverview } from "@/features/api/apiSlice";

export function NavTasks({ tasks }: { tasks: TaskOverview[] }) {
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
            {tasks.map(({ name, id, conversationStatus }) => {
              const url = `tasks/${id}`;
              const isActive = activeTaskId === id;
              const isGenerating = conversationStatus === "generating";
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
                      <span>{name}</span>
                      {isGenerating && (
                        <Loader2 className="ml-auto h-4 w-4 animate-spin" />
                      )}
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
