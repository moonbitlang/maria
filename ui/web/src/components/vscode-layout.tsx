import { Outlet } from "react-router";

export default function VscodeLayout() {
  return (
    <div className="flex flex-col min-h-0 h-full overflow-x-hidden">
      <Outlet />
    </div>
  );
}
