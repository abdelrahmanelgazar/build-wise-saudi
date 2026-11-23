import { createFileRoute, Outlet } from "@tanstack/react-router";
import { supabase } from "@/integrations/supabase/client";
import { AppShell } from "@/components/layout/app-shell";

export const Route = createFileRoute("/_authenticated")({
  ssr: false,
  beforeLoad: async () => {
    try {
      const { data } = await supabase.auth.getUser();
      if (data?.user) return { user: data.user };
    } catch {
      // ignore
    }
    // Bypass protection for local preview / easy testing
    return {
      user: {
        id: "preview-user-id",
        email: "demo@buildwise.sa",
        user_metadata: { name: "مستخدم تجريبي" },
      },
    };
  },
  component: () => (
    <AppShell>
      <Outlet />
    </AppShell>
  ),
});
