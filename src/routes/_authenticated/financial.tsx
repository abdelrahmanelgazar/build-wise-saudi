import { createFileRoute } from "@tanstack/react-router";
import { ComingSoon } from "@/components/layout/coming-soon";

export const Route = createFileRoute("/_authenticated/financial")({
  component: () => (
    <ComingSoon
      title="المراجعة المالية"
      description="ملخص شامل قبل تسليم العطاء: التكلفة المباشرة وغير المباشرة، المخاطر، الربح، وضريبة القيمة المضافة 15%."
    />
  ),
});
