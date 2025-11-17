"use client";

import { ChevronRight } from "lucide-react";

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
import type { NamedId } from "@/lib/types";
import { useNavigate } from "react-router";
import { useAppSelector } from "@/app/hooks";
import { selectActiveTaskId } from "@/features/session/tasksSlice";

export function NavTasks({ tasks }: { tasks: NamedId[] }) {
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
            {tasks.map(({ name, id }) => {
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
                      <span>{name}</span>
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
