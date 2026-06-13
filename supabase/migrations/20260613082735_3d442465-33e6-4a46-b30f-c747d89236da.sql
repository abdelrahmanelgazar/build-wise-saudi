
-- ========== ENUMS ==========
CREATE TYPE public.app_role AS ENUM ('admin', 'estimation_manager', 'estimator', 'viewer');
CREATE TYPE public.resource_type AS ENUM ('material', 'labor', 'equipment');

-- ========== USER ROLES ==========
CREATE TABLE public.user_roles (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role app_role NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (user_id, role)
);
GRANT SELECT ON public.user_roles TO authenticated;
GRANT ALL ON public.user_roles TO service_role;
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users view own roles" ON public.user_roles FOR SELECT TO authenticated USING (auth.uid() = user_id);

CREATE OR REPLACE FUNCTION public.has_role(_user_id UUID, _role app_role)
RETURNS BOOLEAN LANGUAGE SQL STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (SELECT 1 FROM public.user_roles WHERE user_id = _user_id AND role = _role)
$$;

-- First user becomes admin, others become estimator
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  user_count INT;
BEGIN
  SELECT COUNT(*) INTO user_count FROM auth.users;
  IF user_count = 1 THEN
    INSERT INTO public.user_roles (user_id, role) VALUES (NEW.id, 'admin');
  ELSE
    INSERT INTO public.user_roles (user_id, role) VALUES (NEW.id, 'estimator');
  END IF;
  RETURN NEW;
