-- Article support (likes). Run this in the Supabase SQL editor if migrations
-- are not applied automatically.
--
-- One like per user per blog. Public read of counts; write limited to the
-- authenticated user for their own rows.

create table if not exists public.blog_likes (
  id uuid primary key default gen_random_uuid(),
  blog_id uuid not null references public.blogs (blog_id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (blog_id, user_id)
);

create index if not exists blog_likes_blog_id_idx on public.blog_likes (blog_id);
create index if not exists blog_likes_user_id_idx on public.blog_likes (user_id);

alter table public.blog_likes enable row level security;

create policy "Anyone can read blog likes"
  on public.blog_likes
  for select
  using (true);

create policy "Users can like blogs"
  on public.blog_likes
  for insert
  with check (auth.uid() = user_id);

create policy "Users can unlike blogs"
  on public.blog_likes
  for delete
  using (auth.uid() = user_id);
