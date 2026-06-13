import { createFileRoute } from "@tanstack/react-router";
import { ComingSoon } from "@/components/layout/coming-soon";

export const Route = createFileRoute("/_authenticated/dashboard")({
  component: () => (
    <ComingSoon
      title="لوحة التحكم"
      description="مؤشرات الأداء الرئيسية، الرسوم البيانية للتكاليف الشهرية، نسبة الفوز/الخسارة، وتوزيع المشاريع."
    />
  ),
});
