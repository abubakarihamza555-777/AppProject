-- Water Delivery App (Supabase/Postgres) schema
-- Designed to match the Flutter models & services in /lib.

begin;

-- Extensions
create extension if not exists "pgcrypto";

-- Enums (stored as text in app; enums optional)

-- Public profile table (mirrors auth.users id)
create table if not exists public.users (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null unique,
  full_name text not null,
  phone text not null,
  role text not null check (role in ('customer','vendor','admin')),
  address text,
  profile_image text,
  is_active boolean not null default true,
  suspended_at timestamptz,
  created_at timestamptz not null default now()
);

-- Optional customer profile (code references customers in joins)
create table if not exists public.customers (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references public.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  updated_at timestamptz
);

create table if not exists public.vendors (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references public.users(id) on delete cascade,
  business_name text not null,
  business_phone text not null,
  business_address text not null,
  business_license text,
  profile_image text,
  rating double precision not null default 0,
  total_deliveries integer not null default 0,
  is_active boolean not null default true,
  is_verified boolean not null default false,
  verified_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz
);

create index if not exists vendors_is_active_idx on public.vendors (is_active);
create index if not exists vendors_is_verified_idx on public.vendors (is_verified);

create table if not exists public.water_requests (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references public.users(id) on delete cascade,
  vendor_id uuid not null references public.vendors(id) on delete restrict,
  water_type text not null,
  quantity integer not null check (quantity > 0),
  price_per_unit double precision not null check (price_per_unit >= 0),
  total_price double precision not null check (total_price >= 0),
  delivery_address text not null,
  status text not null default 'pending',
  created_at timestamptz not null default now(),
  updated_at timestamptz
);

create index if not exists water_requests_customer_idx on public.water_requests (customer_id);
create index if not exists water_requests_vendor_idx on public.water_requests (vendor_id);
create index if not exists water_requests_status_idx on public.water_requests (status);

create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references public.users(id) on delete cascade,
  vendor_id uuid not null references public.vendors(id) on delete restrict,
  water_type text not null,
  quantity integer not null check (quantity > 0),
  total_price double precision not null check (total_price >= 0),
  delivery_address text not null,
  payment_method text not null,
  status text not null default 'pending',
  delivery_date timestamptz,
  tracking_number text,
  created_at timestamptz not null default now(),
  updated_at timestamptz
);

create index if not exists orders_customer_idx on public.orders (customer_id);
create index if not exists orders_vendor_idx on public.orders (vendor_id);
create index if not exists orders_status_idx on public.orders (status);
create index if not exists orders_created_at_idx on public.orders (created_at desc);

create table if not exists public.payments (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  customer_id uuid not null references public.users(id) on delete cascade,
  vendor_id uuid not null references public.vendors(id) on delete restrict,
  amount double precision not null check (amount >= 0),
  method text not null,
  status text not null default 'pending',
  transaction_id text,
  created_at timestamptz not null default now(),
  completed_at timestamptz
);

create index if not exists payments_order_idx on public.payments (order_id);
create index if not exists payments_status_idx on public.payments (status);

create table if not exists public.deliveries (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null unique references public.orders(id) on delete cascade,
  vendor_id uuid not null references public.vendors(id) on delete restrict,
  driver_id uuid not null references public.users(id) on delete restrict,
  status text not null default 'assigned',
  assigned_at timestamptz not null default now(),
  picked_up_at timestamptz,
  delivered_at timestamptz,
  tracking_number text
);

create index if not exists deliveries_vendor_idx on public.deliveries (vendor_id);
create index if not exists deliveries_driver_idx on public.deliveries (driver_id);

create table if not exists public.earnings (
  id uuid primary key default gen_random_uuid(),
  vendor_id uuid not null references public.vendors(id) on delete cascade,
  order_id uuid not null unique references public.orders(id) on delete cascade,
  amount double precision not null check (amount >= 0),
  status text not null default 'pending',
  created_at timestamptz not null default now(),
  paid_at timestamptz
);

create index if not exists earnings_vendor_idx on public.earnings (vendor_id);

create table if not exists public.conversations (
  id text primary key,
  created_at timestamptz not null default now()
);

