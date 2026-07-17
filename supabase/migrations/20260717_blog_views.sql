-- Blog view / read counts.
-- Run in the Supabase SQL editor if migrations are not applied automatically.
--
-- Stores a denormalized counter on blogs for cheap list queries, and an RPC
-- that any client can call when an article is opened.

alter table public.blogs
  add column if not exists view_count integer not null default 0;

create or replace function public.increment_blog_view(p_blog_id uuid)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  new_count integer;
begin
  update public.blogs
  set view_count = coalesce(view_count, 0) + 1
  where blog_id = p_blog_id
  returning view_count into new_count;

  return coalesce(new_count, 0);
end;
$$;

revoke all on function public.increment_blog_view(uuid) from public;
grant execute on function public.increment_blog_view(uuid) to anon, authenticated;
