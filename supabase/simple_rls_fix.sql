-- Simple fix for infinite recursion
-- Run this in Supabase SQL Editor

-- Step 1: Disable RLS temporarily to allow access
ALTER TABLE public.users DISABLE ROW LEVEL SECURITY;

-- Step 2: Drop the problematic function
DROP FUNCTION IF EXISTS public.is_admin();

-- Step 3: Create a simpler admin check that doesn't reference users table
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Check if current user's role in auth metadata is 'admin'
    -- This avoids the circular reference
    RETURN COALESCE(
        (
            SELECT raw_user_meta_data->>'role' = 'admin'
            FROM auth.users
            WHERE id = auth.uid()
        ),
        false
    );
END;
$$;

-- Step 4: Create simple, non-recursive policies
DROP POLICY IF EXISTS "users_select_self_or_admin" ON public.users;
DROP POLICY IF EXISTS "users_insert_self" ON public.users;
DROP POLICY IF EXISTS "users_insert_admin" ON public.users;
DROP POLICY IF EXISTS "users_update_self_or_admin" ON public.users;

-- Allow users to manage their own data
CREATE POLICY "users_manage_own" ON public.users
    FOR ALL USING (auth.uid() = id);

-- Step 5: Re-enable RLS
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
