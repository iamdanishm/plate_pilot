import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plate_pilot/features/auth/data/auth_repository.dart';
import 'package:plate_pilot/features/auth/domain/user_entity.dart';
import 'package:plate_pilot/features/auth/presentation/controllers/auth_controller.dart';

class MockAuthRepository implements IAuthRepository {
  UserEntity? _user;
  final _controller = StreamController<UserEntity?>.broadcast();
  bool shouldThrow = false;

  MockAuthRepository([this._user]);

  @override
  UserEntity? get currentUser => _user;

  @override
  Stream<UserEntity?> get authStateChanges => _controller.stream;

  @override
  Future<UserEntity> signInWithEmail({required String email, required String password}) async {
    if (shouldThrow) throw Exception('Invalid login credentials');
    _user = UserEntity(id: 'user_123', email: email);
    _controller.add(_user);
    return _user!;
  }

  @override
  Future<UserEntity> signUpWithEmail({required String email, required String password}) async {
    if (shouldThrow) throw Exception('Email already registered');
    _user = UserEntity(id: 'user_456', email: email);
    _controller.add(_user);
    return _user!;
  }

  @override
  Future<bool> signInWithGoogle() async {
    if (shouldThrow) throw Exception('Google sign-in cancelled');
    _user = const UserEntity(id: 'google_user_1', email: 'google@test.com');
    _controller.add(_user);
    return true;
  }

  @override
  Future<void> signOut() async {
    _user = null;
    _controller.add(null);
  }
}

void main() {
  group('AuthController State Transition Tests', () {
    test('initial state contains current user', () {
      final mockRepo = MockAuthRepository(const UserEntity(id: 'init_user', email: 'init@test.com'));
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );

      final state = container.read(authControllerProvider);
      expect(state.value?.id, 'init_user');
      expect(state.value?.email, 'init@test.com');
    });

    test('successful signIn sets AsyncData with user', () async {
      final mockRepo = MockAuthRepository();
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );

      final controller = container.read(authControllerProvider.notifier);
      await controller.signIn('chef@platepilot.com', 'password123');

      final state = container.read(authControllerProvider);
      expect(state.hasError, false);
      expect(state.value?.id, 'user_123');
      expect(state.value?.email, 'chef@platepilot.com');
    });

    test('failed signIn sets AsyncError', () async {
      final mockRepo = MockAuthRepository()..shouldThrow = true;
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );

      final controller = container.read(authControllerProvider.notifier);
      await controller.signIn('bad@platepilot.com', 'wrongpass');

      final state = container.read(authControllerProvider);
      expect(state.hasError, true);
      expect(state.error.toString(), contains('Invalid login credentials'));
    });

    test('signOut clears user and sets AsyncData(null)', () async {
      final mockRepo = MockAuthRepository(const UserEntity(id: 'logged_in', email: 'user@test.com'));
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );

      final controller = container.read(authControllerProvider.notifier);
      await controller.signOut();

      final state = container.read(authControllerProvider);
      expect(state.hasError, false);
      expect(state.value, isNull);
    });

    test('signInWithGoogle sets user on success', () async {
      final mockRepo = MockAuthRepository();
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );

      final controller = container.read(authControllerProvider.notifier);
      await controller.signInWithGoogle();

      final state = container.read(authControllerProvider);
      expect(state.hasError, false);
      expect(state.value?.id, 'google_user_1');
      expect(state.value?.email, 'google@test.com');
    });

    test('signInWithGoogle sets AsyncError on failure', () async {
      final mockRepo = MockAuthRepository()..shouldThrow = true;
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );

      final controller = container.read(authControllerProvider.notifier);
      await controller.signInWithGoogle();

      final state = container.read(authControllerProvider);
      expect(state.hasError, true);
      expect(state.error.toString(), contains('Google sign-in cancelled'));
    });
  });
}
