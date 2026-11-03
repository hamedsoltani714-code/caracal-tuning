# CARACAL ADMIN
اپلیکیشن مستقل مدیریت CARACAL TUNING با Flutter و Supabase.

## امکانات
- ورود با ایمیل/گذرواژه یا کد یک‌بارمصرف برای حساب‌های موجود
- بررسی نقش owner/admin از جدول profiles
- داشبورد آمار
- مدیریت وضعیت درخواست‌های booking_requests
- ایجاد، ویرایش و انتشار محتوای دوزبانه در lessons
- فهرست کاربران
- دعوت مدیر با Edge Function به نام create-admin
- تنظیم دسترسی مدیران توسط مالک اصلی

## بیلد
از ریشه مخزن: وارد پوشه admin_app شوید، سپس flutter pub get و flutter build apk --release را اجرا کنید.
فقط کلید عمومی anon/publishable مجاز است؛ هرگز service_role را داخل برنامه قرار ندهید.

## امنیت و پیش‌نیازها
- جدول profiles باید نقش owner را برای حساب hamed.soltani714@gmail.com و نقش admin را برای مدیران مجاز ثبت کرده باشد.
- جدول‌های profiles، booking_requests و lessons باید RLS صحیح داشته باشند.
- کنترل‌های رابط کاربری جایگزین RLS نیستند؛ مجوزهای دیتابیس باید نقش و permissions را اعتبارسنجی کنند.
- Edge Function create-admin باید JWT را بررسی کند و مالک را سمت سرور اعتبارسنجی کند.


## Release verification
- Launcher icon asset: `assets/130315.png` (copied from the repository root by the GitHub Actions workflow).
- The release workflow builds the standalone universal Android APK and uploads it as `CARACAL-ADMIN-APK`.
- `flutter_launcher_icons` is declared as a development dependency so icon generation is reproducible in CI.
