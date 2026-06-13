
-- 1) projects RLS
DROP POLICY IF EXISTS "Authenticated users can manage projects" ON public.projects;
DROP POLICY IF EXISTS "Users can view their own projects" ON public.projects;
DROP POLICY IF EXISTS "Users can insert their own projects" ON public.projects;
DROP POLICY IF EXISTS "Users can update their own projects" ON public.projects;
DROP POLICY IF EXISTS "Users can delete their own projects" ON public.projects;
CREATE POLICY "Users select own projects" ON public.projects FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users insert own projects" ON public.projects FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users update own projects" ON public.projects FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users delete own projects" ON public.projects FOR DELETE USING (auth.uid() = user_id);

-- 2) boq_items RLS + cascade
DROP POLICY IF EXISTS "Authenticated users can manage boq items" ON public.boq_items;
DROP POLICY IF EXISTS "Users can view their own boq_items" ON public.boq_items;
DROP POLICY IF EXISTS "Users can insert their own boq_items" ON public.boq_items;
DROP POLICY IF EXISTS "Users can update their own boq_items" ON public.boq_items;
DROP POLICY IF EXISTS "Users can delete their own boq_items" ON public.boq_items;
CREATE POLICY "Users select own boq_items" ON public.boq_items FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users insert own boq_items" ON public.boq_items FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users update own boq_items" ON public.boq_items FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users delete own boq_items" ON public.boq_items FOR DELETE USING (auth.uid() = user_id);

-- Add ON DELETE CASCADE on boq_items.parent_id
ALTER TABLE public.boq_items DROP CONSTRAINT IF EXISTS boq_items_parent_id_fkey;
ALTER TABLE public.boq_items
  ADD CONSTRAINT boq_items_parent_id_fkey
  FOREIGN KEY (parent_id) REFERENCES public.boq_items(id) ON DELETE CASCADE;

-- 3) resources RLS
DROP POLICY IF EXISTS "Authenticated users can manage resources" ON public.resources;
DROP POLICY IF EXISTS "Users can view their own resources" ON public.resources;
DROP POLICY IF EXISTS "Users can insert their own resources" ON public.resources;
DROP POLICY IF EXISTS "Users can update their own resources" ON public.resources;
DROP POLICY IF EXISTS "Users can delete their own resources" ON public.resources;
CREATE POLICY "Users select own resources" ON public.resources FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users insert own resources" ON public.resources FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users update own resources" ON public.resources FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users delete own resources" ON public.resources FOR DELETE USING (auth.uid() = user_id);

-- 4) price_analysis_items RLS
DROP POLICY IF EXISTS "Authenticated users can manage price analysis items" ON public.price_analysis_items;
DROP POLICY IF EXISTS "Users can view their own price_analysis_items" ON public.price_analysis_items;
DROP POLICY IF EXISTS "Users can insert their own price_analysis_items" ON public.price_analysis_items;
DROP POLICY IF EXISTS "Users can update their own price_analysis_items" ON public.price_analysis_items;
DROP POLICY IF EXISTS "Users can delete their own price_analysis_items" ON public.price_analysis_items;
CREATE POLICY "Users select own pa_items" ON public.price_analysis_items FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users insert own pa_items" ON public.price_analysis_items FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users update own pa_items" ON public.price_analysis_items FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users delete own pa_items" ON public.price_analysis_items FOR DELETE USING (auth.uid() = user_id);

-- 5) price_analysis_markup RLS + unique
DROP POLICY IF EXISTS "Authenticated users can manage price analysis markup" ON public.price_analysis_markup;
DROP POLICY IF EXISTS "Users can view their own price_analysis_markup" ON public.price_analysis_markup;
DROP POLICY IF EXISTS "Users can insert their own price_analysis_markup" ON public.price_analysis_markup;
DROP POLICY IF EXISTS "Users can update their own price_analysis_markup" ON public.price_analysis_markup;
DROP POLICY IF EXISTS "Users can delete their own price_analysis_markup" ON public.price_analysis_markup;
CREATE POLICY "Users select own pa_markup" ON public.price_analysis_markup FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users insert own pa_markup" ON public.price_analysis_markup FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users update own pa_markup" ON public.price_analysis_markup FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users delete own pa_markup" ON public.price_analysis_markup FOR DELETE USING (auth.uid() = user_id);

-- ensure boq_item_id unique for upsert
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'price_analysis_markup_boq_item_id_key'
  ) THEN
    ALTER TABLE public.price_analysis_markup
      ADD CONSTRAINT price_analysis_markup_boq_item_id_key UNIQUE (boq_item_id);
  END IF;
END $$;

-- 6) project_files RLS
DROP POLICY IF EXISTS "Authenticated users can manage project files" ON public.project_files;
DROP POLICY IF EXISTS "Users can view their own project_files" ON public.project_files;
DROP POLICY IF EXISTS "Users can insert their own project_files" ON public.project_files;
DROP POLICY IF EXISTS "Users can update their own project_files" ON public.project_files;
DROP POLICY IF EXISTS "Users can delete their own project_files" ON public.project_files;
CREATE POLICY "Users select own project_files" ON public.project_files FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users insert own project_files" ON public.project_files FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users update own project_files" ON public.project_files FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users delete own project_files" ON public.project_files FOR DELETE USING (auth.uid() = user_id);

-- 7) Storage UPDATE policy for project-files bucket
DROP POLICY IF EXISTS "Users can update their own project files" ON storage.objects;
CREATE POLICY "Users can update their own project files" ON storage.objects
  FOR UPDATE TO authenticated
  USING (bucket_id = 'project-files' AND (auth.uid())::text = (storage.foldername(name))[1])
  WITH CHECK (bucket_id = 'project-files' AND (auth.uid())::text = (storage.foldername(name))[1]);

-- 8) Unique constraint on (user_id, project_id, item_no)
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'boq_items_user_project_itemno_key'
  ) THEN
    ALTER TABLE public.boq_items
      ADD CONSTRAINT boq_items_user_project_itemno_key UNIQUE (user_id, project_id, item_no);
  END IF;
END $$;
