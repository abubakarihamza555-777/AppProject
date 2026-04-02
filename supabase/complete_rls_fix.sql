-- Complete RLS fix for user registration
-- Run this in your Supabase SQL Editor

-- First, let's check current policies
SELECT * FROM pg_policies WHERE tablename = 'users';

-- Drop existing policies on users table to start fresh
DROP POLICY IF EXISTS "users_select_self_or_admin" ON public.users;
DROP POLICY IF EXISTS "users_update_self_or_admin" ON public.users;
DROP POLICY IF EXISTS "users_insert_self" ON public.users;
DROP POLICY IF EXISTS "users_insert_admin" ON public.users;

-- Create comprehensive policies for users table
-- Allow users to see their own data
CREATE POLICY "users_select_self" ON public.users
    FOR SELECT USING (auth.uid() = id);

-- Allow users to insert their own data (for registration)
CREATE POLICY "users_insert_self" ON public.users
    FOR INSERT WITH CHECK (auth.uid() = id);

-- Allow users to update their own data
CREATE POLICY "users_update_self" ON public.users
    FOR UPDATE USING (auth.uid() = id);

-- Allow admins full access
CREATE POLICY "users_admin_all" ON public.users
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() AND role = 'admin' AND is_active = true
        )
    );

-- Alternative approach: Create a function to handle user creation
CREATE OR REPLACE FUNCTION public.create_user_profile()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    INSERT INTO public.users (id, email, full_name, phone, role, is_active, created_at)
    VALUES (
        NEW.id,
        NEW.email,
        NEW.raw_user_meta_data->>'full_name',
        NEW.raw_user_meta_data->>'phone',
        NEW.raw_user_meta_data->>'role',
        true,
        NOW()
    );
    RETURN NEW;
END;
$$;

-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Create trigger to automatically create user profile
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    WHEN (NEW.raw_user_meta_data IS NOT NULL)
    EXECUTE FUNCTION public.create_user_profile();

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO anon;
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON public.users TO authenticated;
GRANT SELECT ON public.users TO anon;
