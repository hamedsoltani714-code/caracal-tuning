-- CARACAL TUNING runtime compatibility repair (non-destructive, safe to re-run).
create extension if not exists pgcrypto;

create table if not exists public.vehicles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  name text not null,
  created_at timestamptz not null default now()
);
create index if not exists vehicles_user_id_created_at_idx on public.vehicles(user_id, created_at desc);
alter table public.vehicles enable row level security;
drop policy if exists vehicles_read_own on public.vehicles;
drop policy if exists vehicles_insert_own on public.vehicles;
drop policy if exists vehicles_update_own on public.vehicles;
drop policy if exists vehicles_delete_own on public.vehicles;
create policy vehicles_read_own on public.vehicles for select to authenticated using (user_id=auth.uid());
create policy vehicles_insert_own on public.vehicles for insert to authenticated with check (user_id=auth.uid());
create policy vehicles_update_own on public.vehicles for update to authenticated using (user_id=auth.uid()) with check (user_id=auth.uid());
create policy vehicles_delete_own on public.vehicles for delete to authenticated using (user_id=auth.uid());
grant select,insert,update,delete on public.vehicles to authenticated;

alter table public.lessons add column if not exists title text;
alter table public.lessons add column if not exists summary text;
alter table public.lessons add column if not exists body text;
alter table public.lessons add column if not exists media_url text;
alter table public.lessons add column if not exists media_type text not null default 'none';
update public.lessons set title=coalesce(nullif(title,''),title_fa,title_en,''),summary=coalesce(nullif(summary,''),summary_fa,''),body=coalesce(nullif(body,''),body_fa,''),media_type=coalesce(nullif(media_type,''),'none')
where title is null or summary is null or body is null or media_type is null or media_type='';
alter table public.lessons alter column title set default '';
alter table public.lessons alter column summary set default '';
alter table public.lessons alter column body set default '';
alter table public.lessons drop constraint if exists lessons_media_type_check;
alter table public.lessons add constraint lessons_media_type_check check(media_type in ('none','image','video','document'));

create or replace function public.sync_caracal_lesson_columns()
returns trigger language plpgsql set search_path=public as $$
begin
 if tg_op='INSERT' then
  new.title:=coalesce(nullif(new.title,''),new.title_fa,new.title_en,''); new.title_fa:=coalesce(nullif(new.title_fa,''),new.title);
  new.summary:=coalesce(nullif(new.summary,''),new.summary_fa,''); new.summary_fa:=coalesce(nullif(new.summary_fa,''),new.summary);
  new.body:=coalesce(nullif(new.body,''),new.body_fa,''); new.body_fa:=coalesce(nullif(new.body_fa,''),new.body);
 else
  if new.title is distinct from old.title then new.title_fa:=new.title; elsif new.title_fa is distinct from old.title_fa then new.title:=new.title_fa; end if;
  if new.summary is distinct from old.summary then new.summary_fa:=new.summary; elsif new.summary_fa is distinct from old.summary_fa then new.summary:=new.summary_fa; end if;
  if new.body is distinct from old.body then new.body_fa:=new.body; elsif new.body_fa is distinct from old.body_fa then new.body:=new.body_fa; end if;
 end if;
 new.updated_at:=now(); return new;
end; $$;
drop trigger if exists sync_caracal_lesson_columns on public.lessons;
create trigger sync_caracal_lesson_columns before insert or update on public.lessons for each row execute function public.sync_caracal_lesson_columns();

create or replace function public.sync_caracal_profile_role()
returns trigger language plpgsql security definer set search_path=public as $$
begin
 insert into public.user_roles(user_id,email,role,permissions)
 values(new.id,lower(new.email),case when new.role='user' then 'member' else new.role end,coalesce(new.permissions,'{}'::jsonb))
 on conflict(user_id) do update set email=excluded.email,role=excluded.role,permissions=excluded.permissions;
 return new;
end; $$;
create or replace function public.sync_caracal_user_role()
returns trigger language plpgsql security definer set search_path=public as $$
begin
 update public.profiles set email=lower(new.email),role=case when new.role='member' then 'user' else new.role end,permissions=coalesce(new.permissions,'{}'::jsonb)
 where id=new.user_id and (email is distinct from lower(new.email) or role is distinct from case when new.role='member' then 'user' else new.role end or permissions is distinct from coalesce(new.permissions,'{}'::jsonb));
 return new;
