import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_constants.dart';

/// Provider for the global [SupabaseClient] instance.
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// Provider for the [GoTrueClient] / auth instance from Supabase.
final supabaseAuthProvider = Provider<GoTrueClient>((ref) {
  return ref.watch(supabaseClientProvider).auth;
});

/// Stream provider for raw Supabase auth state changes.
final supabaseAuthStateChangesProvider = StreamProvider<AuthState>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return supabase.auth.onAuthStateChange;
});

/// Initializes Supabase with environment variables from `.env`.
Future<void> initSupabase() async {
  await dotenv.load(fileName: '.env');

  final supabaseUrl = dotenv.env[AppConstants.envSupabaseUrl] ?? '';
  final supabaseAnonKey = dotenv.env[AppConstants.envSupabaseAnonKey] ??
      dotenv.env[AppConstants.envSupabasePublishableKey] ??
      '';

  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    throw StateError(
      'Supabase URL or Key missing in .env. Ensure SUPABASE_URL and SUPABASE_ANON_KEY are set.',
    );
  }

  await Supabase.initialize(
    url: supabaseUrl,
    // ignore: deprecated_member_use
    anonKey: supabaseAnonKey,
  );
}
