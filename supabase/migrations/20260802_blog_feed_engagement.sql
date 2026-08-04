-- Feed freshness + denormalized engagement counters.
-- Run in the Supabase SQL editor before deploy if migrations are not applied automatically.

-- 1) Publish timestamp for feed ordering (drafts keep old created_at).
ALTER TABLE public.blogs
  ADD COLUMN IF NOT EXISTS published_at timestamptz;

UPDATE public.blogs
SET published_at = COALESCE(created_at, now())
WHERE is_published = true
  AND published_at IS NULL;

-- 2) Denormalized like_count (list + detail read the same column).
ALTER TABLE public.blogs
  ADD COLUMN IF NOT EXISTS like_count integer NOT NULL DEFAULT 0;

UPDATE public.blogs b
SET like_count = COALESCE(agg.cnt, 0)
FROM (
  SELECT blog_id, COUNT(*)::integer AS cnt
  FROM public.blog_likes
  GROUP BY blog_id
) AS agg
WHERE b.blog_id = agg.blog_id;

CREATE OR REPLACE FUNCTION public.blogs_like_count_from_likes()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE public.blogs
    SET like_count = COALESCE(like_count, 0) + 1
    WHERE blog_id = NEW.blog_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE public.blogs
    SET like_count = GREATEST(COALESCE(like_count, 0) - 1, 0)
    WHERE blog_id = OLD.blog_id;
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS trg_blog_likes_like_count ON public.blog_likes;
CREATE TRIGGER trg_blog_likes_like_count
AFTER INSERT OR DELETE ON public.blog_likes
FOR EACH ROW
EXECUTE PROCEDURE public.blogs_like_count_from_likes();

-- 3) Feed index
CREATE INDEX IF NOT EXISTS blogs_published_feed_idx
  ON public.blogs (is_published, published_at DESC NULLS LAST)
  WHERE is_published = true;

-- Note: view_count must continue to be updated by increment_blog_view RPC.
