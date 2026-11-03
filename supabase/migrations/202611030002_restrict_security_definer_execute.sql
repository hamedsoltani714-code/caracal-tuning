-- Restrict SECURITY DEFINER functions to the roles that need them.
-- Trigger-only routines are not callable through the public API.
revoke all on function public.can_manage_content() from public, anon, authenticated;
grant execute on function public.can_manage_content() to authenticated;
revoke all on function public.has_caracal_permission(text) from public, anon, authenticated;
grant execute on function public.has_caracal_permission(text) to authenticated;
revoke all on function public.is_booking_manager() from public, anon, authenticated;
grant execute on function public.is_booking_manager() to authenticated;
revoke all on function public.is_owner() from public, anon, authenticated;
grant execute on function public.is_owner() to authenticated;
revoke all on function public.handle_new_user() from public, anon, authenticated;
revoke all on function public.sync_caracal_profile_role() from public, anon, authenticated;
revoke all on function public.sync_caracal_user_role() from public, anon, authenticated;
