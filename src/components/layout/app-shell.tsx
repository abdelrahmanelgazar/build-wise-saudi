import { useEffect, useState, type ReactNode } from "react";
import { Link, useRouter, useRouterState } from "@tanstack/react-router";
import {
  Calculator,
  LayoutDashboard,
  FileText,
  TrendingUp,
  Database,
  ShieldCheck,
  BarChart3,
  Sparkles,
  Settings,
  LogOut,
  Search,
  Building2,
  Check,
  ChevronsUpDown,
  FolderKanban,
} from "lucide-react";
import { supabase } from "@/integrations/supabase/client";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import { cn } from "@/lib/utils";
import { useQuery, useQueryClient } from "@tanstack/react-query";
import { toast } from "sonner";
import { Popover, PopoverContent, PopoverTrigger } from "@/components/ui/popover";
import { useActiveProjectId, setActiveProjectId } from "@/lib/active-project";

type NavItem = {
  to: string;
  label: string;
  icon: typeof LayoutDashboard;
  enabled: boolean;
};

const NAV: NavItem[] = [
  { to: "/dashboard", label: "لوحة التحكم", icon: LayoutDashboard, enabled: true },
  { to: "/projects", label: "المشاريع", icon: FileText, enabled: true },
  { to: "/boq", label: "جدول الكميات", icon: Calculator, enabled: true },
  { to: "/price-analysis", label: "تحليل الأسعار", icon: TrendingUp, enabled: true },
  { to: "/resources", label: "مكتبة البيانات", icon: Database, enabled: true },
  { to: "/financial", label: "المراجعة المالية", icon: ShieldCheck, enabled: false },
  { to: "/reports", label: "التقارير", icon: BarChart3, enabled: true },
  { to: "/ai-assistant", label: "مساعد الذكاء الاصطناعي", icon: Sparkles, enabled: false },
  { to: "/settings", label: "الإعدادات والصلاحيات", icon: Settings, enabled: false },
];

function ProjectSwitcher() {
  const [open, setOpen] = useState(false);
  const activeId = useActiveProjectId();
  const qc = useQueryClient();
  const { data: projects = [] } = useQuery({
    queryKey: ["project-switcher-projects"],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("projects")
        .select("id, name, client_name")
        .order("created_at", { ascending: false });
      if (error) throw error;
      return data as { id: string; name: string; client_name: string | null }[];
    },
  });

  // Auto-pick first project on first load
  useEffect(() => {
    if (!activeId && projects.length > 0) setActiveProjectId(projects[0].id);
  }, [activeId, projects]);

  const active = projects.find((p) => p.id === activeId);

  return (
    <Popover open={open} onOpenChange={setOpen}>
      <PopoverTrigger asChild>
        <Button
          variant="outline"
          className="h-9 w-full justify-between gap-2 px-3 text-right"
        >
          <FolderKanban className="h-3.5 w-3.5 text-primary shrink-0" />
          <span className="flex-1 truncate text-xs font-medium">
            {active?.name ?? (projects.length === 0 ? "أنشئ مشروعاً" : "اختر مشروعاً")}
          </span>
          <ChevronsUpDown className="h-3 w-3 text-muted-foreground shrink-0" />
        </Button>
      </PopoverTrigger>
      <PopoverContent className="w-64 p-1" align="start">
        <div className="max-h-72 overflow-auto">
          {projects.length === 0 && (
            <div className="p-3 text-center text-xs text-muted-foreground">
              لا توجد مشاريع بعد
            </div>
          )}
          {projects.map((p) => (
            <button
              key={p.id}
              onClick={() => {
                setActiveProjectId(p.id);
                // Invalidate all project-scoped queries
                qc.invalidateQueries({ queryKey: ["boq_items"] });
                qc.invalidateQueries({ queryKey: ["resources"] });
                qc.invalidateQueries({ queryKey: ["pa_items"] });
                qc.invalidateQueries({ queryKey: ["pa_markup"] });
                qc.invalidateQueries({ queryKey: ["dashboard-resources-count"] });
                qc.invalidateQueries({ queryKey: ["dashboard-boq-count"] });
                setOpen(false);
              }}
              className={cn(
                "flex w-full items-start justify-between gap-2 rounded-md px-2.5 py-2 text-right text-xs hover:bg-accent",
                p.id === activeId && "bg-primary/10 text-primary",
              )}
            >
              <div className="min-w-0 flex-1">
                <div className="truncate font-medium">{p.name}</div>
                {p.client_name && (
                  <div className="truncate text-[10px] text-muted-foreground">{p.client_name}</div>
                )}
              </div>
              {p.id === activeId && <Check className="h-3.5 w-3.5 shrink-0" />}
            </button>
          ))}
        </div>
        <div className="mt-1 border-t border-border pt-1">
          <Link
            to="/projects"
            onClick={() => setOpen(false)}
            className="block rounded-md px-2.5 py-2 text-center text-xs text-primary hover:bg-accent"
          >
            إدارة كل المشاريع ←
          </Link>
        </div>
      </PopoverContent>
    </Popover>
  );
}

