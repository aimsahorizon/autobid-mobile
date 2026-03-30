-- Enable UUID extension if not enabled
create extension if not exists "uuid-ossp";

-- Create Regions Table
create table addr_regions (
  id uuid primary key default uuid_generate_v4(),
  name text not null,
  code text, -- e.g., 'IX', 'NCR'
  is_active boolean default false,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Create Provinces Table
create table addr_provinces (
  id uuid primary key default uuid_generate_v4(),
  region_id uuid references addr_regions(id) on delete cascade not null,
  name text not null,
  is_active boolean default false,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Create Cities/Municipalities Table
create table addr_cities (
  id uuid primary key default uuid_generate_v4(),
  province_id uuid references addr_provinces(id) on delete cascade not null,
  name text not null,
  is_active boolean default false,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Create Barangays Table
create table addr_barangays (
  id uuid primary key default uuid_generate_v4(),
  city_id uuid references addr_cities(id) on delete cascade not null,
  name text not null,
  is_active boolean default false,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS
alter table addr_regions enable row level security;
alter table addr_provinces enable row level security;
alter table addr_cities enable row level security;
alter table addr_barangays enable row level security;

-- Policies: Public Read (Active Only)
create policy "Public regions are viewable by everyone" on addr_regions
  for select using (true); -- Currently allow seeing all, but frontend filters active? Or filtering here. 
  -- Better to filter active here for public users, but admins need to see all.
  -- For simplicity in this migration, let's allow read all and filter in app or create separate policies.
  -- Let's stick to "Everyone can read everything" for now to avoid complexity, app will filter is_active=true.
  
create policy "Public read access" on addr_regions for select using (true);
create policy "Public read access" on addr_provinces for select using (true);
create policy "Public read access" on addr_cities for select using (true);
create policy "Public read access" on addr_barangays for select using (true);

-- Policies: Admin Write (All)
-- Assuming a function or claim exists for 'admin', or relying on Supabase service role for seeding.
-- Real-world app would check auth.jwt() ->> 'role' or similar.
create policy "Admin full access" on addr_regions for all using (auth.role() = 'service_role');
create policy "Admin full access" on addr_provinces for all using (auth.role() = 'service_role');
create policy "Admin full access" on addr_cities for all using (auth.role() = 'service_role');
create policy "Admin full access" on addr_barangays for all using (auth.role() = 'service_role');


-- SEED DATA (Zamboanga City - Region IX)

do $$
declare
  region_ix_id uuid;
  zambo_sur_id uuid;
  zambo_city_id uuid;
begin
  -- 1. Insert Region IX
  insert into addr_regions (name, code, is_active)
  values ('Region IX (Zamboanga Peninsula)', 'IX', true)
  returning id into region_ix_id;

  -- 2. Insert Province (Zamboanga del Sur)
  insert into addr_provinces (region_id, name, is_active)
  values (region_ix_id, 'Zamboanga del Sur', true)
  returning id into zambo_sur_id;

  -- 3. Insert City (Zamboanga City)
  insert into addr_cities (province_id, name, is_active)
  values (zambo_sur_id, 'Zamboanga City', true)
  returning id into zambo_city_id;

  -- 4. Insert Barangays
  insert into addr_barangays (city_id, name, is_active)
  values 
    (zambo_city_id, 'Ayala', true),
    (zambo_city_id, 'Baliwasan', true),
    (zambo_city_id, 'Baluno', true),
    (zambo_city_id, 'Boalan', true),
    (zambo_city_id, 'Bolong', true),
    (zambo_city_id, 'Buenavista', true),
    (zambo_city_id, 'Bunguiao', true),
    (zambo_city_id, 'Busay', true),
    (zambo_city_id, 'Cabaluay', true),
    (zambo_city_id, 'Cabatangan', true),
    (zambo_city_id, 'Cacao', true),
    (zambo_city_id, 'Calarian', true),
    (zambo_city_id, 'Camino Nuevo', true),
    (zambo_city_id, 'Campo Islam', true),
    (zambo_city_id, 'Canelar', true),
    (zambo_city_id, 'Capisan', true),
    (zambo_city_id, 'Cawit', true),
    (zambo_city_id, 'Culianan', true),
    (zambo_city_id, 'Curuan', true),
    (zambo_city_id, 'Divisoria', true),
    (zambo_city_id, 'Dulian', true),
    (zambo_city_id, 'Guiwan', true),
    (zambo_city_id, 'Kasanyangan', true),
    (zambo_city_id, 'La Paz', true),
    (zambo_city_id, 'Labuan', true),
    (zambo_city_id, 'Lamisahan', true),
    (zambo_city_id, 'Limpapa', true),
    (zambo_city_id, 'Lubigan', true),
    (zambo_city_id, 'Lumayang', true),
    (zambo_city_id, 'Lumbangan', true),
    (zambo_city_id, 'Lunzuran', true),
    (zambo_city_id, 'Maasin', true),
    (zambo_city_id, 'Malagutay', true),
    (zambo_city_id, 'Mampang', true),
    (zambo_city_id, 'Manalipa', true),
    (zambo_city_id, 'Mangusu', true),
    (zambo_city_id, 'Manicahan', true),
    (zambo_city_id, 'Mariki', true),
    (zambo_city_id, 'Mercedes', true),
    (zambo_city_id, 'Muti', true),
    (zambo_city_id, 'Pamucutan', true),
    (zambo_city_id, 'Pasilmanta', true),
    (zambo_city_id, 'Pasobolong', true),
    (zambo_city_id, 'Pasonanca', true),
    (zambo_city_id, 'Patalon', true),
    (zambo_city_id, 'Putik', true),
    (zambo_city_id, 'Quiniput', true),
    (zambo_city_id, 'Recodo', true),
    (zambo_city_id, 'Rio Hondo', true),
    (zambo_city_id, 'Salaan', true),
    (zambo_city_id, 'San Jose Cawa-Cawa', true),
    (zambo_city_id, 'San Jose Gusu', true),
    (zambo_city_id, 'San Roque', true),
    (zambo_city_id, 'Sangali', true),
    (zambo_city_id, 'Santa Barbara', true),
    (zambo_city_id, 'Santa Catalina', true),
    (zambo_city_id, 'Santa Cruz', true),
    (zambo_city_id, 'Santa Maria', true),
    (zambo_city_id, 'Santo Niño', true),
    (zambo_city_id, 'Sibulao', true),
    (zambo_city_id, 'Sinubong', true),
    (zambo_city_id, 'Sinunuc', true),
    (zambo_city_id, 'Tagasilay', true),
    (zambo_city_id, 'Taguiti', true),
    (zambo_city_id, 'Talabaan', true),
    (zambo_city_id, 'Talisayan', true),
    (zambo_city_id, 'Talon-Talon', true),
    (zambo_city_id, 'Taluksangay', true),
    (zambo_city_id, 'Tetuan', true),
    (zambo_city_id, 'Tictapul', true),
    (zambo_city_id, 'Tigbalabag', true),
    (zambo_city_id, 'Tigtabon', true),
    (zambo_city_id, 'Tolosa', true),
    (zambo_city_id, 'Tugbungan', true),
    (zambo_city_id, 'Tulungatung', true),
    (zambo_city_id, 'Tumaga', true),
    (zambo_city_id, 'Tumalutap', true),
    (zambo_city_id, 'Upper Calarian', true),
    (zambo_city_id, 'Victoria', true),
    (zambo_city_id, 'Vitali', true),
    (zambo_city_id, 'Zambowood', true),
    (zambo_city_id, 'Zone I', true),
    (zambo_city_id, 'Zone II', true),
    (zambo_city_id, 'Zone III', true),
    (zambo_city_id, 'Zone IV', true);
    
end $$;
