import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:plate_pilot/core/constants/app_constants.dart';
import 'package:plate_pilot/features/auth/data/auth_repository.dart';
import 'package:plate_pilot/features/auth/domain/user_entity.dart';
import 'package:plate_pilot/features/auth/presentation/screens/register_screen.dart';

class FakeRegisterAuthRepo implements IAuthRepository {
  @override
  UserEntity? get currentUser => null;

  @override
  Stream<UserEntity?> get authStateChanges => const Stream.empty();

  @override
  Future<bool> signInWithGoogle() async => true;

  @override
  Future<UserEntity> signInWithEmail({required String email, required String password}) async =>
      const UserEntity(id: 'u1', email: 'test@domain.com');

  @override
  Future<UserEntity> signUpWithEmail({required String email, required String password}) async =>
      const UserEntity(id: 'u1', email: 'test@domain.com');

  @override
  Future<void> signOut() async {}
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('RegisterScreen Tests', () {
    testWidgets('renders unified single-sign-on Google interface', (tester) async {
      final fakeRepo = FakeRegisterAuthRepo();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MaterialApp(
            home: RegisterScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppConstants.appName), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.byType(TextFormField), findsNothing);
    });
  });
}