export function AppShell({ children }: { children: ReactNode }) {
  const router = useRouter();
  const queryClient = useQueryClient();
  const pathname = useRouterState({ select: (s) => s.location.pathname });
  const [email, setEmail] = useState<string>("");

  useEffect(() => {
    supabase.auth.getUser().then(({ data }) => setEmail(data.user?.email ?? ""));
  }, []);

  async function handleSignOut() {
    await queryClient.cancelQueries();
    queryClient.clear();
    await supabase.auth.signOut();
    router.navigate({ to: "/auth", replace: true });
  }

  return (
    <div className="flex min-h-screen w-full bg-background text-foreground">
      {/* Sidebar (right side for RTL) */}
      <aside className="sticky top-0 flex h-screen w-64 shrink-0 flex-col border-l border-sidebar-border bg-sidebar">
        <div className="flex h-14 items-center gap-2.5 border-b border-sidebar-border px-4">
          <div className="flex h-8 w-8 items-center justify-center rounded-md bg-primary/15 ring-1 ring-primary/30">
            <Calculator className="h-4 w-4 text-primary" />
          </div>
          <div className="leading-tight">
            <div className="text-sm font-bold text-sidebar-foreground">تقديري</div>
            <div className="text-[10px] text-muted-foreground">منصة التسعير الاحترافية</div>
          </div>
        </div>

        <div className="border-b border-sidebar-border p-2">
          <ProjectSwitcher />
        </div>

        <nav className="flex-1 overflow-y-auto p-2">
          <ul className="space-y-0.5">
            {NAV.map((item) => {
              const Icon = item.icon;
              const active = pathname.startsWith(item.to);
              return (
                <li key={item.to}>
                  <Link
                    to={item.to}
                    onClick={(e) => {
                      if (!item.enabled) {
                        e.preventDefault();
                        toast.info(`${item.label} — قيد التطوير في المرحلة التالية`);
                      }
                    }}
                    className={cn(
                      "group flex items-center justify-between gap-2 rounded-md px-3 py-2 text-sm transition-colors",
                      active && item.enabled
                        ? "bg-primary/15 text-primary ring-1 ring-primary/20"
                        : "text-sidebar-foreground hover:bg-sidebar-accent",
                      !item.enabled && "opacity-60",
                    )}
                  >
                    <div className="flex items-center gap-2.5">
                      <Icon className="h-4 w-4 shrink-0" />
                      <span>{item.label}</span>
                    </div>
                    {!item.enabled && (
                      <Badge
                        variant="outline"
                        className="h-5 border-border/60 px-1.5 text-[9px] font-normal text-muted-foreground"
                      >
                        قريباً
                      </Badge>
                    )}
                  </Link>
                </li>
              );
            })}
          </ul>
        </nav>

        <div className="border-t border-sidebar-border p-3">
          <div className="mb-2 flex items-center gap-2 rounded-md bg-card/50 px-2.5 py-2">
            <div className="flex h-7 w-7 items-center justify-center rounded-full bg-primary/20 text-xs font-semibold text-primary">
              {email.charAt(0).toUpperCase() || "U"}
            </div>
            <div className="min-w-0 flex-1 leading-tight">
              <div className="truncate text-xs font-medium text-sidebar-foreground">
                {email || "مستخدم"}
              </div>
              <div className="text-[10px] text-muted-foreground">مدير التسعير</div>
            </div>
          </div>
          <Button
            variant="ghost"
            size="sm"
            onClick={handleSignOut}
            className="w-full justify-start gap-2 text-muted-foreground hover:text-foreground"
          >
            <LogOut className="h-4 w-4" />
            تسجيل الخروج
          </Button>
        </div>
      </aside>

      {/* Main area */}
      <div className="flex min-w-0 flex-1 flex-col">
        <header className="sticky top-0 z-30 flex h-14 items-center gap-3 border-b border-border bg-background/80 px-6 backdrop-blur">
          <div className="relative flex-1 max-w-md">
            <Search className="pointer-events-none absolute right-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
            <Input
              placeholder="البحث الموحّد قريباً…"
              disabled
              className="h-9 pr-9 text-sm"
              title="ميزة البحث الموحّد قيد التطوير"
            />
          </div>
          <div className="flex items-center gap-2">
            <Badge
              variant="outline"
              className="hidden h-7 gap-1.5 border-primary/30 bg-primary/10 text-primary md:flex"
            >
              <Sparkles className="h-3 w-3" />
              مساعد الذكاء الاصطناعي
            </Badge>
            <Badge variant="outline" className="h-7 gap-1.5 border-border/60">
              <Building2 className="h-3 w-3" />
              السوق السعودي
            </Badge>
          </div>
        </header>

        <main className="flex-1 overflow-auto">{children}</main>
      </div>
    </div>
  );
}