END;
$$;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ========== RESOURCES ==========
CREATE TABLE public.resources (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  type resource_type NOT NULL,
  code TEXT,
  name_ar TEXT NOT NULL,
  unit TEXT NOT NULL,
  unit_price NUMERIC(14,2) NOT NULL DEFAULT 0,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.resources TO authenticated;
GRANT ALL ON public.resources TO service_role;
ALTER TABLE public.resources ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users manage own resources" ON public.resources FOR ALL TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE INDEX idx_resources_user_type ON public.resources(user_id, type);

-- ========== BOQ ITEMS ==========
CREATE TABLE public.boq_items (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  parent_id UUID REFERENCES public.boq_items(id) ON DELETE CASCADE,
  item_no TEXT NOT NULL,
  description_ar TEXT NOT NULL,
  unit TEXT,
  quantity NUMERIC(14,3) DEFAULT 0,
  material_cost NUMERIC(14,2) DEFAULT 0,
  labor_cost NUMERIC(14,2) DEFAULT 0,
  equipment_cost NUMERIC(14,2) DEFAULT 0,
  subcontractor_cost NUMERIC(14,2) DEFAULT 0,
  is_group BOOLEAN NOT NULL DEFAULT false,
  level INT NOT NULL DEFAULT 0,
  sort_order INT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.boq_items TO authenticated;
GRANT ALL ON public.boq_items TO service_role;
ALTER TABLE public.boq_items ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users manage own boq" ON public.boq_items FOR ALL TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE INDEX idx_boq_user_parent ON public.boq_items(user_id, parent_id, sort_order);

-- ========== PRICE ANALYSIS ==========
CREATE TABLE public.price_analysis_items (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  boq_item_id UUID NOT NULL REFERENCES public.boq_items(id) ON DELETE CASCADE,
  resource_id UUID REFERENCES public.resources(id) ON DELETE SET NULL,
  resource_type resource_type NOT NULL,
  description_ar TEXT NOT NULL,
  unit TEXT NOT NULL,
  quantity NUMERIC(14,4) NOT NULL DEFAULT 0,
  unit_price NUMERIC(14,2) NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.price_analysis_items TO authenticated;
GRANT ALL ON public.price_analysis_items TO service_role;
ALTER TABLE public.price_analysis_items ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users manage own price analysis" ON public.price_analysis_items FOR ALL TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE INDEX idx_pa_boq ON public.price_analysis_items(boq_item_id);

CREATE TABLE public.price_analysis_markup (
  boq_item_id UUID NOT NULL PRIMARY KEY REFERENCES public.boq_items(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  indirect_pct NUMERIC(6,2) NOT NULL DEFAULT 5,
  overhead_pct NUMERIC(6,2) NOT NULL DEFAULT 8,
  risk_pct NUMERIC(6,2) NOT NULL DEFAULT 3,
  profit_pct NUMERIC(6,2) NOT NULL DEFAULT 10,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.price_analysis_markup TO authenticated;
GRANT ALL ON public.price_analysis_markup TO service_role;
ALTER TABLE public.price_analysis_markup ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users manage own markup" ON public.price_analysis_markup FOR ALL TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- ========== SEED FUNCTION ==========
-- Called via RPC after first sign-up to populate sample data
CREATE OR REPLACE FUNCTION public.seed_demo_data()
RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  uid UUID := auth.uid();
  g_earth UUID; g_conc UUID; g_steel UUID; g_block UUID;
  b_exc UUID; b_back UUID;
  res_diesel UUID; res_operator UUID; res_helper UUID; res_excavator UUID; res_loader UUID;
BEGIN
  IF uid IS NULL THEN RAISE EXCEPTION 'Not authenticated'; END IF;
  -- Avoid double-seeding
  IF EXISTS (SELECT 1 FROM public.resources WHERE user_id = uid) THEN RETURN; END IF;

  -- Materials
  INSERT INTO public.resources(user_id, type, code, name_ar, unit, unit_price) VALUES
    (uid,'material','M001','خرسانة جاهزة 350 كجم/م³','م³',350),
    (uid,'material','M002','أسمنت بورتلاندي','طن',650),
    (uid,'material','M003','حديد تسليح قطر 16مم','طن',2750),
    (uid,'material','M004','حديد تسليح قطر 12مم','طن',2800),
    (uid,'material','M005','بلوك خرساني 20سم','حبة',3.5),
    (uid,'material','M006','رمل أبيض','م³',45),
    (uid,'material','M007','بحص','م³',60),
    (uid,'material','M008','إسفلت ساخن','طن',420),
    (uid,'material','M009','ديزل','لتر',2.33),
    (uid,'material','M010','سيراميك أرضيات','م²',55),
    (uid,'material','M011','دهان بلاستيك داخلي','جالون',85),
    (uid,'material','M012','عازل مائي','م²',18),
    (uid,'material','M013','بلاط رخام','م²',180),
    (uid,'material','M014','أبواب خشبية','حبة',850),
    (uid,'material','M015','زجاج مزدوج','م²',220)
  RETURNING id INTO res_diesel; -- not exact, we'll re-fetch
  SELECT id INTO res_diesel FROM public.resources WHERE user_id=uid AND code='M009';

  -- Labor
  INSERT INTO public.resources(user_id, type, code, name_ar, unit, unit_price) VALUES
    (uid,'labor','L001','بنّاء','ساعة',35),
    (uid,'labor','L002','نجار مسلح','ساعة',40),
    (uid,'labor','L003','حداد تسليح','ساعة',40),
    (uid,'labor','L004','عامل عادي (مساعد)','ساعة',20),
    (uid,'labor','L005','فورمان','ساعة',55),
    (uid,'labor','L006','مساح','ساعة',60),
    (uid,'labor','L007','كهربائي','ساعة',45),
    (uid,'labor','L008','سبّاك','ساعة',45),
    (uid,'labor','L009','دهّان','ساعة',35),
    (uid,'labor','L010','مشغل معدات','ساعة',50);
  SELECT id INTO res_operator FROM public.resources WHERE user_id=uid AND code='L010';
  SELECT id INTO res_helper FROM public.resources WHERE user_id=uid AND code='L004';

  -- Equipment
  INSERT INTO public.resources(user_id, type, code, name_ar, unit, unit_price) VALUES
    (uid,'equipment','E001','حفار (إكسكافيتر)','ساعة',180),
    (uid,'equipment','E002','لودر','ساعة',150),
    (uid,'equipment','E003','بوبكات','ساعة',95),
    (uid,'equipment','E004','رولر (مدحلة)','ساعة',120),
    (uid,'equipment','E005','رافعة برجية','ساعة',280),
    (uid,'equipment','E006','قلاب 20م³','ساعة',140),
    (uid,'equipment','E007','خلاطة خرسانة','ساعة',75),
    (uid,'equipment','E008','مضخة خرسانة','ساعة',320),
    (uid,'equipment','E009','مولد كهرباء','ساعة',65),
    (uid,'equipment','E010','شاحنة مياه','ساعة',110);
  SELECT id INTO res_excavator FROM public.resources WHERE user_id=uid AND code='E001';
  SELECT id INTO res_loader FROM public.resources WHERE user_id=uid AND code='E002';

  -- BOQ groups
  INSERT INTO public.boq_items(user_id,item_no,description_ar,unit,is_group,level,sort_order)
  VALUES (uid,'01','الأعمال الترابية',NULL,true,0,10) RETURNING id INTO g_earth;
  INSERT INTO public.boq_items(user_id,item_no,description_ar,unit,is_group,level,sort_order)
  VALUES (uid,'02','الأعمال الخرسانية',NULL,true,0,20) RETURNING id INTO g_conc;
  INSERT INTO public.boq_items(user_id,item_no,description_ar,unit,is_group,level,sort_order)
  VALUES (uid,'03','أعمال حديد التسليح',NULL,true,0,30) RETURNING id INTO g_steel;
  INSERT INTO public.boq_items(user_id,item_no,description_ar,unit,is_group,level,sort_order)
  VALUES (uid,'04','أعمال البناء والمباني',NULL,true,0,40) RETURNING id INTO g_block;

  -- Earthworks children
  INSERT INTO public.boq_items(user_id,parent_id,item_no,description_ar,unit,quantity,material_cost,labor_cost,equipment_cost,level,sort_order)
  VALUES (uid,g_earth,'01.01','حفر عام بالماكينات لجميع الأعمدة والقواعد','م³',850, 0, 4, 22, 1, 1)
  RETURNING id INTO b_exc;
  INSERT INTO public.boq_items(user_id,parent_id,item_no,description_ar,unit,quantity,material_cost,labor_cost,equipment_cost,level,sort_order)
  VALUES (uid,g_earth,'01.02','ردم بالرمل المختار وحدله على طبقات','م³',420, 25, 5, 12, 1, 2)
  RETURNING id INTO b_back;
  INSERT INTO public.boq_items(user_id,parent_id,item_no,description_ar,unit,quantity,material_cost,labor_cost,equipment_cost,level,sort_order)
  VALUES (uid,g_earth,'01.03','نقل ناتج الحفر خارج الموقع','م³',430, 0, 2, 18, 1, 3);

  -- Concrete children
  INSERT INTO public.boq_items(user_id,parent_id,item_no,description_ar,unit,quantity,material_cost,labor_cost,equipment_cost,level,sort_order) VALUES
    (uid,g_conc,'02.01','خرسانة نظافة سمك 10سم','م³',45, 280, 25, 8, 1, 1),
    (uid,g_conc,'02.02','خرسانة مسلحة للقواعد','م³',180, 380, 65, 22, 1, 2),
    (uid,g_conc,'02.03','خرسانة مسلحة للأعمدة','م³',95, 395, 85, 28, 1, 3),
    (uid,g_conc,'02.04','خرسانة مسلحة للأسقف','م³',240, 385, 70, 25, 1, 4),
    (uid,g_conc,'02.05','خرسانة مسلحة للجسور','م³',85, 390, 75, 26, 1, 5);

  -- Steel children
  INSERT INTO public.boq_items(user_id,parent_id,item_no,description_ar,unit,quantity,material_cost,labor_cost,equipment_cost,level,sort_order) VALUES
    (uid,g_steel,'03.01','توريد وتركيب حديد تسليح قطر 16مم','طن',32, 2750, 320, 45, 1, 1),
    (uid,g_steel,'03.02','توريد وتركيب حديد تسليح قطر 12مم','طن',28, 2800, 340, 45, 1, 2),
    (uid,g_steel,'03.03','أسلاك ربط ومسامير','كجم',450, 12, 2, 0, 1, 3);

  -- Block children
  INSERT INTO public.boq_items(user_id,parent_id,item_no,description_ar,unit,quantity,material_cost,labor_cost,equipment_cost,level,sort_order) VALUES
    (uid,g_block,'04.01','بناء بالبلوك الخرساني 20سم','م²',680, 42, 28, 3, 1, 1),
    (uid,g_block,'04.02','لياسة داخلية بالأسمنت','م²',1350, 14, 16, 1, 1, 2),
    (uid,g_block,'04.03','لياسة خارجية مقاومة للماء','م²',520, 22, 22, 2, 1, 3);

  -- Price analysis for "حفر عام" (b_exc)
  INSERT INTO public.price_analysis_items(user_id, boq_item_id, resource_id, resource_type, description_ar, unit, quantity, unit_price) VALUES
    (uid, b_exc, res_diesel, 'material', 'ديزل', 'لتر', 3.5, 2.33),
    (uid, b_exc, res_operator, 'labor', 'مشغل حفار', 'ساعة', 0.08, 50),
    (uid, b_exc, res_helper, 'labor', 'عامل مساعد', 'ساعة', 0.12, 20),
    (uid, b_exc, res_excavator, 'equipment', 'حفار', 'ساعة', 0.08, 180),
    (uid, b_exc, res_loader, 'equipment', 'لودر', 'ساعة', 0.05, 150);
  INSERT INTO public.price_analysis_markup(boq_item_id, user_id, indirect_pct, overhead_pct, risk_pct, profit_pct)
  VALUES (b_exc, uid, 5, 8, 3, 12);
END;
$$;
GRANT EXECUTE ON FUNCTION public.seed_demo_data() TO authenticated;
