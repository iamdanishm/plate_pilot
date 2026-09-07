import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:plate_pilot/core/constants/app_constants.dart';
import 'package:plate_pilot/core/errors/app_error_handler.dart';
import 'package:plate_pilot/core/theme/app_theme.dart';
import 'package:plate_pilot/core/theme/glass_container.dart';
import 'package:plate_pilot/features/auth/presentation/controllers/auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  Future<void> _handleGoogleSignIn() async {
    await ref.read(authControllerProvider.notifier).signInWithGoogle();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isIOS = AppTheme.isIOS;
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    ref.listen(authControllerProvider, (previous, next) {
      if (next.hasValue && next.value != null && !next.isLoading) {
        if (GoRouter.maybeOf(context) != null) {
          context.go('/splash');
        }
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Brand Icon
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppTheme.primaryEmerald,
                            AppTheme.primaryEmeraldDark,
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryEmerald.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.restaurant_menu_rounded,
                        size: 42,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // App Title & Tagline
                  Text(
                    AppConstants.appName,
                    textAlign: TextAlign.center,
                    style: AppTheme.fontStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Smart weekly meals • Effortless groceries',
                    textAlign: TextAlign.center,
                    style: AppTheme.fontStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Feature Cards Container
                  if (isIOS)
                    GlassContainer(
                      padding: const EdgeInsets.all(20),
                      child: _buildValueHighlights(context),
                    )
                  else
                    Card(
                      elevation: 0,
                      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: _buildValueHighlights(context),
                      ),
                    ),

                  const SizedBox(height: 28),

                  // User-friendly Sanitized Error Banner
                  if (authState.hasError) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.error.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: Theme.of(context).colorScheme.error,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              AppErrorHandler.toUserFriendlyMessage(authState.error),
                              style: AppTheme.fontStyle(
                                fontSize: 13,
                                color: Theme.of(context).colorScheme.onErrorContainer,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Continue with Google Button
                  SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _handleGoogleSignIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                        foregroundColor: isDark ? Colors.white : const Color(0xFF1E293B),
                        elevation: isDark ? 0 : 2,
                        shadowColor: Colors.black.withValues(alpha: 0.1),
                        side: BorderSide(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.15)
                              : Colors.black.withValues(alpha: 0.12),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: AppTheme.primaryEmerald,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildGoogleIcon(),
                                const SizedBox(width: 14),
                                Text(
                                  'Continue with Google',
                                  style: AppTheme.fontStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Terms & Privacy Note
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'By continuing, you agree to PlatePilot’s Terms of Service and Privacy Policy.',
                      textAlign: TextAlign.center,
                      style: AppTheme.fontStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildValueHighlights(BuildContext context) {
    return Column(
      children: [
        _buildHighlightRow(
          context,
          icon: Icons.auto_awesome_rounded,
          color: AppTheme.primaryEmerald,
          title: 'Personalized Meal Plans',
          subtitle: 'Tailored to your household size and taste',
        ),
        const Divider(height: 20),
        _buildHighlightRow(
          context,
          icon: Icons.shopping_cart_checkout_rounded,
          color: AppTheme.secondaryAmberDark,
          title: 'Smart Grocery Lists',
          subtitle: 'Aggregated automatically from selected recipes',
        ),
        const Divider(height: 20),
        _buildHighlightRow(
          context,
          icon: Icons.shield_outlined,
          color: const Color(0xFF3B82F6),
          title: 'Allergen & Budget Safety',
          subtitle: 'Strict deterministic ingredient exclusions',
        ),
      ],
    );
  }

  Widget _buildHighlightRow(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTheme.fontStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTheme.fontStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGoogleIcon() {
    return Container(
      width: 22,
      height: 22,
      decoration: const BoxDecoration(shape: BoxShape.circle),
      child: CustomPaint(
        painter: _GoogleLogoPainter(),
      ),
    );
  }
}

/// Precise vector painter for official 4-color Google logo G
class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);
    final radius = w / 2;

    final redPaint = Paint()..color = const Color(0xFFEA4335);
    final yellowPaint = Paint()..color = const Color(0xFFFBBC05);
    final greenPaint = Paint()..color = const Color(0xFF34A853);
    final bluePaint = Paint()..color = const Color(0xFF4285F4);

    final pathRed = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(Rect.fromCircle(center: center, radius: radius), -2.6, 1.4, false)
      ..close();
    canvas.drawPath(pathRed, redPaint);

    final pathYellow = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(Rect.fromCircle(center: center, radius: radius), -1.2, 1.2, false)
      ..close();
    canvas.drawPath(pathYellow, yellowPaint);

    final pathGreen = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(Rect.fromCircle(center: center, radius: radius), 0.0, 1.5, false)
      ..close();
    canvas.drawPath(pathGreen, greenPaint);

    final pathBlue = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(Rect.fromCircle(center: center, radius: radius), 1.5, 1.8, false)
      ..close();
    canvas.drawPath(pathBlue, bluePaint);

    // Inner cutout
    final innerPaint = Paint()..color = Colors.white;
    canvas.drawCircle(center, radius * 0.55, innerPaint);

    // Blue horizontal bar
    final barRect = Rect.fromLTWH(center.dx, center.dy - radius * 0.22, radius, radius * 0.44);
    canvas.drawRect(barRect, bluePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
