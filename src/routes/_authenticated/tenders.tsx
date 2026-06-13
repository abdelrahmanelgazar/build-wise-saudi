import { createFileRoute } from "@tanstack/react-router";
import { ComingSoon } from "@/components/layout/coming-soon";

export const Route = createFileRoute("/_authenticated/tenders")({
  component: () => (
    <ComingSoon
      title="المشاريع"
      description="إنشاء المشاريع، متابعة حالاتها (جاري الدراسة، التسعير، التسليم، الفوز/الخسارة)، وإدارة المالك والاستشاري وقيمة الضمان."
    />
  ),
});
