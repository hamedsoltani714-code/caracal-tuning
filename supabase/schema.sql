-- =====================================================
-- CARACAL TUNING DATABASE
-- Supabase / PostgreSQL
-- =====================================================

create extension if not exists pgcrypto;

-- -----------------------------------------------------
-- HELPER FUNCTIONS
-- -----------------------------------------------------

create or replace function public.is_caracal_owner()
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1
    from public.profiles
    where id = auth.uid()
      and role = 'owner'
  );
$$;

create or replace function public.has_caracal_permission(permission_name text)
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1
    from public.profiles
    where id = auth.uid()
      and (
        role = 'owner'
        or (
          role = 'admin'
          and coalesce(
            (permissions ->> permission_name)::boolean,
            false
          )
        )
      )
  );
$$;

-- -----------------------------------------------------
-- PROFILES
-- -----------------------------------------------------

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text unique,
  role text not null default 'user'
    check (role in ('user', 'admin', 'owner')),
  permissions jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

drop policy if exists "profile_read_own" on public.profiles;
create policy "profile_read_own"
on public.profiles
for select
to authenticated
using (id = auth.uid());

drop policy if exists "owner_read_profiles" on public.profiles;
create policy "owner_read_profiles"
on public.profiles
for select
to authenticated
using (public.is_caracal_owner());

drop policy if exists "owner_update_admin_permissions" on public.profiles;
create policy "owner_update_admin_permissions"
on public.profiles
for update
to authenticated
using (
  public.is_caracal_owner()
  and role = 'admin'
)
with check (
  public.is_caracal_owner()
  and role = 'admin'
);

grant select on public.profiles to authenticated;
grant update (permissions) on public.profiles to authenticated;

-- -----------------------------------------------------
-- AUTOMATIC PROFILE CREATION
-- -----------------------------------------------------

create or replace function public.handle_new_caracal_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (
    id,
    email,
    role,
    permissions
  )
  values (
    new.id,
    lower(new.email),
    case
      when lower(new.email) = 'hamed.soltani714@gmail.com'
        then 'owner'
      else 'user'
    end,
    '{}'::jsonb
  )
  on conflict (id) do update
  set email = excluded.email,
      role = case
        when lower(excluded.email) = 'hamed.soltani714@gmail.com'
          then 'owner'
        else public.profiles.role
      end;

  return new;
end;
$$;

drop trigger if exists on_caracal_user_created on auth.users;

create trigger on_caracal_user_created
after insert on auth.users
for each row
execute procedure public.handle_new_caracal_user();

-- Ensure the existing owner account has a profile.
insert into public.profiles (id, email, role, permissions)
select
  id,
  lower(email),
  'owner',
  '{}'::jsonb
from auth.users
where lower(email) = 'hamed.soltani714@gmail.com'
on conflict (id) do update
set email = excluded.email,
    role = 'owner';

-- -----------------------------------------------------
-- VEHICLES
-- -----------------------------------------------------

create table if not exists public.vehicles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid()
    references auth.users(id) on delete cascade,
  name text not null,
  created_at timestamptz not null default now()
);

create index if not exists vehicles_user_id_idx
on public.vehicles(user_id);

alter table public.vehicles enable row level security;

drop policy if exists "vehicles_read_own" on public.vehicles;
create policy "vehicles_read_own"
on public.vehicles
for select
to authenticated
using (user_id = auth.uid());

drop policy if exists "vehicles_insert_own" on public.vehicles;
create policy "vehicles_insert_own"
on public.vehicles
for insert
to authenticated
with check (user_id = auth.uid());

drop policy if exists "vehicles_update_own" on public.vehicles;
create policy "vehicles_update_own"
on public.vehicles
for update
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

drop policy if exists "vehicles_delete_own" on public.vehicles;
create policy "vehicles_delete_own"
on public.vehicles
for delete
to authenticated
using (user_id = auth.uid());

grant select, insert, update, delete
on public.vehicles to authenticated;

-- -----------------------------------------------------
-- LESSONS
-- -----------------------------------------------------

