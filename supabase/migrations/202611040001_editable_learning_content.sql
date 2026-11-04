-- CARACAL TUNING: editable learning modules managed through CARACAL ADMIN.
create table if not exists public.learning_modules (
  id uuid primary key default gen_random_uuid(),
  title_fa text not null,
  title_en text not null,
  description_fa text not null default '',
  description_en text not null default '',
  category text not null default 'learn',
  icon_key text not null default 'school',
  sort_order integer not null default 100,
  is_published boolean not null default true,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create unique index if not exists learning_modules_title_fa_uidx on public.learning_modules(title_fa);
create index if not exists learning_modules_published_order_idx on public.learning_modules(is_published,sort_order,created_at);
alter table public.learning_modules enable row level security;

drop policy if exists "learning_modules_public_read" on public.learning_modules;
create policy "learning_modules_public_read" on public.learning_modules for select to anon,authenticated using (is_published=true);
drop policy if exists "learning_modules_admin_read" on public.learning_modules;
create policy "learning_modules_admin_read" on public.learning_modules for select to authenticated using (private.has_caracal_permission('manage_content'));
drop policy if exists "learning_modules_admin_insert" on public.learning_modules;
create policy "learning_modules_admin_insert" on public.learning_modules for insert to authenticated with check (private.has_caracal_permission('manage_content') and created_by=auth.uid() and (is_published=false or private.has_caracal_permission('publish_content')));
drop policy if exists "learning_modules_admin_update" on public.learning_modules;
create policy "learning_modules_admin_update" on public.learning_modules for update to authenticated using (private.has_caracal_permission('manage_content')) with check (private.has_caracal_permission('manage_content'));
drop policy if exists "learning_modules_admin_delete" on public.learning_modules;
create policy "learning_modules_admin_delete" on public.learning_modules for delete to authenticated using (private.has_caracal_permission('manage_content'));
grant select on public.learning_modules to anon,authenticated;
grant insert,update,delete on public.learning_modules to authenticated;

insert into public.learning_modules(title_fa,title_en,description_fa,description_en,category,icon_key,sort_order,is_published) values
('آموزش تخصصی خودرو','Automotive Technical Education','مسیرهای آموزشی از مبانی تا مباحث حرفه‌ای خودرو.','Structured learning paths from fundamentals to advanced automotive topics.','learn','school',1,true),
('بانک اطلاعات فنی خودرو','Vehicle Technical Database','مشخصات فنی، سیستم‌ها و اطلاعات کاربردی خودروها.','Vehicle specifications, systems and technical references.','reference','directions_car',2,true),
('بانک کدهای خطای DTC','DTC Error Code Database','جست‌وجو و شناخت کدهای خطا و مفهوم آن‌ها.','Search diagnostic trouble codes and understand their meaning.','diagnosis','warning',3,true),
('نقشه پایه ECU','ECU Pinout Diagrams','مرجع آموزشی پایه‌ها و اتصالات واحد کنترل الکترونیکی.','Educational reference for ECU pins and connections.','reference','memory',4,true),
('نقشه سیم‌کشی خودرو','Automotive Wiring Diagrams','مطالعه ساختار مدارها و مسیرهای سیم‌کشی.','Study circuit layouts and vehicle wiring paths.','reference','account_tree',5,true),
('نقشه فیوز و رله','Fuse & Relay Diagrams','راهنمای آموزشی جعبه‌فیوزها و مدارهای حفاظتی.','Educational guide to fuse boxes and protection circuits.','reference','electrical',6,true),
('راهنمای تعمیر موتور','Engine Repair Guides','آشنایی با اجزای موتور، اصول سرویس و تعمیر.','Engine components, service principles and repair guides.','repair','settings',7,true),
('سیستم برق خودرو','Automotive Electrical Systems','مبانی برق، شارژ، استارت و مدارهای الکتریکی.','Electrical fundamentals, charging, starting and circuits.','repair','bolt',8,true),
('آموزش برنامه‌ریزی و ریمپ ECU','ECU Programming & Remapping','مفاهیم کالیبراسیون، ساختار داده و اصول ایمن ریمپ.','Calibration concepts, data structure and safe remapping principles.','learn','tune',9,true),
('گیربکس اتوماتیک','Automatic Transmission','شناخت ساختار، عملکرد و عیب‌یابی مقدماتی گیربکس.','Transmission architecture, operation and basic diagnostics.','repair','settings_applications',10,true),
('سنسورها و عملگرها','Sensors & Actuators','نحوه عملکرد و نقش حسگرها و عملگرهای خودرو.','How automotive sensors and actuators work.','diagnosis','sensors',11,true),
('فرهنگ لغت تخصصی خودرو','Automotive Technical Dictionary','اصطلاحات تخصصی فارسی و انگلیسی صنعت خودرو.','Persian and English automotive terminology.','reference','menu_book',12,true),
('ماشین‌حساب‌های فنی','Automotive Calculators','ابزارهای محاسباتی آموزشی برای پارامترهای خودرو.','Learning calculators for common vehicle parameters.','tools','calculate',13,true),
('دستیار هوشمند عیب‌یابی','AI Diagnostic Assistant','راهنمای مرحله‌ای تحلیل علائم و اطلاعات عیب‌یابی.','Step-by-step assistance for interpreting symptoms and diagnostic data.','tools','smart_toy',14,true),
('آزمون‌ها و سنجش تخصصی','Professional Quizzes & Exams','آزمون‌های آموزشی برای سنجش دانش فنی.','Knowledge checks and technical learning assessments.','learn','quiz',15,true)
on conflict(title_fa) do nothing;

-- Content managers may edit already-published records without being granted
-- permission to publish/unpublish them. This trigger protects that boundary.
create or replace function private.guard_caracal_publish_flag()
returns trigger language plpgsql set search_path='' as $$
begin
  if not private.has_caracal_permission('publish_content') then
    if tg_op='INSERT' then
      new.is_published:=false;
    elsif new.is_published is distinct from old.is_published then
      raise exception 'برای تغییر وضعیت انتشار، مجوز انتشار محتوا لازم است.';
    end if;
  end if;
  return new;
end;
$$;
drop trigger if exists guard_lessons_publish_flag on public.lessons;
create trigger guard_lessons_publish_flag before insert or update of is_published on public.lessons for each row execute function private.guard_caracal_publish_flag();
drop trigger if exists guard_learning_modules_publish_flag on public.learning_modules;
create trigger guard_learning_modules_publish_flag before insert or update of is_published on public.learning_modules for each row execute function private.guard_caracal_publish_flag();

alter policy lessons_admin_update on public.lessons
using (private.has_caracal_permission('manage_content'))
with check (private.has_caracal_permission('manage_content'));
