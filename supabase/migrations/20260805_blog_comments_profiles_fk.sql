-- PostgREST requires a foreign key to public.profiles for embedded selects.
-- blog_comments.user_id originally referenced auth.users only.

alter table public.blog_comments
  drop constraint if exists blog_comments_user_id_fkey;

alter table public.blog_comments
  add constraint blog_comments_user_id_fkey
  foreign key (user_id) references public.profiles (id) on delete cascade;
