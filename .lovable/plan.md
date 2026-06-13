## نظرة عامة
بناء منصة مؤسسية لتقدير التكاليف وإدارة المناقصات للمقاولين في السوق السعودي، بواجهة عربية كاملة (RTL) ووضع داكن احترافي بلون أخضر نيون. التركيز في هذه المرحلة على الهيكل + 3 وحدات أساسية (BOQ، تحليل الأسعار، قاعدة الموارد) مع تفعيل Lovable Cloud لإدارة البيانات والمصادقة من البداية.

## التقنيات
- TanStack Start + TypeScript + Tailwind v4 + shadcn/ui + Recharts + lucide-react
- Lovable Cloud (قاعدة بيانات + مصادقة + RBAC)
- اللون الأساسي: أخضر نيون `#4ade80` + خلفية `slate-950` / بطاقات `slate-900`
- `dir="rtl"` + خط عربي احترافي (Cairo أو Tajawal من Google Fonts)

## هيكل التنقل والمسارات
يتم بناء الهيكل الكامل للـ sidebar مع 9 عناصر، لكن في هذه المرحلة فقط الـ 3 مسارات الأساسية تكون فعّالة، والباقي يعرض صفحة "قريباً" بسيطة (سيتم بناؤها في المراحل التالية):

```
src/routes/
  __root.tsx              -> Sidebar + Header + Outlet (RTL shell)
  index.tsx               -> redirect إلى /boq
  _authenticated/route.tsx -> حماية المسارات (managed)
  _authenticated/boq.tsx              -> جدول الكميات (افتراضي)
  _authenticated/price-analysis.tsx   -> تحليل الأسعار
  _authenticated/resources.tsx        -> قاعدة الموارد
  _authenticated/dashboard.tsx        -> placeholder "قريباً"
  _authenticated/tenders.tsx          -> placeholder
  _authenticated/financial.tsx        -> placeholder
  _authenticated/reports.tsx          -> placeholder
  _authenticated/ai-assistant.tsx     -> placeholder
  _authenticated/settings.tsx         -> placeholder
  auth.tsx                -> تسجيل دخول/إنشاء حساب (إيميل+كلمة مرور + Google)
```

## نظام التصميم (src/styles.css)
- تعريف tokens: `--background` (slate-950)، `--card` (slate-900)، `--primary` (أخضر نيون)، `--destructive` (أحمر)، `--warning` (amber)
- تطبيق dark mode افتراضياً على `<html>`
- خط `Cairo` للعربية يُحمَّل من `<link>` في `__root.tsx`
- تفعيل `dir="rtl"` على `<html>`

## الوحدة 1: جدول الكميات (BOQ)
- جدول شبيه بـ Excel، كثيف بصرياً، مع تسلسل WBS هرمي لا نهائي (parent_id self-reference)
- أعمدة: رقم البند، الوصف، الوحدة، الكمية، تكلفة المواد، تكلفة العمالة، تكلفة المعدات، مقاول الباطن، إجمالي سعر الوحدة (محسوب)، الإجمالي (محسوب)
- صفوف الـ parent (مثل "01 الأعمال الترابية") بخلفية مميزة وخط عريض، الأبناء بمسافة بادئة (indent حسب المستوى)
- إمكانية طيّ/فتح الفروع (collapse/expand)
- زر "استيراد BOQ من Excel" في الأعلى (UI فقط في هذه المرحلة، يفتح dialog يشرح أن الاستيراد قادم)
- زر إضافة بند/مجموعة جديدة
- بيانات وهمية واقعية: أعمال ترابية، خرسانة، حديد تسليح، أعمال كهروميكانيكية... إلخ

