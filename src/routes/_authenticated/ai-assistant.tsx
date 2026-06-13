import { createFileRoute } from "@tanstack/react-router";
import { ComingSoon } from "@/components/layout/coming-soon";

export const Route = createFileRoute("/_authenticated/ai-assistant")({
  component: () => (
    <ComingSoon
      title="مساعد الذكاء الاصطناعي"
      description="قراءة ملفات BOQ، اقتراح أسعار البنود، كشف البنود الناقصة، حساب الربح، وإنشاء تحليل الأسعار تلقائياً عبر Lovable AI."
    />
  ),
});
