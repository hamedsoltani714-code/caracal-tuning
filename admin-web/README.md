# CARACAL TUNING — Web Admin

داشبورد مدیریت مستقل وب است؛ هیچ مسیر یا صفحه مدیریت داخل اپلیکیشن Flutter وجود ندارد.

## اجرای محلی
1. وارد پوشه `admin-web` شوید.
2. فایل `.env.example` را به `.env.local` کپی کنید.
3. مقدار `NEXT_PUBLIC_SUPABASE_URL` و کلید عمومی anon/publishable پروژه را قرار دهید.
4. اجرا: `npm install` و سپس `npm run dev`.

## انتشار روی Cloudflare Workers
این پروژه با Next.js و آداپتور OpenNext برای Cloudflare Workers آماده شده است.

- مخزن: `hamedsoltani714-code/caracal-tuning`
- شاخه: `main`
- Root directory: `admin-web`
- Build command: `npm run build` فقط برای بررسی عادی Next.js است؛ انتشار Cloudflare با `npm run deploy` انجام می‌شود.
- Deploy command: `npm run deploy`
- متغیرهای محیطی را در تنظیمات Workers اضافه کنید: `NEXT_PUBLIC_SUPABASE_URL` و `NEXT_PUBLIC_SUPABASE_ANON_KEY`.

برای انتشار از خط فرمان، پس از ورود به حساب Cloudflare اجرا کنید: `npm run deploy`.
برای پیش‌نمایش محلی در محیط Workers: `npm run preview`.

## امکانات
- ورود مالک و مدیر با گذرواژه یا کد یک‌بارمصرف ایمیل
- مدیریت درخواست‌های نوبت (بر اساس مجوز حساب)
- ایجاد/ویرایش و انتشار محتوای دوزبانه
- بارگذاری فایل در Storage bucket با نام `lesson-media`
- دعوت مدیر جدید از طریق Edge Function به نام `create-admin`
- تنظیم مجوز مدیران توسط مالک

## امنیت
- فقط کلید عمومی Supabase در متغیرهای `NEXT_PUBLIC_*` قرار می‌گیرد؛ هرگز service-role key را وارد این پروژه نکنید.
- دسترسی واقعی داده‌ها باید با RLS دیتابیس کنترل شود؛ مخفی‌کردن دکمه‌ها به‌تنهایی کنترل امنیتی نیست.
- برای مدیریت مدیران، تابع `create-admin` باید با JWT فعال باشد و مالک را سمت سرور اعتبارسنجی کند.