## الوحدة 2: تحليل الأسعار (Price Analysis)
- تخطيط Master-Detail: قائمة بنود BOQ على اليمين، تفاصيل البند على اليسار
- عند اختيار بند (مثل "حفر 1م³") تظهر 3 جداول فرعية:
  - المواد (ديزل، إلخ) — كمية × سعر وحدة = إجمالي
  - العمالة (مشغل، مساعد) — ساعات × أجر/ساعة
  - المعدات (حفار، لودر) — ساعات × تكلفة/ساعة
- ملخص حساب تفاعلي أسفل الشاشة:
  ```
  التكلفة المباشرة + التكلفة غير المباشرة (%) + المصاريف العامة (%) + المخاطر (%) + الربح (%) = سعر البيع
  ```
- حقول النِسب قابلة للتعديل والحساب يتم فورياً

## الوحدة 3: قاعدة الموارد (Resources)
- 3 تبويبات (Tabs):
  - **المواد**: خرسانة جاهزة 350 ر.س/م³، أسمنت، حديد، بلوك، إسفلت... (مع وحدة وسعر)
  - **العمالة**: بنّاء، نجار، حداد، فورمان، مساح (ر.س/ساعة)
  - **المعدات**: حفار، رولر، رافعة، بوبكات، قلاب (ر.س/ساعة)
- جدول بحث + فلترة + إضافة/تعديل/حذف
- الأسعار مخزّنة في قاعدة البيانات

## قاعدة البيانات (Lovable Cloud)
جداول هذه المرحلة (مع RLS لكل مستخدم + جدول أدوار منفصل):

- `app_role` (enum): `admin`, `estimation_manager`, `estimator`, `viewer`
- `user_roles(id, user_id, role)` + دالة `has_role()` SECURITY DEFINER
- `resources(id, user_id, type[material|labor|equipment], name_ar, unit, unit_price, created_at)`
- `boq_items(id, user_id, parent_id, item_no, description_ar, unit, quantity, material_cost, labor_cost, equipment_cost, subcontractor_cost, sort_order, level)`
- `price_analysis_items(id, user_id, boq_item_id, resource_type, resource_id, quantity, unit_price)`
- `price_analysis_markup(boq_item_id, indirect_pct, overhead_pct, risk_pct, profit_pct)`

كل الجداول مع GRANTs للـ `authenticated` + `service_role` و RLS scoped بـ `auth.uid()`.

## المصادقة
- صفحة `/auth` بسيطة باللغة العربية: إيميل + كلمة مرور + زر "تسجيل دخول بـ Google" (عبر `lovable.auth.signInWithOAuth`)
- المستخدم الأول يحصل تلقائياً على دور `admin` (عبر trigger على `auth.users`)
- جميع مسارات النظام محمية تحت `_authenticated/`

## بيانات seed
Migration تضع بيانات وهمية واقعية للسوق السعودي:
- ~15 مادة، ~10 عمالة، ~10 معدات
- مشروع BOQ نموذجي (فيلا سكنية أو مبنى تجاري) بـ 3 مستويات هرمية و~25 بند
- تحليل أسعار جاهز لبعض البنود

## ملاحظات تقنية
- شريط التنقل (Sidebar) يستخدم shadcn `sidebar` مع `side="right"` لدعم RTL
- جدول BOQ يُبنى يدوياً كـ `<table>` لتحقيق الكثافة البصرية (وليس DataTable عامة)، مع scrolling أفقي وعمودي
- جميع الأرقام تُنسَّق بـ `Intl.NumberFormat('ar-SA')` وتُلحق بـ "ر.س"
- placeholders للمسارات الأخرى = بطاقة وسط الشاشة فيها أيقونة + اسم القسم + "قيد التطوير — سيتم بناؤه في المرحلة التالية"

## ما هو خارج نطاق هذه المرحلة
- الداشبورد + المناقصات + المراجعة المالية + التقارير + مساعد AI + إدارة الصلاحيات (UI كامل)
- استيراد Excel فعلي
- توليد PDF
- بناء أيٍّ منها يتم في مراحل تالية بعد التحقق من نجاح هذه المرحلة
