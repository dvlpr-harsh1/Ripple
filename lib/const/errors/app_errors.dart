sealed class AppError {
  final String message;
  const AppError(this.message);
}

class NetworkError extends AppError {
  const NetworkError() : super('No Internet Connection');
}

class AuthErrors extends AppError {
  const AuthErrors({required String message}) : super(message);
}

class UnknownErrors extends AppError {
  const UnknownErrors() : super('Something went wrong. Please try again');
}

///Yo convert Firebase error lcode into readable.
String firebaseAuthErrorToMessage(String code) {
  return switch (code) {
    // ── Login errors ──────────────────────────────
    'user-not-found' => 'No account found with this email.',
    'wrong-password' => 'Incorrect password. Please try again.',
    'invalid-credential' => 'Email or password is incorrect.',
    'user-disabled' => 'This account has been disabled.',

    // ── Sign up errors ────────────────────────────
    'email-already-in-use' => 'An account already exists with this email.',
    'weak-password' => 'Password must be at least 6 characters.',
    'invalid-email' => 'Please enter a valid email address.',

    // ── Network / general errors ──────────────────
    'network-request-failed' => 'No internet connection. Please try again.',
    'too-many-requests' => 'Too many attempts. Please wait and try again.',
    'operation-not-allowed' => 'This sign-in method is not enabled.',

    _ => 'Something went wrong. Please try again.',
  };
}