create table if not exists public.chat_messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id text not null references public.conversations(id) on delete cascade,
  sender_id uuid not null references public.users(id) on delete cascade,
  receiver_id uuid not null references public.users(id) on delete cascade,
  message text not null,
  message_type text not null default 'text',
  is_read boolean not null default false,
  sent_at timestamptz not null default now(),
  delivered_at timestamptz,
  read_at timestamptz
);

create index if not exists chat_messages_conversation_idx on public.chat_messages (conversation_id, sent_at desc);

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  title text not null,
  body text not null,
  type text not null,
  data jsonb,
  is_read boolean not null default false,
  created_at timestamptz not null default now(),
  read_at timestamptz
);

create index if not exists notifications_user_idx on public.notifications (user_id, created_at desc);

create table if not exists public.reports (
  id uuid primary key default gen_random_uuid(),
  type text not null,
  start_date timestamptz not null,
  end_date timestamptz not null,
  data jsonb not null,
  generated_by uuid not null references public.users(id) on delete restrict,
  generated_at timestamptz not null default now(),
  file_url text not null
);

-- RLS
alter table public.users enable row level security;
alter table public.customers enable row level security;
alter table public.vendors enable row level security;
alter table public.water_requests enable row level security;
alter table public.orders enable row level security;
alter table public.payments enable row level security;
alter table public.deliveries enable row level security;
alter table public.earnings enable row level security;
alter table public.conversations enable row level security;
alter table public.chat_messages enable row level security;
alter table public.notifications enable row level security;
alter table public.reports enable row level security;

-- Helper: treat admins as service users (role stored in public.users)
create or replace function public.is_admin()
returns boolean
language sql
stable
as $$
  select exists (
    select 1 from public.users u
    where u.id = auth.uid()
      and u.role = 'admin'
      and u.is_active = true
  );
$$;

-- users: self-read/write; admins read all
create policy "users_select_self_or_admin"
on public.users for select
using (id = auth.uid() or public.is_admin());

create policy "users_update_self_or_admin"
on public.users for update
using (id = auth.uid() or public.is_admin())
with check (id = auth.uid() or public.is_admin());

-- customers: self or admin
create policy "customers_select_self_or_admin"
on public.customers for select
using (user_id = auth.uid() or public.is_admin());

create policy "customers_insert_self"
on public.customers for insert
with check (user_id = auth.uid());

create policy "customers_update_self_or_admin"
on public.customers for update
using (user_id = auth.uid() or public.is_admin())
with check (user_id = auth.uid() or public.is_admin());

-- vendors: anyone can read active verified vendors; vendor owner can read/update own; admin all
create policy "vendors_select_public_active_verified"
on public.vendors for select
using (
  public.is_admin()
  or user_id = auth.uid()
  or (is_active = true and is_verified = true)
);

create policy "vendors_insert_owner"
on public.vendors for insert
with check (user_id = auth.uid());

create policy "vendors_update_owner_or_admin"
on public.vendors for update
using (user_id = auth.uid() or public.is_admin())
with check (user_id = auth.uid() or public.is_admin());

-- orders: customer/vendor/admin visibility
create policy "orders_select_customer_vendor_admin"
on public.orders for select
using (
  public.is_admin()
  or customer_id = auth.uid()
  or exists (select 1 from public.vendors v where v.id = vendor_id and v.user_id = auth.uid())
);

create policy "orders_insert_customer"
on public.orders for insert
with check (customer_id = auth.uid());

create policy "orders_update_customer_vendor_admin"
on public.orders for update
using (
  public.is_admin()
  or customer_id = auth.uid()
  or exists (select 1 from public.vendors v where v.id = vendor_id and v.user_id = auth.uid())
)
with check (
  public.is_admin()
  or customer_id = auth.uid()
  or exists (select 1 from public.vendors v where v.id = vendor_id and v.user_id = auth.uid())
);

-- water_requests: customer/vendor/admin
create policy "water_requests_select_customer_vendor_admin"
on public.water_requests for select
using (
  public.is_admin()
  or customer_id = auth.uid()
  or exists (select 1 from public.vendors v where v.id = vendor_id and v.user_id = auth.uid())
);

