
REVOKE EXECUTE ON FUNCTION public.seed_demo_data() FROM public, anon;
GRANT EXECUTE ON FUNCTION public.seed_demo_data() TO authenticated;
