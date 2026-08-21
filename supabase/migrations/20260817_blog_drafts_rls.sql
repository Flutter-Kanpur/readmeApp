-- Let authors read and manage their own unpublished blogs (drafts).
-- Safe to re-run: drops and recreates the policy.

alter table public.blogs enable row level security;

drop policy if exists "Authors can read own blogs" on public.blogs;
create policy "Authors can read own blogs"
  on public.blogs
  for select
  using (
    is_published = true
    or auth.uid() = author_id
  );

drop policy if exists "Authors can insert own blogs" on public.blogs;
create policy "Authors can insert own blogs"
  on public.blogs
  for insert
  with check (auth.uid() = author_id);

drop policy if exists "Authors can update own blogs" on public.blogs;
create policy "Authors can update own blogs"
  on public.blogs
  for update
  using (auth.uid() = author_id)
  with check (auth.uid() = author_id);

drop policy if exists "Authors can delete own blogs" on public.blogs;
create policy "Authors can delete own blogs"
  on public.blogs
  for delete
  using (auth.uid() = author_id);
