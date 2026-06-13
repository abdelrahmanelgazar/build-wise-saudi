drop policy if exists "Users manage own projects" on public.projects;
create policy "Authenticated users manage all projects"
on public.projects
for all
to authenticated
using (true)
with check (true);

drop policy if exists "Users manage own boq" on public.boq_items;
create policy "Authenticated users manage all boq items"
on public.boq_items
for all
to authenticated
using (true)
with check (true);

drop policy if exists "Users manage own resources" on public.resources;
create policy "Authenticated users manage all resources"
on public.resources
for all
to authenticated
using (true)
with check (true);

drop policy if exists "Users manage own price analysis" on public.price_analysis_items;
create policy "Authenticated users manage all price analysis items"
on public.price_analysis_items
for all
to authenticated
using (true)
with check (true);

drop policy if exists "Users manage own markup" on public.price_analysis_markup;
create policy "Authenticated users manage all price analysis markup"
on public.price_analysis_markup
for all
to authenticated
using (true)
with check (true);

drop policy if exists "Users manage own project files" on public.project_files;
create policy "Authenticated users manage all project files"
on public.project_files
for all
to authenticated
using (true)
with check (true);