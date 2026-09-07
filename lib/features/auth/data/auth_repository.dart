import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:plate_pilot/core/constants/app_constants.dart';
import 'package:plate_pilot/core/network/supabase_client.dart';
import 'package:plate_pilot/features/auth/domain/user_entity.dart';

abstract class IAuthRepository {
  UserEntity? get currentUser;
  Stream<UserEntity?> get authStateChanges;
  Future<bool> signInWithGoogle();
  Future<UserEntity> signInWithEmail({required String email, required String password});
  Future<UserEntity> signUpWithEmail({required String email, required String password});
  Future<void> signOut();
}

class AuthRepository implements IAuthRepository {
  final supabase.SupabaseClient _client;
  static bool _googleSignInInitialized = false;

  AuthRepository(this._client);

  static Future<void> ensureGoogleSignInInitialized() async {
    if (_googleSignInInitialized) return;
    final webClientId = dotenv.env[AppConstants.envGoogleWebClientId];
    final iosClientId = dotenv.env[AppConstants.envGoogleIosClientId];

    await GoogleSignIn.instance.initialize(
      clientId: kIsWeb ? webClientId : iosClientId,
      serverClientId: webClientId,
    );
    _googleSignInInitialized = true;
  }

  @override
  UserEntity? get currentUser {
    final user = _client.auth.currentUser;
    return user != null ? UserEntity.fromSupabaseUser(user) : null;
  }

  @override
  Stream<UserEntity?> get authStateChanges {
    return _client.auth.onAuthStateChange.map((data) {
      final user = data.session?.user;
      return user != null ? UserEntity.fromSupabaseUser(user) : null;
    });
  }

  @override
  Future<bool> signInWithGoogle() async {
    await ensureGoogleSignInInitialized();

    try {
      final googleUser = await GoogleSignIn.instance.authenticate();
      final idToken = googleUser.authentication.idToken;

      if (idToken == null) {
        throw Exception('No ID Token found from Google Sign-In');
      }

      String? accessToken;
      try {
        final authz = await googleUser.authorizationClient.authorizationForScopes([
          'email',
          'profile',
        ]);
        accessToken = authz?.accessToken;
      } catch (_) {
        // Access token is optional for Supabase signInWithIdToken
      }

      final response = await _client.auth.signInWithIdToken(
        provider: supabase.OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      return response.user != null;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        // User cancelled the native sign-in dialog
        return false;
      }
      rethrow;
    }
  }

  @override
  Future<UserEntity> signInWithEmail({required String email, required String password}) async {
    final response = await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
    final user = response.user;
    if (user == null) {
      throw Exception('Login succeeded but user data was null');
    }
    return UserEntity.fromSupabaseUser(user);
  }

  @override
  Future<UserEntity> signUpWithEmail({required String email, required String password}) async {
    final response = await _client.auth.signUp(
      email: email.trim(),
      password: password,
    );
    final user = response.user;
    if (user == null) {
      throw Exception('Registration succeeded but user data was null');
    }
    return UserEntity.fromSupabaseUser(user);
  }

  @override
  Future<void> signOut() async {
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // Ignore if google sign-in was not active
    }
    await _client.auth.signOut();
  }
}

final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return AuthRepository(client);
});

final authStateChangesProvider = StreamProvider<UserEntity?>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return authRepo.authStateChanges;
});
