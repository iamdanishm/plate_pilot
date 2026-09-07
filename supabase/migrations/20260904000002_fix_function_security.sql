-- =============================================================================
-- PlatePilot: Tighten Internal Helper Function Security
-- =============================================================================

-- Ensure internal RLS helper is SECURITY INVOKER and cannot be directly executed as an RPC
ALTER FUNCTION public.user_owns_household(UUID) SECURITY INVOKER;
REVOKE EXECUTE ON FUNCTION public.user_owns_household(UUID) FROM anon, authenticated;
GRANT EXECUTE ON FUNCTION public.user_owns_household(UUID) TO service_role;
