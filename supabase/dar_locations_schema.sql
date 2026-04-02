-- Dar es Salaam Water Delivery App - Updated Schema
-- Includes locations and vendor service areas

begin;

-- Districts and Wards for Dar es Salaam
CREATE TABLE IF NOT EXISTS public.districts (
  id serial PRIMARY KEY,
  name text NOT NULL UNIQUE,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.wards (
  id serial PRIMARY KEY,
  name text NOT NULL,
  district_id integer NOT NULL REFERENCES public.districts(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(name, district_id)
);

-- Insert Dar es Salaam Districts
INSERT INTO public.districts (name) VALUES
('Kinondoni'),
('Ilala'), 
('Temeke'),
('Kigamboni'),
('Ubungo')
ON CONFLICT (name) DO NOTHING;

-- Insert Wards for each district
INSERT INTO public.wards (name, district_id) VALUES
-- Kinondoni Wards
('Hananasifu', 1), ('Kawe', 1), ('Kijitonyama', 1), ('Kigogo', 1),
('Kinondoni', 1), ('Kisutu', 1), ('Magomeni', 1), ('Makumbusho', 1),
('Manzese', 1), ('Mwananyamala', 1), ('Ndugumbi', 1), ('Oysterbay', 1),
('Regent', 1), ('Tandale', 1), ('Ubungo', 1), ('Ukonga', 1),

-- Ilala Wards  
('Buguruni', 2), ('Chang''ombe', 2), ('Gerezani', 2), ('Ilala', 2),
('Kariakoo', 2), ('Kisutu', 2), ('Kivukoni', 2), ('Mchikichini', 2),
('Mchafukoge', 2), ('Mikocheni', 2), ('Mzimuni', 2), ('Pugu', 2),
('Segerea', 2), ('Tabata', 2), ('Vingunguti', 2), ('Upanga', 2),

-- Temeke Wards
('Azimio', 3), ('Buza', 3), ('Changani', 3), ('Changombe', 3),
('Kijichi', 3), ('Kurasini', 3), ('Mbagala', 3), ('Mtoni', 3),
('Temeke', 3), ('Tunduru', 3), ('Yombo', 3), ('Mwembe', 3),

-- Kigamboni Wards
('Ferry', 4), ('Kigamboni', 4), ('Kimanga', 4), ('Mji Mwema', 4),
('SOMA', 4), ('Tungi', 4), ('Vijibweni', 4),

-- Ubungo Wards
('Kibaha', 5), ('Kisarawe', 5), ('Mabwepande', 5), ('Mabwepande', 5),
('Mbezi', 5), ('Msasani', 5), ('Mwenge', 5)
ON CONFLICT (name, district_id) DO NOTHING;

-- Update users table to include location details
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS district_id integer REFERENCES public.districts(id);
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS ward_id integer REFERENCES public.wards(id);
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS street_name text;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS house_number text;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS landmark text;
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS is_truck_accessible boolean DEFAULT true;

-- Update vendors table to include service areas
ALTER TABLE public.vendors ADD COLUMN IF NOT EXISTS service_areas text[]; -- Array of ward IDs
ALTER TABLE public.vendors ADD COLUMN IF NOT EXISTS vehicle_type text CHECK (vehicle_type IN ('small_truck', 'large_tanker', 'both'));
ALTER TABLE public.vendors ADD COLUMN IF NOT EXISTS max_liters_per_trip integer;
ALTER TABLE public.vendors ADD COLUMN IF NOT EXISTS default_delivery_fee_per_10l integer DEFAULT 100;
ALTER TABLE public.vendors ADD COLUMN IF NOT EXISTS can_negotiate_large_orders boolean DEFAULT false;

-- Update orders table to include detailed location and pricing
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS delivery_district_id integer REFERENCES public.districts(id);
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS delivery_ward_id integer REFERENCES public.wards(id);
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS delivery_street text;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS delivery_house_number text;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS delivery_landmark text;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS delivery_notes text;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS water_cost integer;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS delivery_fee integer;
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS use_alternative_address boolean DEFAULT false;

-- Order status enum
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS status text 
CHECK (status IN ('pending', 'accepted', 'out_for_delivery', 'delivered', 'cancelled'));

-- Create order tracking table
CREATE TABLE IF NOT EXISTS public.order_tracking (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  status text not null,
  notes text,
  created_by uuid references public.users(id),
  created_at timestamptz not null default now()
);

-- Update RLS policies for new columns
DROP POLICY IF EXISTS "users_manage_own" ON public.users;
CREATE POLICY "users_manage_own" ON public.users
    FOR ALL USING (auth.uid() = id);

-- Enable RLS on new tables
ALTER TABLE public.districts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wards ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_tracking ENABLE ROW LEVEL SECURITY;

-- Public read access for districts and wards
CREATE POLICY "districts_public_read" ON public.districts
    FOR SELECT USING (true);

CREATE POLICY "wards_public_read" ON public.wards
    FOR SELECT USING (true);

-- Order tracking policies
CREATE POLICY "order_tracking_customer_vendor" ON public.order_tracking
    FOR SELECT USING (
        auth.uid() IN (
            SELECT customer_id FROM public.orders WHERE id = order_id
        )
        OR auth.uid() IN (
            SELECT user_id FROM public.vendors v 
            JOIN public.orders o ON o.vendor_id = v.id 
            WHERE o.id = order_id
        )
    );

CREATE POLICY "order_tracking_insert" ON public.order_tracking
    FOR INSERT WITH CHECK (
        auth.uid() IN (
            SELECT user_id FROM public.vendors v 
            JOIN public.orders o ON o.vendor_id = v.id 
            WHERE o.id = order_id
        )
    );

commit;
