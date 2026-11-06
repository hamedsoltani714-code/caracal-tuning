-- CARACAL TUNING: central vehicle catalog and educational resource metadata.
-- The existing public.vehicles table remains the user's personal garage.
-- Raw ECU calibration/dump files are intentionally not part of this catalog.

create table if not exists public.vehicle_catalog (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  make_id text not null,
  make_fa text not null,
  make_en text not null,
  model_fa text not null,
  model_en text not null,
  body_type text not null default 'other',
  year_start integer,
  year_end integer,
  summary_fa text not null default '',
  summary_en text not null default '',
  data_status text not null default 'model-index-only',
  is_verified boolean not null default false,
  is_published boolean not null default false,
  source_label text,
  source_url text,
  license_note text,
  sort_order integer not null default 100,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint vehicle_catalog_years_valid check (
    (year_start is null and year_end is null) or
    (year_start is not null and (year_end is null or year_end >= year_start))
  )
);
create index if not exists vehicle_catalog_public_order_idx
  on public.vehicle_catalog(is_published, make_id, sort_order, model_fa);
alter table public.vehicle_catalog enable row level security;

drop policy if exists vehicle_catalog_public_read on public.vehicle_catalog;
create policy vehicle_catalog_public_read on public.vehicle_catalog
  for select to anon, authenticated using (is_published = true);
drop policy if exists vehicle_catalog_admin_read on public.vehicle_catalog;
create policy vehicle_catalog_admin_read on public.vehicle_catalog
  for select to authenticated using (private.has_caracal_permission('manage_content'));
drop policy if exists vehicle_catalog_admin_insert on public.vehicle_catalog;
create policy vehicle_catalog_admin_insert on public.vehicle_catalog
  for insert to authenticated with check (
    private.has_caracal_permission('manage_content')
    and (created_by is null or created_by = auth.uid())
    and (is_published = false or private.has_caracal_permission('publish_content'))
  );
drop policy if exists vehicle_catalog_admin_update on public.vehicle_catalog;
create policy vehicle_catalog_admin_update on public.vehicle_catalog
  for update to authenticated
  using (private.has_caracal_permission('manage_content'))
  with check (private.has_caracal_permission('manage_content'));
drop policy if exists vehicle_catalog_admin_delete on public.vehicle_catalog;
create policy vehicle_catalog_admin_delete on public.vehicle_catalog
  for delete to authenticated using (private.has_caracal_permission('manage_content'));
grant select on public.vehicle_catalog to anon, authenticated;
grant insert, update, delete on public.vehicle_catalog to authenticated;

create table if not exists public.catalog_resources (
  id uuid primary key default gen_random_uuid(),
  vehicle_id uuid references public.vehicle_catalog(id) on delete set null,
  lesson_id uuid references public.lessons(id) on delete set null,
  title_fa text not null,
  title_en text not null,
  description_fa text not null default '',
  description_en text not null default '',
  resource_type text not null default 'article'
    check (resource_type in ('article','image','video','document','external_link')),
  category text not null default 'general',
  storage_path text,
  external_url text,
  source_label text,
  source_url text,
  license_note text,
  is_verified boolean not null default false,
  is_published boolean not null default false,
  sort_order integer not null default 100,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint catalog_resources_location_check check (
    storage_path is not null or external_url is not null or resource_type = 'article'
  )
);
create index if not exists catalog_resources_public_order_idx
  on public.catalog_resources(is_published, category, sort_order, created_at desc);
create index if not exists catalog_resources_vehicle_idx on public.catalog_resources(vehicle_id);
alter table public.catalog_resources enable row level security;

drop policy if exists catalog_resources_public_read on public.catalog_resources;
create policy catalog_resources_public_read on public.catalog_resources
  for select to anon, authenticated using (is_published = true);
drop policy if exists catalog_resources_admin_read on public.catalog_resources;
create policy catalog_resources_admin_read on public.catalog_resources
  for select to authenticated using (private.has_caracal_permission('manage_content'));
