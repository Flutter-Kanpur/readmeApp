-- Blog responses (comments) with one-level replies and comment likes.

create table if not exists public.blog_comments (
  id uuid primary key default gen_random_uuid(),
  blog_id uuid not null references public.blogs (blog_id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  parent_id uuid references public.blog_comments (id) on delete cascade,
  body text not null check (char_length(trim(body)) > 0),
  like_count integer not null default 0,
  created_at timestamptz not null default now(),
  constraint blog_comments_not_self_parent check (
    parent_id is null or parent_id <> id
  )
);

create index if not exists blog_comments_blog_id_created_at_idx
  on public.blog_comments (blog_id, created_at);

create index if not exists blog_comments_parent_id_created_at_idx
  on public.blog_comments (parent_id, created_at)
  where parent_id is not null;

-- Replies may only attach to top-level comments (parent_id is null).
create or replace function public.blog_comments_enforce_one_level_reply()
returns trigger
language plpgsql
as $$
declare
  parent_row public.blog_comments%rowtype;
begin
  if new.parent_id is null then
    return new;
  end if;

  select * into parent_row
  from public.blog_comments
  where id = new.parent_id;

  if not found then
    raise exception 'Parent comment not found';
  end if;

  if parent_row.parent_id is not null then
    raise exception 'Replies can only attach to top-level comments';
  end if;

  if parent_row.blog_id <> new.blog_id then
    raise exception 'Reply must belong to the same blog as the parent comment';
  end if;

  return new;
end;
$$;

drop trigger if exists trg_blog_comments_one_level_reply on public.blog_comments;
create trigger trg_blog_comments_one_level_reply
before insert or update of parent_id, blog_id on public.blog_comments
for each row
execute function public.blog_comments_enforce_one_level_reply();

create table if not exists public.blog_comment_likes (
  id uuid primary key default gen_random_uuid(),
  comment_id uuid not null references public.blog_comments (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (comment_id, user_id)
);

create index if not exists blog_comment_likes_comment_id_idx
  on public.blog_comment_likes (comment_id);

create index if not exists blog_comment_likes_user_id_idx
  on public.blog_comment_likes (user_id);

create or replace function public.blog_comments_like_count_from_likes()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'INSERT' then
    update public.blog_comments
    set like_count = coalesce(like_count, 0) + 1
    where id = new.comment_id;
    return new;
  elsif tg_op = 'DELETE' then
    update public.blog_comments
    set like_count = greatest(coalesce(like_count, 0) - 1, 0)
    where id = old.comment_id;
    return old;
  end if;
  return null;
end;
$$;

drop trigger if exists trg_blog_comment_likes_like_count on public.blog_comment_likes;
create trigger trg_blog_comment_likes_like_count
after insert or delete on public.blog_comment_likes
for each row
execute function public.blog_comments_like_count_from_likes();

alter table public.blog_comments enable row level security;
alter table public.blog_comment_likes enable row level security;

create policy "Anyone can read blog comments"
  on public.blog_comments
  for select
  using (true);

create policy "Users can post blog comments"
  on public.blog_comments
  for insert
  with check (auth.uid() = user_id);

create policy "Users can delete own blog comments"
  on public.blog_comments
  for delete
  using (auth.uid() = user_id);

create policy "Anyone can read blog comment likes"
  on public.blog_comment_likes
  for select
  using (true);

create policy "Users can like blog comments"
  on public.blog_comment_likes
  for insert
  with check (auth.uid() = user_id);

create policy "Users can unlike blog comments"
  on public.blog_comment_likes
  for delete
  using (auth.uid() = user_id);
