-- CARACAL TUNING: private technical library for licensed educational files.
-- Keep large binaries out of PostgreSQL and out of the mobile APK.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'vehicle-technical-library',
  'vehicle-technical-library',
  false,
  104857600,
  array[
    'application/pdf',
    'image/jpeg',
    'image/png',
    'image/webp',
    'image/gif',
    'video/mp4',
    'video/webm',
    'text/plain',
    'text/csv'
  ]::text[]
)
on conflict (id) do update
set public = false,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

alter table public.catalog_resources
  add column if not exists original_filename text,
  add column if not exists mime_type text,
  add column if not exists file_size_bytes bigint,
  add column if not exists checksum_sha256 text;

alter table public.catalog_resources
  drop constraint if exists catalog_resources_file_size_bytes_check;
alter table public.catalog_resources
  add constraint catalog_resources_file_size_bytes_check
  check (file_size_bytes is null or file_size_bytes >= 0);

create index if not exists catalog_resources_vehicle_published_idx
  on public.catalog_resources (vehicle_id, is_published, sort_order);

create index if not exists catalog_resources_storage_path_idx
  on public.catalog_resources (storage_path)
  where storage_path is not null;

drop policy if exists vehicle_library_members_read on storage.objects;
create policy vehicle_library_members_read
on storage.objects for select
to authenticated
using (
  bucket_id = 'vehicle-technical-library'
  and (
    private.has_caracal_permission('manage_content')
    or exists (
      select 1
      from public.memberships m
      where m.user_id = (select auth.uid())
        and m.status = 'active'
        and (m.starts_at is null or m.starts_at <= now())
        and (m.ends_at is null or m.ends_at > now())
    )
  )
);

drop policy if exists vehicle_library_admin_upload on storage.objects;
create policy vehicle_library_admin_upload
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'vehicle-technical-library'
  and private.has_caracal_permission('manage_content')
);

drop policy if exists vehicle_library_admin_update on storage.objects;
create policy vehicle_library_admin_update
on storage.objects for update
to authenticated
using (
  bucket_id = 'vehicle-technical-library'
  and private.has_caracal_permission('manage_content')
)
with check (
  bucket_id = 'vehicle-technical-library'
  and private.has_caracal_permission('manage_content')
);

drop policy if exists vehicle_library_admin_delete on storage.objects;
create policy vehicle_library_admin_delete
on storage.objects for delete
to authenticated
using (
  bucket_id = 'vehicle-technical-library'
  and private.has_caracal_permission('manage_content')
);

comment on column public.catalog_resources.storage_path is
  'Object path inside private vehicle-technical-library bucket; never store public URLs for private files.';
comment on column public.catalog_resources.file_size_bytes is
  'File size in bytes; binary content is stored in Supabase Storage, not PostgreSQL.';