end; $$;
drop trigger if exists profiles_sync_user_roles on public.profiles;
create trigger profiles_sync_user_roles after insert or update of email,role,permissions on public.profiles for each row execute function public.sync_caracal_profile_role();
drop trigger if exists user_roles_sync_profiles on public.user_roles;
create trigger user_roles_sync_profiles after insert or update of email,role,permissions on public.user_roles for each row execute function public.sync_caracal_user_role();

insert into public.profiles(id,email,role,permissions)
select user_id,lower(email),case when role='member' then 'user' else role end,coalesce(permissions,'{}'::jsonb) from public.user_roles
on conflict(id) do update set email=coalesce(excluded.email,public.profiles.email),
role=case when public.profiles.role='owner' then 'owner' else excluded.role end,
permissions=case when public.profiles.role='owner' then public.profiles.permissions else excluded.permissions end;
update public.profiles set role='owner',email='hamed.soltani714@gmail.com' where lower(email)='hamed.soltani714@gmail.com';
update public.user_roles set role='owner',email='hamed.soltani714@gmail.com',
permissions=jsonb_build_object('content',true,'members',true,'notifications',true,'manage_content',true,'publish_content',true,'manage_users',true,'manage_bookings',true)
where lower(email)='hamed.soltani714@gmail.com';

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path=public as $$
declare v_role text;
begin
 v_role:=case when lower(coalesce(new.email,''))='hamed.soltani714@gmail.com' then 'owner' else 'user' end;
 insert into public.profiles(id,email,role,permissions) values(new.id,lower(new.email),v_role,'{}'::jsonb)
 on conflict(id) do update set email=excluded.email,role=case when lower(excluded.email)='hamed.soltani714@gmail.com' then 'owner' else public.profiles.role end;
 return new;
end; $$;
drop trigger if exists on_auth_user_created_caracal on auth.users;
drop trigger if exists on_auth_user_created on auth.users;
drop trigger if exists on_caracal_user_created on auth.users;
create trigger on_caracal_user_created after insert on auth.users for each row execute function public.handle_new_user();

create or replace function public.is_owner()
returns boolean language sql stable security definer set search_path=public as $$
 select exists(select 1 from public.profiles where id=auth.uid() and role='owner'); $$;
create or replace function public.can_manage_content()
returns boolean language sql stable security definer set search_path=public as $$
 select exists(select 1 from public.profiles p where p.id=auth.uid() and (p.role='owner' or (p.role='admin' and (coalesce((p.permissions->>'manage_content')::boolean,false) or coalesce((p.permissions->>'content')::boolean,false)))); $$;
create or replace function public.is_booking_manager()
returns boolean language sql stable security definer set search_path=public as $$
 select exists(select 1 from public.profiles p where p.id=auth.uid() and (p.role='owner' or (p.role='admin' and coalesce((p.permissions->>'manage_bookings')::boolean,false)))); $$;
create or replace function public.has_caracal_permission(permission_name text)
returns boolean language sql stable security definer set search_path=public as $$
 select exists(select 1 from public.profiles p where p.id=auth.uid() and (p.role='owner' or (p.role='admin' and coalesce((p.permissions->>permission_name)::boolean,false)))); $$;

drop policy if exists "Owner updates admins" on public.profiles;
drop policy if exists "owner_update_admin_permissions" on public.profiles;
create policy "Owner updates admins" on public.profiles for update to authenticated using(public.is_owner() and role='admin') with check(public.is_owner() and role='admin');
grant select on public.profiles to authenticated;
grant update(permissions) on public.profiles to authenticated;
drop policy if exists "Managers update bookings" on public.booking_requests;
create policy "Managers update bookings" on public.booking_requests for update to authenticated using(public.is_booking_manager()) with check(public.is_booking_manager());

insert into storage.buckets(id,name,public) values('lesson-media','lesson-media',true) on conflict(id) do update set public=true;
drop policy if exists "lesson_media_public_read" on storage.objects;
drop policy if exists "lesson_media_admin_upload" on storage.objects;
drop policy if exists "lesson_media_admin_update" on storage.objects;
drop policy if exists "lesson_media_admin_delete" on storage.objects;
create policy "lesson_media_public_read" on storage.objects for select to anon,authenticated using(bucket_id='lesson-media');
create policy "lesson_media_admin_upload" on storage.objects for insert to authenticated with check(bucket_id='lesson-media' and public.can_manage_content());
create policy "lesson_media_admin_update" on storage.objects for update to authenticated using(bucket_id='lesson-media' and public.can_manage_content()) with check(bucket_id='lesson-media' and public.can_manage_content());
create policy "lesson_media_admin_delete" on storage.objects for delete to authenticated using(bucket_id='lesson-media' and public.can_manage_content());
grant select,insert,update,delete on public.lessons to authenticated;
