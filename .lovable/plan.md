# خطة إصلاح شاملة للمنصة

عملت فحص أمني كامل + مراجعة كاملة للكود. لقيت **9 ثغرات أمنية** + **3 مشاكل حرجة** + **8 مشاكل كبيرة** + عدد من المشاكل الصغيرة. دي خطة الإصلاح مرتّبة بالأولوية.

---

## 🔴 الأولوية القصوى — أمان البيانات (Migrations)

كل سياسات RLS الحالية بتسمح لأي مستخدم مسجّل بقراءة وتعديل بيانات المستخدمين الآخرين (الشرط `auth.uid() IS NOT NULL` فقط). دي السبب الحقيقي إن البيانات كانت "بتختفي" قبل كده — لأن المستخدمين كانوا بيشوفوا بيانات بعض.

**Migration واحد يصلح كل الجداول:**
- استبدال سياسات `projects`, `boq_items`, `resources`, `price_analysis_items`, `price_analysis_markup`, `project_files` بشرط `auth.uid() = user_id`
- إضافة `ON DELETE CASCADE` على `boq_items.parent_id` (يحل مشكلة C3 — حذف مجموعة يحذف بنودها)
- إضافة UNIQUE constraint على `(user_id, project_id, item_no)` لمنع التكرار
- إضافة policy UPDATE على storage bucket `project-files`
- تأمين دالة `seed_demo_data` بحيث ما تتنفذش إلا للمستخدم الحالي فقط (موجود فعلاً لكن لازم نتأكد إنها مش متاحة للـ anon)

## 🔴 Bugs حرجة في الكود

1. **`boq.tsx:106` — `useMemo` مع `setState`**: نقلها لـ `useEffect` (السلوك الحالي ممكن يسبب infinite loop أو يفشل صامتاً).
2. **`price-analysis.tsx:329` — Race condition في markup**: استخدام `upsert` بدل `insert/update` المنفصلين، مع الاعتماد على unique constraint على `boq_item_id`.
3. **`price-analysis.tsx:353` — `MarkupInput` uncontrolled**: تحويلها لـ controlled input عشان تتحدث لما القيمة تتغير.

## 🟠 مشاكل كبيرة

4. **`reports.tsx` — تقرير الموارد بيعرض كل البيانات**: إضافة فلتر `project_id` (حالياً بيتجاوز عزل المشاريع).
5. **`boq.tsx:419,433` — `level` و `sort_order` ثابتين**:
   - حساب `level` من عمق الـ parent
   - `sort_order = MAX(sort_order) + 1` لإخوة الـ parent نفسه
6. **`dashboard.tsx:71,82` — عدّاد الموارد/البنود عام**: فلترة بـ `project_id` للمشروع النشط، وتغيير اللابل لو مفيش مشروع مختار.
7. **`projects.$projectId.tsx:449` — خطأ حذف الملف من Storage مُتجاهَل**: فحص النتيجة قبل حذف السجل من DB.
8. **`app-shell.tsx:98` — query key ميت `"active-project-data"`**: استبداله بـ keys فعلية (`["boq_items"]`, `["resources"]`, `["price_analysis_items"]`).
9. **`projects.$projectId.tsx:413` — رفع الملفات بدون تحقق**: إضافة حد أقصى للحجم (10MB) وقائمة MIME types مسموحة.

## 🟡 تحسينات صغيرة

10. **توحيد `STATUS_META`** في ملف واحد `src/lib/project-status.ts` بدل تكراره في 4 ملفات (اللابل مختلف حالياً في الـ Dashboard — "مُرسل للوسيط" vs "مُرسل للوسيط (GM)").
11. **إزالة `as any`** عن حقول `Project` الموجودة فعلاً في types.
12. **توحيد imports المكررة** من نفس الـ package في `boq.tsx` و `price-analysis.tsx`.
13. **إخفاء/تفعيل خانة البحث في الـ header**: إما إزالتها أو وصلها فعلياً.
14. **إزالة meta description المكرر** في `__root.tsx`.
15. **إضافة loading state** على `NoEditor` في `projects.index.tsx`.

## 🔵 ملاحظات (ما هتتعملش إلا لو طلبت)

- نقل العمليات الحساسة لـ `createServerFn` (حالياً كله client-side — مقبول طالما RLS صح بعد الإصلاح).
- تفعيل صفحات "قريباً": المراجعة المالية، مساعد AI، الإعدادات.

---

## ترتيب التنفيذ

1. **Migration الأمان** (يحل أهم 6 ثغرات + مشكلة الـ orphan)
2. **الـ 3 bugs الحرجة في الكود**
3. **الـ 6 مشاكل الكبيرة**
4. **التحسينات الصغيرة** (دفعة واحدة)

كل خطوة هتعمل verify بعدها للتأكد من النتيجة.

---

## للتأكيد قبل البدء

عايز أنفّذ:
- (أ) **كل الخطة** (الأمان + الحرج + الكبير + الصغير) — مُوصى به
- (ب) **الأمان + الحرج فقط** (أسرع، يحل مشاكل عزل البيانات والـ bugs)
- (ج) **اختار خطوات معينة** بالأرقام

استنّى موافقتك قبل ما أبدأ.
