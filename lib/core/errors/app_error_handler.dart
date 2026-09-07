import 'dart:async';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Centralized utility to transform raw exceptions into polite, user-friendly messages.
/// Ensures no raw Supabase technical strings, SQL errors, or stack traces leak to users.
class AppErrorHandler {
  AppErrorHandler._();

  /// Converts any exception into a clear, non-technical, user-friendly message.
  static String toUserFriendlyMessage(dynamic error) {
    if (error == null) return 'An unexpected error occurred. Please try again.';

    if (error is AuthException) {
      final msg = error.message.toLowerCase();

      if (msg.contains('invalid login credentials') || msg.contains('invalid grant')) {
        return 'The login credentials provided are incorrect. Please try again.';
      }
      if (msg.contains('user already registered') || msg.contains('email already in use')) {
        return 'An account already exists with this Google account. Please sign in instead.';
      }
      if (msg.contains('network') || msg.contains('connection') || msg.contains('timeout')) {
        return 'Network error. Please check your internet connection and try again.';
      }
      if (msg.contains('cancelled') || msg.contains('canceled') || msg.contains('abort')) {
        return 'Google sign-in was cancelled.';
      }
      if (msg.contains('popup closed') || msg.contains('user closed')) {
        return 'Sign-in was closed before completing. Please try again.';
      }

      // Return a clean message if it's safe, otherwise fall back to generic
      if (error.message.isNotEmpty && error.message.length < 80 && !error.message.contains('{')) {
        return error.message;
      }
      return 'Unable to sign in. Please try again in a moment.';
    }

    if (error is PostgrestException) {
      final msg = error.message.toLowerCase();
      if (msg.contains('row-level security') || msg.contains('permission denied')) {
        return 'You do not have permission to perform this action.';
      }
      if (msg.contains('duplicate key') || msg.contains('unique constraint')) {
        return 'This information is already saved in your account.';
      }
      return 'Unable to save data. Please check your details and try again.';
    }

    if (error is SocketException || error is TimeoutException) {
      return 'Connection timed out. Please check your internet connection and try again.';
    }

    final rawString = error.toString().toLowerCase();
    if (rawString.contains('cancelled') || rawString.contains('canceled')) {
      return 'Action was cancelled.';
    }
    if (rawString.contains('network') || rawString.contains('offline') || rawString.contains('socket')) {
      return 'Network connection issue. Please check your Wi-Fi or cellular data.';
    }

    // Default polite message without technical jargon
    return 'Something went wrong. Please try again in a moment.';
  }
}
