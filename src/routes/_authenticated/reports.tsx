import { createFileRoute } from "@tanstack/react-router";
import { ComingSoon } from "@/components/layout/coming-soon";

export const Route = createFileRoute("/_authenticated/reports")({
  component: () => (
    <ComingSoon
      title="التقارير"
      description="تقارير BOQ، تحليل الأسعار التفصيلي، المواد، العمالة، المعدات، الملخص التجاري — مع تصدير PDF و Excel."
    />
  ),
});
