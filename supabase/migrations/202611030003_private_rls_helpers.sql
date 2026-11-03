-- Keep privileged RLS helper routines out of the exposed public API schema.
create schema if not exists private;
revoke all on schema private from public, anon;
grant usage on schema private to authenticated, service_role;
create or replace function private.is_owner()
returns boolean language sql stable security definer set search_path=public as $$
 select exists(select 1 from public.profiles where id=auth.uid() and role='owner');
$$;
create or replace function private.can_manage_content()
returns boolean language sql stable security definer set search_path=public as $$
 select exists(select 1 from public.profiles p where p.id=auth.uid() and
 (p.role='owner' or (p.role='admin' and
 (coalesce((p.permissions->>'manage_content')::boolean,false) or coalesce((p.permissions->>'content')::boolean,false)))));
$$;
create or replace function private.is_booking_manager()
returns boolean language sql stable security definer set search_path=public as $$
 select exists(select 1 from public.profiles p where p.id=auth.uid() and
 (p.role='owner' or (p.role='admin' and coalesce((p.permissions->>'manage_bookings')::boolean,false))));
$$;
create or replace function private.has_caracal_permission(permission_name text)
returns boolean language sql stable security definer set search_path=public as $$
 select exists(select 1 from public.profiles p where p.id=auth.uid() and
 (p.role='owner' or (p.role='admin' and coalesce((p.permissions->>permission_name)::boolean,false))));
$$;
revoke all on function private.is_owner() from public,anon,authenticated;
revoke all on function private.can_manage_content() from public,anon,authenticated;
revoke all on function private.is_booking_manager() from public,anon,authenticated;
revoke all on function private.has_caracal_permission(text) from public,anon,authenticated;
grant execute on function private.is_owner() to authenticated;
grant execute on function private.can_manage_content() to authenticated;
grant execute on function private.is_booking_manager() to authenticated;
grant execute on function private.has_caracal_permission(text) to authenticated;

drop policy if exists "Managers update bookings" on public.booking_requests;
create policy "Managers update bookings" on public.booking_requests for update to authenticated using(private.is_booking_manager()) with check(private.is_booking_manager());
drop policy if exists "Users read own bookings or managers read all" on public.booking_requests;
create policy "Users read own bookings or managers read all" on public.booking_requests for select to authenticated using(user_id=auth.uid() or private.is_booking_manager());
drop policy if exists "content managers delete lessons" on public.lessons;
create policy "content managers delete lessons" on public.lessons for delete to authenticated using(private.can_manage_content());
drop policy if exists "content managers insert lessons" on public.lessons;
create policy "content managers insert lessons" on public.lessons for insert to authenticated with check(private.can_manage_content() and created_by=auth.uid());
drop policy if exists "content managers update lessons" on public.lessons;
create policy "content managers update lessons" on public.lessons for update to authenticated using(private.can_manage_content()) with check(private.can_manage_content());
drop policy if exists "published lessons are public" on public.lessons;
create policy "published lessons are public" on public.lessons for select to anon,authenticated using(is_published=true);
drop policy if exists "lessons_admin_read_all" on public.lessons;
create policy "lessons_admin_read_all" on public.lessons for select to authenticated using(private.can_manage_content());
drop policy if exists "Owner updates admins" on public.profiles;
create policy "Owner updates admins" on public.profiles for update to authenticated using(private.is_owner() and role='admin') with check(private.is_owner() and role='admin');
drop policy if exists "Read own profile" on public.profiles;
create policy "Read own profile" on public.profiles for select to authenticated using(id=auth.uid() or private.is_owner());
drop policy if exists "owner updates roles" on public.user_roles;
create policy "owner updates roles" on public.user_roles for update to authenticated using(private.is_owner()) with check(private.is_owner());
drop policy if exists "users read own role" on public.user_roles;
create policy "users read own role" on public.user_roles for select to authenticated using(user_id=auth.uid() or private.is_owner());
drop policy if exists "lesson_media_admin_upload" on storage.objects;
drop policy if exists "lesson_media_admin_update" on storage.objects;
drop policy if exists "lesson_media_admin_delete" on storage.objects;
create policy "lesson_media_admin_upload" on storage.objects for insert to authenticated with check(bucket_id='lesson-media' and private.can_manage_content());
create policy "lesson_media_admin_update" on storage.objects for update to authenticated using(bucket_id='lesson-media' and private.can_manage_content()) with check(bucket_id='lesson-media' and private.can_manage_content());
create policy "lesson_media_admin_delete" on storage.objects for delete to authenticated using(bucket_id='lesson-media' and private.can_manage_content());
revoke all on function public.can_manage_content() from public,anon,authenticated;
revoke all on function public.has_caracal_permission(text) from public,anon,authenticated;
revoke all on function public.is_booking_manager() from public,anon,authenticated;
revoke all on function public.is_owner() from public,anon,authenticated;
revoke all on function public.handle_new_user() from public,anon,authenticated;
revoke all on function public.sync_caracal_profile_role() from public,anon,authenticated;
revoke all on function public.sync_caracal_user_role() from public,anon,authenticated;
