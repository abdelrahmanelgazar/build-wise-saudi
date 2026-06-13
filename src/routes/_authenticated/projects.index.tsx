import { createFileRoute, Link } from "@tanstack/react-router";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useState } from "react";
import { supabase } from "@/integrations/supabase/client";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import { Label } from "@/components/ui/label";
import {
  Dialog,
  DialogContent,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { ChevronLeft, FolderPlus, Plus, Search, Trash2 } from "lucide-react";
import { fmtSAR } from "@/lib/format";
import { toast } from "sonner";
import { setActiveProjectId } from "@/lib/active-project";
import type { Database } from "@/integrations/supabase/types";

type Project = Database["public"]["Tables"]["projects"]["Row"];
type Status = Database["public"]["Enums"]["project_status"];

const STATUS_META: Record<Status, { label: string; cls: string }> = {
  draft: { label: "مسودة", cls: "bg-muted/60 text-muted-foreground border-border/60" },
  in_progress: { label: "جاري", cls: "bg-primary/15 text-primary border-primary/30" },
  awarded: { label: "مرسي", cls: "bg-emerald-500/15 text-emerald-500 border-emerald-500/30" },
  rejected: { label: "مرفوض", cls: "bg-red-500/15 text-red-500 border-red-500/30" },
  completed: { label: "منتهي", cls: "bg-blue-500/15 text-blue-500 border-blue-500/30" },
};

export const Route = createFileRoute("/_authenticated/projects/")({
  component: ProjectsIndex,
});

function ProjectsIndex() {
  const qc = useQueryClient();
  const [search, setSearch] = useState("");
  const [statusFilter, setStatusFilter] = useState<Status | "all">("all");

  const { data: projects = [], isLoading } = useQuery({
    queryKey: ["projects"],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("projects")
        .select("*")
        .order("created_at", { ascending: false });
      if (error) throw error;
      return data as Project[];
    },
  });

  const delMut = useMutation({
    mutationFn: async (id: string) => {
      const { error } = await supabase.from("projects").delete().eq("id", id);
      if (error) throw error;
    },
    onSuccess: () => {
      toast.success("تم حذف المشروع");
      qc.invalidateQueries({ queryKey: ["projects"] });
    },
    onError: (e: Error) => toast.error(e.message),
  });

  const filtered = projects
    .filter((p) => statusFilter === "all" || p.status === statusFilter)
    .filter(
      (p) =>
        !search ||
        p.name.includes(search) ||
        (p.client_name ?? "").includes(search) ||
        (p.location ?? "").includes(search),
    );

  return (
    <div className="p-6">
      <div className="flex flex-wrap items-start justify-between gap-3">
        <div>
          <h1 className="text-2xl font-bold">المشاريع</h1>
          <p className="mt-1 text-sm text-muted-foreground">
            إدارة المشاريع والمناقصات — كل مشروع يحتوي على بنود الكميات وتحليل الأسعار والمتطلبات والملفات.
          </p>
        </div>
        <NewProjectDialog />
      </div>

      <div className="mt-6 flex flex-wrap items-center gap-3">
        <div className="relative w-full max-w-sm">
          <Search className="pointer-events-none absolute right-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
          <Input
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="ابحث بالاسم أو العميل أو الموقع…"
            className="h-9 pr-9"
          />
        </div>
        <Select value={statusFilter} onValueChange={(v) => setStatusFilter(v as Status | "all")}>
          <SelectTrigger className="h-9 w-40">
            <SelectValue />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">كل الحالات</SelectItem>
            {(Object.keys(STATUS_META) as Status[]).map((s) => (
              <SelectItem key={s} value={s}>
                {STATUS_META[s].label}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>
        <div className="text-xs text-muted-foreground">
          {filtered.length} من {projects.length} مشروع
        </div>
      </div>

      <div className="mt-4 overflow-hidden rounded-lg border border-border bg-card">
        <table className="w-full text-right text-sm">
          <thead className="bg-muted/40 text-xs text-muted-foreground">
            <tr>
              <th className="px-4 py-3 font-medium">اسم المشروع</th>
              <th className="px-4 py-3 font-medium">العميل</th>
              <th className="px-4 py-3 font-medium">الموقع</th>
              <th className="px-4 py-3 font-medium">الحالة</th>
              <th className="px-4 py-3 font-medium">القيمة التقديرية</th>
              <th className="px-4 py-3 font-medium">تاريخ التسليم</th>
              <th className="px-4 py-3 font-medium"></th>
            </tr>
          </thead>
          <tbody className="divide-y divide-border">
            {isLoading && (
              <tr>
                <td colSpan={7} className="px-4 py-8 text-center text-muted-foreground">
                  جاري التحميل…
                </td>
              </tr>
            )}
            {!isLoading && filtered.length === 0 && (
              <tr>
                <td colSpan={7} className="px-4 py-12 text-center text-muted-foreground">
                  <FolderPlus className="mx-auto mb-2 h-8 w-8 opacity-40" />
                  <div>لا توجد مشاريع — أضف مشروعك الأول للبدء</div>
                </td>
              </tr>
            )}
            {filtered.map((p) => (
              <tr key={p.id} className="hover:bg-muted/30">
                <td className="px-4 py-3 font-medium">
                  <Link
                    to="/projects/$projectId"
                    params={{ projectId: p.id }}
                    onClick={() => setActiveProjectId(p.id)}
                    className="text-primary hover:underline"
                  >
                    {p.name}
                  </Link>
                </td>
                <td className="px-4 py-3 text-muted-foreground">{p.client_name || "—"}</td>
                <td className="px-4 py-3 text-muted-foreground">{p.location || "—"}</td>
                <td className="px-4 py-3">
                  <Badge variant="outline" className={STATUS_META[p.status].cls}>
                    {STATUS_META[p.status].label}
                  </Badge>
                </td>
                <td className="px-4 py-3 tabular-nums">{fmtSAR(Number(p.estimated_value ?? 0))}</td>
                <td className="px-4 py-3 text-muted-foreground">{p.submission_date || "—"}</td>
                <td className="px-4 py-3">
                  <div className="flex items-center justify-end gap-1">
                    <Link
                      to="/projects/$projectId"
                      params={{ projectId: p.id }}
                      onClick={() => setActiveProjectId(p.id)}
                    >
                      <Button size="sm" variant="ghost" className="gap-1">
                        فتح
                        <ChevronLeft className="h-3.5 w-3.5" />
                      </Button>
                    </Link>
                    <Button
                      size="icon"
                      variant="ghost"
                      onClick={() => {
                        if (confirm(`حذف المشروع "${p.name}" مع كل بياناته؟`)) {
                          delMut.mutate(p.id);
                        }
                      }}
                      className="h-8 w-8 text-muted-foreground hover:text-red-500"
                    >
                      <Trash2 className="h-4 w-4" />
                    </Button>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}

function NewProjectDialog() {
  const [open, setOpen] = useState(false);
  const [name, setName] = useState("");
  const [client, setClient] = useState("");
  const [location, setLocation] = useState("");
  const [status, setStatus] = useState<Status>("draft");
  const [estValue, setEstValue] = useState("");
  const qc = useQueryClient();

  const mut = useMutation({
    mutationFn: async () => {
      const { data: u } = await supabase.auth.getUser();
      const user_id = u.user?.id;
      if (!user_id) throw new Error("غير مسجل دخول");
      if (!name.trim()) throw new Error("اسم المشروع مطلوب");
      const { data, error } = await supabase
        .from("projects")
        .insert({
          user_id,
          name: name.trim(),
          client_name: client.trim() || null,
          location: location.trim() || null,
          status,
          estimated_value: Number(estValue) || 0,
        })
        .select()
        .single();
      if (error) throw error;
      return data as Project;
    },
    onSuccess: (p) => {
      toast.success("تم إنشاء المشروع");
      qc.invalidateQueries({ queryKey: ["projects"] });
      setActiveProjectId(p.id);
      setOpen(false);
      setName(""); setClient(""); setLocation(""); setEstValue(""); setStatus("draft");
    },
    onError: (e: Error) => toast.error(e.message),
  });

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogTrigger asChild>
        <Button className="gap-2">
          <Plus className="h-4 w-4" />
          مشروع جديد
        </Button>
      </DialogTrigger>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>مشروع جديد</DialogTitle>
        </DialogHeader>
        <div className="grid gap-3">
          <div className="grid gap-1.5">
            <Label>اسم المشروع *</Label>
            <Input value={name} onChange={(e) => setName(e.target.value)} placeholder="مثال: مبنى إداري - الرياض" />
          </div>
          <div className="grid grid-cols-2 gap-3">
            <div className="grid gap-1.5">
              <Label>العميل</Label>
              <Input value={client} onChange={(e) => setClient(e.target.value)} placeholder="اسم العميل" />
            </div>
            <div className="grid gap-1.5">
              <Label>الموقع</Label>
              <Input value={location} onChange={(e) => setLocation(e.target.value)} placeholder="المدينة / الحي" />
            </div>
          </div>
          <div className="grid grid-cols-2 gap-3">
            <div className="grid gap-1.5">
              <Label>الحالة</Label>
              <Select value={status} onValueChange={(v) => setStatus(v as Status)}>
                <SelectTrigger><SelectValue /></SelectTrigger>
                <SelectContent>
                  {(Object.keys(STATUS_META) as Status[]).map((s) => (
                    <SelectItem key={s} value={s}>{STATUS_META[s].label}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            <div className="grid gap-1.5">
              <Label>القيمة التقديرية (ر.س)</Label>
              <Input type="number" value={estValue} onChange={(e) => setEstValue(e.target.value)} placeholder="0" />
            </div>
          </div>
        </div>
        <DialogFooter>
          <Button variant="ghost" onClick={() => setOpen(false)}>إلغاء</Button>
          <Button onClick={() => mut.mutate()} disabled={mut.isPending}>
            {mut.isPending ? "جاري الإنشاء…" : "إنشاء"}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
