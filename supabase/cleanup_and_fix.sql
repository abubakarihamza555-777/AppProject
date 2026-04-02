-- Clean up existing users and fix registration/login issues

-- Step 1: Clean up stuck users (delete problematic records)
DELETE FROM public.users WHERE email = 'abuumatanza@gmail.com';

-- Also delete from auth.users if needed (you may need to do this manually in Supabase Dashboard)
-- Go to Authentication -> Users and delete the user manually

-- Step 2: Drop and recreate the trigger function properly
DROP FUNCTION IF EXISTS public.create_user_profile();
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Step 3: Create a better trigger function
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Only create profile if user metadata exists
    IF NEW.raw_user_meta_data IS NOT NULL THEN
        INSERT INTO public.users (id, email, full_name, phone, role, is_active, created_at)
        VALUES (
            NEW.id,
            NEW.email,
            COALESCE(NEW.raw_user_meta_data->>'full_name', 'Unknown'),
            COALESCE(NEW.raw_user_meta_data->>'phone', ''),
            COALESCE(NEW.raw_user_meta_data->>'role', 'customer'),
            true,
            NOW()
        );
    END IF;
    RETURN NEW;
EXCEPTION
    WHEN unique_violation THEN
        -- User already exists, just return
        RETURN NEW;
END;
$$;

-- Step 4: Create the trigger
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- Step 5: Ensure RLS is properly configured
ALTER TABLE public.users DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- Step 6: Create simple RLS policies
DROP POLICY IF EXISTS "users_manage_own" ON public.users;

CREATE POLICY "users_manage_own" ON public.users
    FOR ALL USING (auth.uid() = id);

-- Step 7: Check if user exists function for login
CREATE OR REPLACE FUNCTION public.user_exists()
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.users 
        WHERE id = auth.uid()
    );
$$;