create table if not exists public.lessons (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  title_en text,
  summary text,
  summary_en text,
  body text not null,
  body_en text,
  category text not null default 'general',
  media_url text,
  media_type text not null default 'none'
    check (media_type in ('none', 'image', 'video', 'document')),
  is_published boolean not null default false,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists lessons_published_created_idx
on public.lessons(is_published, created_at desc);

alter table public.lessons enable row level security;

drop policy if exists "lessons_read_published" on public.lessons;
create policy "lessons_read_published"
on public.lessons
for select
to anon, authenticated
using (is_published = true);

drop policy if exists "lessons_admin_read_all" on public.lessons;
create policy "lessons_admin_read_all"
on public.lessons
for select
to authenticated
using (public.has_caracal_permission('manage_content'));

drop policy if exists "lessons_admin_insert" on public.lessons;
create policy "lessons_admin_insert"
on public.lessons
for insert
to authenticated
with check (
  public.has_caracal_permission('manage_content')
  and created_by = auth.uid()
  and (
    is_published = false
    or public.has_caracal_permission('publish_content')
  )
);

drop policy if exists "lessons_admin_update" on public.lessons;
create policy "lessons_admin_update"
on public.lessons
for update
to authenticated
using (public.has_caracal_permission('manage_content'))
with check (
  public.has_caracal_permission('manage_content')
  and (
    is_published = false
    or public.has_caracal_permission('publish_content')
  )
);

drop policy if exists "lessons_admin_delete" on public.lessons;
create policy "lessons_admin_delete"
on public.lessons
for delete
to authenticated
using (public.has_caracal_permission('manage_content'));

grant select on public.lessons to anon, authenticated;
grant insert, update, delete on public.lessons to authenticated;

-- -----------------------------------------------------
-- BOOKING REQUESTS
-- -----------------------------------------------------

create table if not exists public.booking_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid()
    references auth.users(id) on delete cascade,
  customer_name text not null,
  phone text not null,
  vehicle text not null,
  service text not null,
  preferred_date date not null,
  preferred_time time not null,
  notes text,
  status text not null default 'pending'
    check (status in ('pending', 'confirmed', 'completed', 'cancelled')),
  created_at timestamptz not null default now()
);

create index if not exists booking_user_created_idx
on public.booking_requests(user_id, created_at desc);

create index if not exists booking_created_idx
on public.booking_requests(created_at desc);

alter table public.booking_requests enable row level security;

drop policy if exists "booking_read_own" on public.booking_requests;
create policy "booking_read_own"
on public.booking_requests
for select
to authenticated
using (user_id = auth.uid());

drop policy if exists "booking_admin_read" on public.booking_requests;
create policy "booking_admin_read"
on public.booking_requests
for select
to authenticated
using (public.has_caracal_permission('manage_bookings'));

drop policy if exists "booking_insert_own" on public.booking_requests;
create policy "booking_insert_own"
on public.booking_requests
for insert
to authenticated
with check (
  user_id = auth.uid()
  and status = 'pending'
);

drop policy if exists "booking_admin_update" on public.booking_requests;
create policy "booking_admin_update"
on public.booking_requests
for update
to authenticated
using (public.has_caracal_permission('manage_bookings'))
with check (public.has_caracal_permission('manage_bookings'));

grant select, insert, update
on public.booking_requests to authenticated;

-- -----------------------------------------------------
-- STORAGE BUCKET
-- -----------------------------------------------------

insert into storage.buckets (
  id,
  name,
  public
)
values (
  'lesson-media',
  'lesson-media',
  true
)
on conflict (id) do update
set public = true;

drop policy if exists "lesson_media_public_read" on storage.objects;
create policy "lesson_media_public_read"
on storage.objects
for select
to anon, authenticated
using (bucket_id = 'lesson-media');

drop policy if exists "lesson_media_admin_upload" on storage.objects;
create policy "lesson_media_admin_upload"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'lesson-media'
  and public.has_caracal_permission('manage_content')
);

drop policy if exists "lesson_media_admin_update" on storage.objects;
create policy "lesson_media_admin_update"
on storage.objects
for update
to authenticated
using (
  bucket_id = 'lesson-media'
  and public.has_caracal_permission('manage_content')
)
with check (
  bucket_id = 'lesson-media'
  and public.has_caracal_permission('manage_content')
);

drop policy if exists "lesson_media_admin_delete" on storage.objects;
create policy "lesson_media_admin_delete"
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'lesson-media'
  and public.has_caracal_permission('manage_content')
);

-- -----------------------------------------------------
-- END
-- -----------------------------------------------------
