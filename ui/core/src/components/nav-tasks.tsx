import { CheckCircle2, ChevronRight, Loader2 } from "lucide-react";

import { Link } from "react-router";
import type { Status, Task } from "../lib/types";
import {
  Collapsible,
  CollapsibleContent,
  CollapsibleTrigger,
} from "./ui/collapsible";
import {
  SidebarGroup,
  SidebarGroupLabel,
  SidebarMenu,
  SidebarMenuButton,
  SidebarMenuItem,
  useSidebar,
} from "./ui/sidebar";

export function getTaskIcon(status: Status) {
  switch (status) {
    case "generating":
      return <Loader2 className="ml-auto h-4 w-4 animate-spin" />;
    case "idle":
      return <CheckCircle2 className="ml-auto h-4 w-4 text-green-600" />;
  }
}

type NavTasksProps = {
  activeTaskId?: string;
  tasks: Task[];
};

export function NavTasks(props: NavTasksProps) {
  const { activeTaskId, tasks } = props;
  const { isMobile, setOpenMobile } = useSidebar();
  return (
    <Collapsible defaultOpen className="group/collapsible">
      <SidebarGroup className="group-data-[collapsible=icon]:hidden">
        <SidebarGroupLabel className="text-base font-normal opacity-60" asChild>
          <CollapsibleTrigger className="cursor-pointer">
            Tasks
            <ChevronRight className="ml-auto transition-transform duration-200 group-data-[state=open]/collapsible:rotate-90" />
          </CollapsibleTrigger>
        </SidebarGroupLabel>
        <CollapsibleContent>
          <SidebarMenu>
            {tasks.map(({ name, id, status }) => {
              const path = `/tasks/${id}`;
              const isActive = activeTaskId === id;
              return (
                <SidebarMenuItem key={id}>
                  <SidebarMenuButton
                    className="text-base"
                    tooltip={name}
                    asChild
                    isActive={isActive}
                    onClick={() => {
                      if (isMobile) {
                        setOpenMobile(false);
                      }
                    }}
                  >
                    <Link to={path}>
                      <span className="truncate">{name}</span>
                      {getTaskIcon(status)}
                    </Link>
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
