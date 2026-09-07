import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:plate_pilot/core/constants/app_constants.dart';
import 'package:plate_pilot/features/auth/data/auth_repository.dart';
import 'package:plate_pilot/features/auth/domain/user_entity.dart';
import 'package:plate_pilot/features/auth/presentation/screens/login_screen.dart';

class FakeGoogleAuthRepo implements IAuthRepository {
  bool shouldThrow = false;
  bool googleSignInCalled = false;

  @override
  UserEntity? get currentUser => null;

  @override
  Stream<UserEntity?> get authStateChanges => const Stream.empty();

  @override
  Future<bool> signInWithGoogle() async {
    googleSignInCalled = true;
    if (shouldThrow) {
      throw Exception('network connection timeout');
    }
    return true;
  }

  @override
  Future<UserEntity> signInWithEmail({required String email, required String password}) async {
    return const UserEntity(id: 'u1', email: 'test@domain.com');
  }

  @override
  Future<UserEntity> signUpWithEmail({required String email, required String password}) async {
    return const UserEntity(id: 'u1', email: 'test@domain.com');
  }

  @override
  Future<void> signOut() async {}
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('LoginScreen Google Sign-In Tests', () {
    testWidgets('renders brand elements, value propositions and Continue with Google button', (tester) async {
      final fakeRepo = FakeGoogleAuthRepo();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppConstants.appName), findsOneWidget);
      expect(find.text('Smart weekly meals • Effortless groceries'), findsOneWidget);
      expect(find.text('Personalized Meal Plans'), findsOneWidget);
      expect(find.text('Smart Grocery Lists'), findsOneWidget);
      expect(find.text('Allergen & Budget Safety'), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.byType(TextFormField), findsNothing); // Manual inputs completely removed
    });

    testWidgets('tapping Continue with Google calls signInWithGoogle', (tester) async {
      final fakeRepo = FakeGoogleAuthRepo();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Continue with Google'));
      await tester.pump();

      expect(fakeRepo.googleSignInCalled, isTrue);
    });

    testWidgets('displays sanitized user-friendly error message on failure', (tester) async {
      final fakeRepo = FakeGoogleAuthRepo()..shouldThrow = true;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Continue with Google'));
      await tester.pumpAndSettle();

      // Sanitized message from AppErrorHandler, not raw technical stack trace
      expect(find.text('Network connection issue. Please check your Wi-Fi or cellular data.'), findsOneWidget);
      expect(find.textContaining('Exception:'), findsNothing);
    });
  });
}
