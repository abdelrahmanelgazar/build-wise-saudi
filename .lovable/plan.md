# خطة تنفيذ صفحة المشاريع

## نظرة عامة
المشاريع ستكون الحاوية الرئيسية لكل البيانات (BOQ، تحليل الأسعار). كل بند BOQ وكل مورد سيرتبط بمشروع محدد، مع شريط اختيار المشروع النشط في أعلى التطبيق.

## 1. تعديلات قاعدة البيانات (Migration)

### جدول جديد `projects`
الحقول:
- `name` — اسم المشروع
- `client_name` — اسم العميل
- `location` — الموقع
- `status` — enum: `draft` (مسودة)، `in_progress` (جاري)، `awarded` (مرسي)، `rejected` (مرفوض)، `completed` (منتهي)
- `estimated_value` — القيمة التقديرية
- `budget` — الميزانية
- `start_date` / `end_date` / `submission_date` — التواريخ
- `technical_requirements` — متطلبات العرض الفني (نص طويل)
- `financial_requirements` — متطلبات العرض المالي (نص طويل)
- `notes` — ملاحظات
- `user_id` — مالك المشروع
- `created_at` / `updated_at`

تفعيل RLS مع policy: المستخدم يدير مشاريعه فقط (`auth.uid() = user_id`).
GRANT لـ `authenticated` و `service_role`.

### إضافة `project_id` للجداول الحالية
- `boq_items.project_id` (UUID, FK → projects, ON DELETE CASCADE)
- `resources.project_id` (UUID nullable — الموارد قد تكون عامة أو خاصة بمشروع)
- `price_analysis_items.project_id` (مشتقة من boq_item)
- `price_analysis_markup.project_id`

### تخزين الملفات
إنشاء bucket خاص `project-files` (private) لرفع ملفات الشروط/المرفقات، مع RLS على `storage.objects` يحصر الوصول للمالك (path = `{user_id}/{project_id}/...`).

### جدول `project_files`
لتتبع الملفات المرفوعة:
- `project_id`، `file_name`، `file_path`، `file_size`، `file_type`، `uploaded_at`

## 2. الواجهة

### الصفحة الرئيسية `/projects` (استبدال tenders.tsx بـ projects.tsx)
- جدول/كروت بكل المشاريع
- بحث بالاسم/العميل، فلترة بالحالة
- زر "مشروع جديد" يفتح Dialog لإضافة سريعة
- كل صف فيه: اسم، عميل، حالة (Badge ملون)، قيمة، تاريخ تسليم، أزرار (عرض/تعديل/حذف)

### صفحة التفاصيل `/projects/$projectId`
تبويبات (Tabs):
1. **نظرة عامة** — بيانات المشروع + إحصائيات (عدد بنود BOQ، إجمالي التكلفة)
2. **البيانات الأساسية** — تعديل كل الحقول
3. **المتطلبات** — العرض الفني والمالي (textarea كبير)
4. **الملفات** — رفع/تحميل/حذف ملفات الشروط
5. **روابط سريعة** — أزرار للانتقال لـ BOQ/تحليل الأسعار الخاصة بالمشروع

### اختيار المشروع النشط
- إضافة Project Switcher في `app-shell` (Combobox أعلى الـ Sidebar)
- المشروع المختار يُحفظ في `localStorage` + Context
- صفحات BOQ، تحليل الأسعار، الموارد تستخدم المشروع النشط لتصفية بياناتها
- زر "بدون مشروع" يعرض كل البيانات (وضع عام)

### تحديث الصفحات الأخرى
- `boq.tsx` و `price-analysis.tsx`: تستخدم `project_id` النشط في كل insert/select
- إضافة شارة في الـ header توضح المشروع الحالي

## 3. Server Functions
في `src/lib/projects.functions.ts`:
- `listProjects` — قائمة مشاريع المستخدم
- `getProject(id)` — تفاصيل مشروع
- `createProject(data)` — إنشاء
- `updateProject(id, data)` — تعديل
- `deleteProject(id)` — حذف (cascade للـ BOQ المرتبط)
- `uploadProjectFile` / `deleteProjectFile`

كلها بـ `requireSupabaseAuth` middleware.

## 4. Routing
- `src/routes/_authenticated/projects.tsx` (layout مع `<Outlet />`)
- `src/routes/_authenticated/projects.index.tsx` (القائمة)
- `src/routes/_authenticated/projects.$projectId.tsx` (التفاصيل)
- تحديث `app-shell.tsx`: المسار `/projects` بدل `/tenders`، وحذف `tenders.tsx`

## 5. ترحيل البيانات الموجودة (Demo)
المشروع التجريبي الموجود (BOQ + Resources الحاليين) — إنشاء مشروع افتراضي تجريبي "مبنى إداري - الرياض" وربط كل البيانات الموجودة به عبر UPDATE.

## ترتيب التنفيذ
1. Migration (جداول + storage bucket + ربط الـ FKs + ترحيل البيانات)
2. Server functions
3. Project Context + Switcher في app-shell
4. صفحة القائمة + Dialog الإضافة
5. صفحة التفاصيل بكل تبويباتها
6. تحديث صفحات BOQ/الموارد لاستخدام المشروع النشط
7. حذف `tenders.tsx`

هل تريد المضي بهذه الخطة كاملة، أم تفضّل تجزئتها (مثلاً البدء بـ CRUD الأساسي فقط ثم الملفات وربط BOQ لاحقاً)؟
