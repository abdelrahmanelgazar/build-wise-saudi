
DROP POLICY IF EXISTS "Signed-in users manage shared boq items" ON public.boq_items;
DROP POLICY IF EXISTS "Signed-in users manage shared price analysis items" ON public.price_analysis_items;
DROP POLICY IF EXISTS "Signed-in users manage shared price analysis markup" ON public.price_analysis_markup;
DROP POLICY IF EXISTS "Signed-in users manage shared project files" ON public.project_files;
DROP POLICY IF EXISTS "Signed-in users manage shared projects" ON public.projects;
DROP POLICY IF EXISTS "Signed-in users manage shared resources" ON public.resources;

DROP POLICY IF EXISTS "Users insert own boq_items" ON public.boq_items;
CREATE POLICY "Users insert own boq_items" ON public.boq_items FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users insert own pa_items" ON public.price_analysis_items;
CREATE POLICY "Users insert own pa_items" ON public.price_analysis_items FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users insert own pa_markup" ON public.price_analysis_markup;
CREATE POLICY "Users insert own pa_markup" ON public.price_analysis_markup FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users insert own project_files" ON public.project_files;
CREATE POLICY "Users insert own project_files" ON public.project_files FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users insert own projects" ON public.projects;
CREATE POLICY "Users insert own projects" ON public.projects FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users insert own resources" ON public.resources;
CREATE POLICY "Users insert own resources" ON public.resources FOR INSERT WITH CHECK (auth.uid() = user_id);
