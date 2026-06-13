
-- Project status enum
CREATE TYPE public.project_status AS ENUM ('draft', 'in_progress', 'awarded', 'rejected', 'completed');

-- Projects table
CREATE TABLE public.projects (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  client_name TEXT,
  location TEXT,
  status public.project_status NOT NULL DEFAULT 'draft',
  estimated_value NUMERIC DEFAULT 0,
  budget NUMERIC DEFAULT 0,
  start_date DATE,
  end_date DATE,
  submission_date DATE,
  technical_requirements TEXT,
  financial_requirements TEXT,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.projects TO authenticated;
GRANT ALL ON public.projects TO service_role;

ALTER TABLE public.projects ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own projects" ON public.projects
  FOR ALL TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE INDEX idx_projects_user_id ON public.projects(user_id);

-- updated_at trigger function (shared)
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER LANGUAGE plpgsql SET search_path = public AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END;
$$;

CREATE TRIGGER update_projects_updated_at
  BEFORE UPDATE ON public.projects
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- Project files table
CREATE TABLE public.project_files (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  project_id UUID NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
  file_name TEXT NOT NULL,
  file_path TEXT NOT NULL,
  file_size BIGINT,
  file_type TEXT,
  category TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.project_files TO authenticated;
GRANT ALL ON public.project_files TO service_role;

ALTER TABLE public.project_files ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own project files" ON public.project_files
  FOR ALL TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE INDEX idx_project_files_project_id ON public.project_files(project_id);

-- Add project_id to existing tables
ALTER TABLE public.boq_items ADD COLUMN project_id UUID REFERENCES public.projects(id) ON DELETE CASCADE;
ALTER TABLE public.resources ADD COLUMN project_id UUID REFERENCES public.projects(id) ON DELETE CASCADE;
ALTER TABLE public.price_analysis_items ADD COLUMN project_id UUID REFERENCES public.projects(id) ON DELETE CASCADE;
ALTER TABLE public.price_analysis_markup ADD COLUMN project_id UUID REFERENCES public.projects(id) ON DELETE CASCADE;

CREATE INDEX idx_boq_items_project_id ON public.boq_items(project_id);
CREATE INDEX idx_resources_project_id ON public.resources(project_id);
CREATE INDEX idx_price_analysis_items_project_id ON public.price_analysis_items(project_id);
CREATE INDEX idx_price_analysis_markup_project_id ON public.price_analysis_markup(project_id);

-- Migrate existing data: create a default demo project per existing user and link
DO $$
DECLARE
  u RECORD;
  new_pid UUID;
BEGIN
  FOR u IN
    SELECT DISTINCT user_id FROM public.boq_items
    UNION
    SELECT DISTINCT user_id FROM public.resources
  LOOP
    INSERT INTO public.projects(user_id, name, client_name, location, status, estimated_value, budget, notes)
    VALUES (u.user_id, 'مبنى إداري - الرياض (تجريبي)', 'وزارة الإسكان', 'الرياض - حي العليا', 'in_progress', 2500000, 2300000, 'مشروع تجريبي تم إنشاؤه تلقائياً لربط البيانات السابقة')
    RETURNING id INTO new_pid;

    UPDATE public.boq_items SET project_id = new_pid WHERE user_id = u.user_id AND project_id IS NULL;
    UPDATE public.resources SET project_id = new_pid WHERE user_id = u.user_id AND project_id IS NULL;
    UPDATE public.price_analysis_items SET project_id = new_pid WHERE user_id = u.user_id AND project_id IS NULL;
    UPDATE public.price_analysis_markup SET project_id = new_pid WHERE user_id = u.user_id AND project_id IS NULL;
  END LOOP;
END $$;
