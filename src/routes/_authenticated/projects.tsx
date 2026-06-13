import { createFileRoute, Outlet } from "@tanstack/react-router";

export const Route = createFileRoute("/_authenticated/projects")({
  head: () => ({ meta: [{ title: "المشاريع — تقديري" }] }),
  component: () => <Outlet />,
});