drop policy if exists catalog_resources_admin_insert on public.catalog_resources;
create policy catalog_resources_admin_insert on public.catalog_resources
  for insert to authenticated with check (
    private.has_caracal_permission('manage_content')
    and (created_by is null or created_by = auth.uid())
    and (is_published = false or private.has_caracal_permission('publish_content'))
  );
drop policy if exists catalog_resources_admin_update on public.catalog_resources;
create policy catalog_resources_admin_update on public.catalog_resources
  for update to authenticated
  using (private.has_caracal_permission('manage_content'))
  with check (private.has_caracal_permission('manage_content'));
drop policy if exists catalog_resources_admin_delete on public.catalog_resources;
create policy catalog_resources_admin_delete on public.catalog_resources
  for delete to authenticated using (private.has_caracal_permission('manage_content'));
grant select on public.catalog_resources to anon, authenticated;
grant insert, update, delete on public.catalog_resources to authenticated;

insert into public.vehicle_catalog
(slug,make_id,make_fa,make_en,model_fa,model_en,body_type,data_status,is_verified,is_published,sort_order)
values
('peugeot-405','iran-khodro','ایران‌خودرو','Iran Khodro','پژو ۴۰۵','Peugeot 405','sedan','model-index-only',false,true,10),
('peugeot-pars','iran-khodro','ایران‌خودرو','Iran Khodro','پژو پارس','Peugeot Pars','sedan','model-index-only',false,true,20),
('samand','iran-khodro','ایران‌خودرو','Iran Khodro','سمند','Samand','sedan','model-index-only',false,true,30),
('soren','iran-khodro','ایران‌خودرو','Iran Khodro','سورن','Soren','sedan','model-index-only',false,true,40),
('dena','iran-khodro','ایران‌خودرو','Iran Khodro','دنا','Dena','sedan','model-index-only',false,true,50),
('rana','iran-khodro','ایران‌خودرو','Iran Khodro','رانا','Runna','sedan','model-index-only',false,true,60),
('peugeot-206','iran-khodro','ایران‌خودرو','Iran Khodro','پژو ۲۰۶','Peugeot 206','hatchback','model-index-only',false,true,70),
('peugeot-207','iran-khodro','ایران‌خودرو','Iran Khodro','پژو ۲۰۷','Peugeot 207','hatchback','model-index-only',false,true,80),
('tara','iran-khodro','ایران‌خودرو','Iran Khodro','تارا','Tara','sedan','model-index-only',false,true,90),
('arisun','iran-khodro','ایران‌خودرو','Iran Khodro','آریسان','Arisun','pickup','model-index-only',false,true,100),
('pride','saipa','سایپا','Saipa','پراید','Pride','family','model-index-only',false,true,110),
('pride-151','saipa','سایپا','Saipa','پراید ۱۵۱','Pride 151','pickup','model-index-only',false,true,120),
('tiba','saipa','سایپا','Saipa','تیبا','Tiba','sedan','model-index-only',false,true,130),
('tiba-2','saipa','سایپا','Saipa','تیبا ۲','Tiba 2','hatchback','model-index-only',false,true,140),
('saina','saipa','سایپا','Saipa','ساینا','Saina','sedan','model-index-only',false,true,150),
('quick','saipa','سایپا','Saipa','کوییک','Quick','hatchback','model-index-only',false,true,160),
('shahin','saipa','سایپا','Saipa','شاهین','Shahin','sedan','model-index-only',false,true,170),
('atlas','saipa','سایپا','Saipa','اطلس','Atlas','hatchback','model-index-only',false,true,180)
on conflict (slug) do update set
  make_id=excluded.make_id, make_fa=excluded.make_fa, make_en=excluded.make_en,
  model_fa=excluded.model_fa, model_en=excluded.model_en, body_type=excluded.body_type,
  data_status='model-index-only', is_verified=false, is_published=true,
  sort_order=excluded.sort_order, updated_at=now();
