/// Shared authentication service for the example application.
library;

/// Example authentication service that manages user authentication state.
///
/// This is a simple in-memory implementation for demonstration purposes.
/// In a real application, this would connect to your auth backend.
class ExampleAuthService {
  bool _isAuthenticated = false;
  String? _userId;

  /// Whether the user is currently authenticated.
  bool get isAuthenticated => _isAuthenticated;

  /// The current user's ID, if authenticated.
  String? get userId => _userId;

  /// Simulates a login operation.
  ///
  /// In a real app, this would validate credentials against a backend.
  Future<void> login(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));
    _isAuthenticated = true;
    _userId = 'user_123';
  }

  /// Logs out the current user.
  Future<void> logout() async {
    _isAuthenticated = false;
    _userId = null;
  }
}
