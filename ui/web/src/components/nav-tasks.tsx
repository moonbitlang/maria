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
import { Link } from "react-router";
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
  const { isMobile, setOpenMobile } = useSidebar();
  return (
    <Collapsible defaultOpen className="group/collapsible">
      <SidebarGroup className="group-data-[collapsible=icon]:hidden">
        <SidebarGroupLabel className="text-base opacity-60 font-normal" asChild>
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
                    <Link to={url}>
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