create policy "water_requests_insert_customer"
on public.water_requests for insert
with check (customer_id = auth.uid());

create policy "water_requests_update_customer_vendor_admin"
on public.water_requests for update
using (
  public.is_admin()
  or customer_id = auth.uid()
  or exists (select 1 from public.vendors v where v.id = vendor_id and v.user_id = auth.uid())
)
with check (
  public.is_admin()
  or customer_id = auth.uid()
  or exists (select 1 from public.vendors v where v.id = vendor_id and v.user_id = auth.uid())
);

-- payments: customer/vendor/admin
create policy "payments_select_customer_vendor_admin"
on public.payments for select
using (
  public.is_admin()
  or customer_id = auth.uid()
  or exists (select 1 from public.vendors v where v.id = vendor_id and v.user_id = auth.uid())
);

create policy "payments_insert_customer"
on public.payments for insert
with check (customer_id = auth.uid());

create policy "payments_update_vendor_admin"
on public.payments for update
using (
  public.is_admin()
  or exists (select 1 from public.vendors v where v.id = vendor_id and v.user_id = auth.uid())
)
with check (
  public.is_admin()
  or exists (select 1 from public.vendors v where v.id = vendor_id and v.user_id = auth.uid())
);

-- deliveries/earnings: vendor/admin
create policy "deliveries_select_vendor_admin"
on public.deliveries for select
using (
  public.is_admin()
  or driver_id = auth.uid()
  or exists (select 1 from public.vendors v where v.id = vendor_id and v.user_id = auth.uid())
);

create policy "deliveries_insert_vendor_admin"
on public.deliveries for insert
with check (
  public.is_admin()
  or exists (select 1 from public.vendors v where v.id = vendor_id and v.user_id = auth.uid())
);

create policy "deliveries_update_vendor_admin"
on public.deliveries for update
using (
  public.is_admin()
  or driver_id = auth.uid()
  or exists (select 1 from public.vendors v where v.id = vendor_id and v.user_id = auth.uid())
)
with check (
  public.is_admin()
  or driver_id = auth.uid()
  or exists (select 1 from public.vendors v where v.id = vendor_id and v.user_id = auth.uid())
);

create policy "earnings_select_vendor_admin"
on public.earnings for select
using (
  public.is_admin()
  or exists (select 1 from public.vendors v where v.id = vendor_id and v.user_id = auth.uid())
);

create policy "earnings_insert_vendor_admin"
on public.earnings for insert
with check (
  public.is_admin()
  or exists (select 1 from public.vendors v where v.id = vendor_id and v.user_id = auth.uid())
);

create policy "earnings_update_vendor_admin"
on public.earnings for update
using (
  public.is_admin()
  or exists (select 1 from public.vendors v where v.id = vendor_id and v.user_id = auth.uid())
)
with check (
  public.is_admin()
  or exists (select 1 from public.vendors v where v.id = vendor_id and v.user_id = auth.uid())
);

-- conversations/chat: participants or admin
create policy "conversations_select_admin_only"
on public.conversations for select
using (public.is_admin());

create policy "chat_messages_select_participants_admin"
on public.chat_messages for select
using (
  public.is_admin()
  or sender_id = auth.uid()
  or receiver_id = auth.uid()
);

create policy "chat_messages_insert_sender"
on public.chat_messages for insert
with check (sender_id = auth.uid());

create policy "chat_messages_update_participants_admin"
on public.chat_messages for update
using (
  public.is_admin()
  or sender_id = auth.uid()
  or receiver_id = auth.uid()
)
with check (
  public.is_admin()
  or sender_id = auth.uid()
  or receiver_id = auth.uid()
);

-- notifications: self or admin
create policy "notifications_select_self_or_admin"
on public.notifications for select
using (user_id = auth.uid() or public.is_admin());

create policy "notifications_update_self_or_admin"
on public.notifications for update
using (user_id = auth.uid() or public.is_admin())
with check (user_id = auth.uid() or public.is_admin());

-- reports: admin only
create policy "reports_admin_only"
on public.reports for all
using (public.is_admin())
with check (public.is_admin());

commit;

