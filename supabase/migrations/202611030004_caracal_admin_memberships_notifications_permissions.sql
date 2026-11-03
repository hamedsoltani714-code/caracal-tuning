-- CARACAL ADMIN: memberships, announcements and server-enforced permission gates.
create or replace function private.can_publish_content()
returns boolean language sql stable security definer set search_path=public as $$
  select exists (select 1 from public.profiles p where p.id=auth.uid()
    and (p.role='owner' or (p.role='admin' and coalesce((p.permissions->>'publish_content')::boolean,false))));
$$;
create or replace function private.can_manage_users()
returns boolean language sql stable security definer set search_path=public as $$
  select exists (select 1 from public.profiles p where p.id=auth.uid()
    and (p.role='owner' or (p.role='admin' and coalesce((p.permissions->>'manage_users')::boolean,false))));
$$;
create or replace function private.can_manage_memberships()
returns boolean language sql stable security definer set search_path=public as $$
  select exists (select 1 from public.profiles p where p.id=auth.uid()
    and (p.role='owner' or (p.role='admin' and coalesce((p.permissions->>'manage_memberships')::boolean,false))));
$$;
create or replace function private.can_manage_notifications()
returns boolean language sql stable security definer set search_path=public as $$
  select exists (select 1 from public.profiles p where p.id=auth.uid()
    and (p.role='owner' or (p.role='admin' and coalesce((p.permissions->>'manage_notifications')::boolean,false))));
$$;
revoke all on function private.can_publish_content() from public,anon,authenticated;
revoke all on function private.can_manage_users() from public,anon,authenticated;
revoke all on function private.can_manage_memberships() from public,anon,authenticated;
revoke all on function private.can_manage_notifications() from public,anon,authenticated;
grant execute on function private.can_publish_content() to authenticated;
grant execute on function private.can_manage_users() to authenticated;
grant execute on function private.can_manage_memberships() to authenticated;
grant execute on function private.can_manage_notifications() to authenticated;

drop policy if exists "content managers insert lessons" on public.lessons;
create policy "content managers insert lessons" on public.lessons for insert to authenticated
with check(private.can_manage_content() and created_by=(select auth.uid()) and (is_published=false or private.can_publish_content()));
drop policy if exists "content managers update lessons" on public.lessons;
create policy "content managers update lessons" on public.lessons for update to authenticated
using(private.can_manage_content())
with check(private.can_manage_content() and (is_published=false or private.can_publish_content()));

drop policy if exists "Read own profile" on public.profiles;
create policy "Read own profile" on public.profiles for select to authenticated
using(id=(select auth.uid()) or private.is_owner() or private.can_manage_users() or private.can_manage_memberships());

create table if not exists public.memberships (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references auth.users(id) on delete cascade,
 plan text not null default 'standard',
 status text not null default 'pending' check(status in ('pending','active','expired','cancelled')),
 starts_at timestamptz,
 ends_at timestamptz,
 notes text not null default '',
 created_by uuid references auth.users(id) on delete set null,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
create index if not exists memberships_user_created_idx on public.memberships(user_id,created_at desc);
alter table public.memberships enable row level security;
drop policy if exists "members read own membership or managers read all" on public.memberships;
create policy "members read own membership or managers read all" on public.memberships for select to authenticated
using(user_id=(select auth.uid()) or private.can_manage_memberships());
drop policy if exists "membership managers insert" on public.memberships;
create policy "membership managers insert" on public.memberships for insert to authenticated
with check(private.can_manage_memberships() and created_by=(select auth.uid()));
drop policy if exists "membership managers update" on public.memberships;
create policy "membership managers update" on public.memberships for update to authenticated
using(private.can_manage_memberships()) with check(private.can_manage_memberships());
drop policy if exists "membership managers delete" on public.memberships;
create policy "membership managers delete" on public.memberships for delete to authenticated
using(private.can_manage_memberships());
grant select,insert,update,delete on public.memberships to authenticated;

create table if not exists public.app_notifications (
 id uuid primary key default gen_random_uuid(),
 title_fa text not null,
 title_en text not null default '',
 body_fa text not null,
 body_en text not null default '',
 target_user_id uuid references auth.users(id) on delete cascade,
 is_published boolean not null default false,
 created_by uuid references auth.users(id) on delete set null,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
create index if not exists app_notifications_published_created_idx on public.app_notifications(is_published,created_at desc);
create index if not exists app_notifications_target_user_idx on public.app_notifications(target_user_id);
alter table public.app_notifications enable row level security;
drop policy if exists "public read published global notifications" on public.app_notifications;
create policy "public read published global notifications" on public.app_notifications for select to anon
using(is_published=true and target_user_id is null);
drop policy if exists "users read published notifications" on public.app_notifications;
create policy "users read published notifications" on public.app_notifications for select to authenticated
using((is_published=true and (target_user_id is null or target_user_id=(select auth.uid()))) or private.can_manage_notifications());
drop policy if exists "notification managers insert" on public.app_notifications;
create policy "notification managers insert" on public.app_notifications for insert to authenticated
with check(private.can_manage_notifications() and created_by=(select auth.uid()));
drop policy if exists "notification managers update" on public.app_notifications;
create policy "notification managers update" on public.app_notifications for update to authenticated
using(private.can_manage_notifications()) with check(private.can_manage_notifications());
drop policy if exists "notification managers delete" on public.app_notifications;
create policy "notification managers delete" on public.app_notifications for delete to authenticated
using(private.can_manage_notifications());
grant select on public.app_notifications to anon,authenticated;
grant insert,update,delete on public.app_notifications to authenticated;

create or replace function private.touch_updated_at()
returns trigger language plpgsql set search_path=public as $$
begin new.updated_at=now(); return new; end;
$$;
drop trigger if exists memberships_touch_updated_at on public.memberships;
create trigger memberships_touch_updated_at before update on public.memberships for each row execute function private.touch_updated_at();
drop trigger if exists notifications_touch_updated_at on public.app_notifications;
create trigger notifications_touch_updated_at before update on public.app_notifications for each row execute function private.touch_updated_at();
