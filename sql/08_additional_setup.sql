-- ============================================
-- 08: Additional setup and fixes
-- Run this after 00-07.
-- This script is safe to run multiple times.
-- ============================================

-- 1. Add the missing achievements module toggle.
ALTER TABLE public.settings ADD COLUMN IF NOT EXISTS show_milestones boolean DEFAULT true;

-- 2. Ensure all required storage buckets exist.
INSERT INTO storage.buckets (id, name, public)
VALUES ('photos', 'photos', true)
ON CONFLICT (id) DO NOTHING;

INSERT INTO storage.buckets (id, name, public)
VALUES ('music', 'music', true)
ON CONFLICT (id) DO NOTHING;

INSERT INTO storage.buckets (id, name, public)
VALUES ('avatars', 'avatars', true)
ON CONFLICT (id) DO NOTHING;

-- 3. Rebuild Storage RLS policies with explicit anon/authenticated roles.

-- avatars bucket policies
DROP POLICY IF EXISTS "Public Access Avatars" ON storage.objects;
DROP POLICY IF EXISTS "Public Insert Avatars" ON storage.objects;
DROP POLICY IF EXISTS "Public Update Avatars" ON storage.objects;
DROP POLICY IF EXISTS "Public Delete Avatars" ON storage.objects;

CREATE POLICY "Public Access Avatars" ON storage.objects
FOR SELECT TO anon, authenticated USING (bucket_id = 'avatars');

CREATE POLICY "Public Insert Avatars" ON storage.objects
FOR INSERT TO anon, authenticated WITH CHECK (bucket_id = 'avatars');

CREATE POLICY "Public Update Avatars" ON storage.objects
FOR UPDATE TO anon, authenticated USING (bucket_id = 'avatars');

CREATE POLICY "Public Delete Avatars" ON storage.objects
FOR DELETE TO anon, authenticated USING (bucket_id = 'avatars');

-- photos bucket policies
DROP POLICY IF EXISTS "Public Access Photos" ON storage.objects;
DROP POLICY IF EXISTS "Public Insert Photos" ON storage.objects;
DROP POLICY IF EXISTS "Public Update Photos" ON storage.objects;
DROP POLICY IF EXISTS "Public Delete Photos" ON storage.objects;

CREATE POLICY "Public Access Photos" ON storage.objects
FOR SELECT TO anon, authenticated USING (bucket_id = 'photos');

CREATE POLICY "Public Insert Photos" ON storage.objects
FOR INSERT TO anon, authenticated WITH CHECK (bucket_id = 'photos');

CREATE POLICY "Public Update Photos" ON storage.objects
FOR UPDATE TO anon, authenticated USING (bucket_id = 'photos');

CREATE POLICY "Public Delete Photos" ON storage.objects
FOR DELETE TO anon, authenticated USING (bucket_id = 'photos');

-- music bucket policies
DROP POLICY IF EXISTS "Public Access Music" ON storage.objects;
DROP POLICY IF EXISTS "Public Insert Music" ON storage.objects;
DROP POLICY IF EXISTS "Public Update Music" ON storage.objects;
DROP POLICY IF EXISTS "Public Delete Music" ON storage.objects;

CREATE POLICY "Public Access Music" ON storage.objects
FOR SELECT TO anon, authenticated USING (bucket_id = 'music');

CREATE POLICY "Public Insert Music" ON storage.objects
FOR INSERT TO anon, authenticated WITH CHECK (bucket_id = 'music');

CREATE POLICY "Public Update Music" ON storage.objects
FOR UPDATE TO anon, authenticated USING (bucket_id = 'music');

CREATE POLICY "Public Delete Music" ON storage.objects
FOR DELETE TO anon, authenticated USING (bucket_id = 'music');

-- 4. Insert initial settings to avoid the first-load 406 error.
-- Change these values later in the settings panel.
INSERT INTO public.settings (name1, name2, start_date, admin_password, password1_hash, password2_hash)
SELECT '她', '他', '2024-01-01', 'admin123', '123456', '654321'
WHERE NOT EXISTS (SELECT 1 FROM public.settings LIMIT 1);

-- 5. Reload PostgREST schema cache.
NOTIFY pgrst, 'reload schema';
