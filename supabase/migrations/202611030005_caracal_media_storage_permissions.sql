-- CARACAL TUNING: public lesson media with authenticated content-manager uploads.
insert into storage.buckets (id,name,public,file_size_limit,allowed_mime_types)
values ('caracal-media','caracal-media',true,52428800,
  array['image/jpeg','image/png','image/webp','image/gif','video/mp4','video/quicktime','video/webm','application/pdf','application/octet-stream'])
on conflict (id) do update set
  public=excluded.public,
  file_size_limit=excluded.file_size_limit,
  allowed_mime_types=excluded.allowed_mime_types;

drop policy if exists "CARACAL content managers upload lesson media" on storage.objects;
create policy "CARACAL content managers upload lesson media"
on storage.objects for insert to authenticated
with check (bucket_id='caracal-media' and private.can_manage_content());

drop policy if exists "CARACAL content managers update lesson media" on storage.objects;
create policy "CARACAL content managers update lesson media"
on storage.objects for update to authenticated
using (bucket_id='caracal-media' and private.can_manage_content())
with check (bucket_id='caracal-media' and private.can_manage_content());

drop policy if exists "CARACAL content managers delete lesson media" on storage.objects;
create policy "CARACAL content managers delete lesson media"
on storage.objects for delete to authenticated
using (bucket_id='caracal-media' and private.can_manage_content());
