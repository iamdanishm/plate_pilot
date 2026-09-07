import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plate_pilot/features/auth/data/auth_repository.dart';
import 'package:plate_pilot/features/auth/domain/user_entity.dart';

class AuthController extends StateNotifier<AsyncValue<UserEntity?>> {
  final IAuthRepository _authRepository;

  AuthController(this._authRepository)
      : super(AsyncData(_authRepository.currentUser));

  Future<void> signInWithGoogle() async {
    state = const AsyncLoading();
    try {
      await _authRepository.signInWithGoogle();
      state = AsyncData(_authRepository.currentUser);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> signIn(String email, String password) async {
    state = const AsyncLoading();
    try {
      final user = await _authRepository.signInWithEmail(
        email: email,
        password: password,
      );
      state = AsyncData(user);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> signUp(String email, String password) async {
    state = const AsyncLoading();
    try {
      final user = await _authRepository.signUpWithEmail(
        email: email,
        password: password,
      );
      state = AsyncData(user);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    try {
      await _authRepository.signOut();
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  void resetError() {
    if (state.hasError) {
      state = AsyncData(_authRepository.currentUser);
    }
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<UserEntity?>>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return AuthController(authRepo);
});
