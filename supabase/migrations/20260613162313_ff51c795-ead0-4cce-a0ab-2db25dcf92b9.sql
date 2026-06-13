drop policy if exists "Authenticated users manage all projects" on public.projects;
create policy "Signed-in users manage shared projects"
on public.projects
for all
to authenticated
using (auth.uid() is not null)
with check (auth.uid() is not null);

drop policy if exists "Authenticated users manage all boq items" on public.boq_items;
create policy "Signed-in users manage shared boq items"
on public.boq_items
for all
to authenticated
using (auth.uid() is not null)
with check (auth.uid() is not null);

drop policy if exists "Authenticated users manage all resources" on public.resources;
create policy "Signed-in users manage shared resources"
on public.resources
for all
to authenticated
using (auth.uid() is not null)
with check (auth.uid() is not null);

drop policy if exists "Authenticated users manage all price analysis items" on public.price_analysis_items;
create policy "Signed-in users manage shared price analysis items"
on public.price_analysis_items
for all
to authenticated
using (auth.uid() is not null)
with check (auth.uid() is not null);

drop policy if exists "Authenticated users manage all price analysis markup" on public.price_analysis_markup;
create policy "Signed-in users manage shared price analysis markup"
on public.price_analysis_markup
for all
to authenticated
using (auth.uid() is not null)
with check (auth.uid() is not null);

drop policy if exists "Authenticated users manage all project files" on public.project_files;
create policy "Signed-in users manage shared project files"
on public.project_files
for all
to authenticated
using (auth.uid() is not null)
with check (auth.uid() is not null);