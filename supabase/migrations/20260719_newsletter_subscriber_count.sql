-- Public subscriber counts without exposing emails.
-- Same as readme_website/supabase/migrations/013_newsletter_subscriber_count.sql.
-- Run in the Supabase SQL editor if not already applied.

create or replace function public.get_community_newsletter_subscriber_count(
  p_community_id uuid
)
returns integer
language sql
security definer
set search_path = public
stable
as $$
  select coalesce(count(*)::integer, 0)
  from public.community_newsletter_subscribers
  where community_id = p_community_id;
$$;

revoke all on function public.get_community_newsletter_subscriber_count(uuid) from public;
grant execute on function public.get_community_newsletter_subscriber_count(uuid)
  to anon, authenticated;
