import { createFileRoute } from "@tanstack/react-router";
import { ComingSoon } from "@/components/layout/coming-soon";

export const Route = createFileRoute("/_authenticated/settings")({
  component: () => (
    <ComingSoon
      title="الإعدادات والصلاحيات"
      description="إدارة المستخدمين والأدوار: مدير عام، مدير تسعير، مُسعّر، مُشاهد فقط (RBAC)."
    />
  ),
});
