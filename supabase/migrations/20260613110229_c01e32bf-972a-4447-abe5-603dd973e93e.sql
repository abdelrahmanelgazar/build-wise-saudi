
-- Lock down SECURITY DEFINER functions exposed to signed-in users.
-- has_role: keep executable by authenticated (used by RLS policies & app role checks).
-- handle_new_user: trigger only, revoke from all callers.
-- seed_demo_data: privileged seeding; remove from public API — demo data is seeded out-of-band.

REVOKE ALL ON FUNCTION public.handle_new_user() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.seed_demo_data() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.has_role(uuid, public.app_role) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.has_role(uuid, public.app_role) TO authenticated;
