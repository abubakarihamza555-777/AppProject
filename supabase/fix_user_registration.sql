-- Fix for user registration RLS policy
-- This adds the missing INSERT policy for the users table

-- Allow users to insert their own record during registration
create policy "users_insert_self"
on public.users for insert
with check (id = auth.uid());

-- Also allow admins to insert users (for admin-created accounts)
create policy "users_insert_admin"
on public.users for insert
with check (public.is_admin());
