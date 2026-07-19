-- Lightweight list previews without selecting full blogs.content (egress).
-- Trigger keeps excerpt in sync for web (HTML) and Flutter (Quill JSON) writes.

ALTER TABLE public.blogs
  ADD COLUMN IF NOT EXISTS excerpt text;

CREATE OR REPLACE FUNCTION public.blogs_set_excerpt()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  plain text;
BEGIN
  plain := coalesce(NEW.content, '');

  -- Quill Delta JSON from the mobile app: pull "insert" string values.
  IF left(ltrim(plain), 1) IN ('[', '{') THEN
    plain := regexp_replace(
      plain,
      '"insert"\s*:\s*"((?:\\.|[^"\\])*)"',
      E'\\1 ',
      'g'
    );
    plain := regexp_replace(plain, '\\n', ' ', 'g');
    plain := regexp_replace(plain, '\\t', ' ', 'g');
  END IF;

  -- HTML from the web editor
  plain := regexp_replace(plain, '<[^>]+>', ' ', 'g');
  plain := replace(plain, '&nbsp;', ' ');
  plain := replace(plain, '&amp;', '&');
  plain := replace(plain, '&lt;', '<');
  plain := replace(plain, '&gt;', '>');
  plain := replace(plain, '&quot;', '"');
  plain := regexp_replace(plain, '\s+', ' ', 'g');
  plain := trim(plain);

  IF char_length(plain) > 320 THEN
    NEW.excerpt := left(plain, 320) || '…';
  ELSE
    NEW.excerpt := NULLIF(plain, '');
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS blogs_set_excerpt_trg ON public.blogs;
CREATE TRIGGER blogs_set_excerpt_trg
  BEFORE INSERT OR UPDATE OF content ON public.blogs
  FOR EACH ROW
  EXECUTE FUNCTION public.blogs_set_excerpt();

-- Backfill existing rows (one-time; does not increase ongoing egress).
UPDATE public.blogs
SET content = content
WHERE excerpt IS NULL AND content IS NOT NULL AND content <> '';
