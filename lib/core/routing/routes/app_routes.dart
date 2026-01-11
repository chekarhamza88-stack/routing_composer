import '../domain/domain.dart';

/// Application route definitions.
///
/// This is the single source of truth for all navigation destinations.
/// All routes are defined as static constants with typed metadata.
///
/// ## Usage
///
/// ```dart
/// // Navigate using typed routes
/// await router.goTo(AppRoutes.userProfile, params: UserProfileParams(userId: '123'));
///
/// // Access route paths for deep linking
/// final path = AppRoutes.userProfile.buildPath({'id': '123'});
/// // Returns: '/user/123'
/// ```
abstract final class AppRoutes {
  // ─────────────────────────────────────────────────────────────────
  // Public Routes (No Auth Required)
  // ─────────────────────────────────────────────────────────────────

  /// Splash/loading screen.
  static const splash = RouteDefinition(
    path: '/splash',
    name: 'splash',
  );

  /// Login screen.
  static const login = RouteDefinition(
    path: '/login',
    name: 'login',
  );

  /// Registration screen.
  static const register = RouteDefinition(
    path: '/register',
    name: 'register',
  );

  /// Forgot password screen.
  static const forgotPassword = RouteDefinition(
    path: '/forgot-password',
    name: 'forgotPassword',
  );

  // ─────────────────────────────────────────────────────────────────
  // Authenticated Routes
  // ─────────────────────────────────────────────────────────────────

  /// Home/dashboard screen.
  static const home = RouteDefinition(
    path: '/',
    name: 'home',
    requiresAuth: true,
  );

  /// User profile screen with user ID parameter.
  static const userProfile = RouteDefinition(
    path: '/user/:id',
    name: 'userProfile',
    requiresAuth: true,
  );

  /// Edit user profile screen.
  static const editProfile = RouteDefinition(
    path: '/user/:id/edit',
    name: 'editProfile',
    requiresAuth: true,
  );

  /// Settings screen.
  static const settings = RouteDefinition(
    path: '/settings',
    name: 'settings',
    requiresAuth: true,
  );

  /// Notifications screen.
  static const notifications = RouteDefinition(
    path: '/notifications',
    name: 'notifications',
    requiresAuth: true,
  );

  // ─────────────────────────────────────────────────────────────────
  // Search & Discovery
  // ─────────────────────────────────────────────────────────────────

  /// Search screen with optional query parameter.
  static const search = RouteDefinition(
    path: '/search',
    name: 'search',
    requiresAuth: true,
  );

  /// Item detail screen.
  static const itemDetail = RouteDefinition(
    path: '/item/:id',
    name: 'itemDetail',
    requiresAuth: true,
  );

  // ─────────────────────────────────────────────────────────────────
  // Shell/Tab Routes
  // ─────────────────────────────────────────────────────────────────

  /// Main shell with bottom navigation.
  static const mainShell = ShellRouteDefinition(
    path: '/',
    name: 'mainShell',
    requiresAuth: true,
    children: [
      home,
      search,
      notifications,
      settings,
    ],
  );

  // ─────────────────────────────────────────────────────────────────
  // Error Routes
  // ─────────────────────────────────────────────────────────────────

  /// 404 Not Found screen.
  static const notFound = RouteDefinition(
    path: '/404',
    name: 'notFound',
  );

  /// Error screen with optional error details.
  static const error = RouteDefinition(
    path: '/error',
    name: 'error',
  );

  // ─────────────────────────────────────────────────────────────────
  // Route Collections
  // ─────────────────────────────────────────────────────────────────

  /// All routes for router configuration.
  static const List<RouteDefinition> all = [
    splash,
    login,
    register,
    forgotPassword,
    home,
    userProfile,
    editProfile,
    settings,
    notifications,
    search,
    itemDetail,
    notFound,
    error,
  ];

  /// Public routes that don't require authentication.
  static const List<RouteDefinition> publicRoutes = [
    splash,
    login,
    register,
    forgotPassword,
    notFound,
    error,
  ];

  /// Routes that require authentication.
  static List<RouteDefinition> get authenticatedRoutes =>
      all.where((r) => r.requiresAuth).toList();
}

// ─────────────────────────────────────────────────────────────────
// Typed Route Parameters
// ─────────────────────────────────────────────────────────────────

/// Parameters for user profile route.
class UserProfileParams extends RouteParams {
  /// The user ID to display.
  final String userId;

  /// Optional tab to display (overview, posts, likes).
  final String? tab;

  /// Creates user profile parameters.
  const UserProfileParams({
    required this.userId,
    this.tab,
  });

  @override
  Map<String, String> toPathParams() => {'id': userId};

  @override
  Map<String, String> toQueryParams() => tab != null ? {'tab': tab!} : {};
}

/// Parameters for edit profile route.
class EditProfileParams extends RouteParams {
  /// The user ID to edit.
  final String userId;

  /// Creates edit profile parameters.
  const EditProfileParams({required this.userId});

  @override
  Map<String, String> toPathParams() => {'id': userId};
}

/// Parameters for search route.
class SearchParams extends RouteParams {
  /// Search query string.
  final String? query;

  /// Filter category.
  final String? category;

  /// Creates search parameters.
  const SearchParams({this.query, this.category});

  @override
  Map<String, String> toPathParams() => {};

  @override
  Map<String, String> toQueryParams() {
    final params = <String, String>{};
    if (query != null) params['q'] = query!;
    if (category != null) params['category'] = category!;
    return params;
  }
}

/// Parameters for item detail route.
class ItemDetailParams extends RouteParams {
  /// The item ID to display.
  final String itemId;

  /// Creates item detail parameters.
  const ItemDetailParams({required this.itemId});

  @override
  Map<String, String> toPathParams() => {'id': itemId};
}

/// Parameters for error route.
class ErrorParams extends RouteParams {
  /// Error message to display.
  final String? message;

  /// Error code for reference.
  final String? code;

  /// Creates error parameters.
  const ErrorParams({this.message, this.code});

  @override
  Map<String, String> toPathParams() => {};

  @override
  Map<String, String> toQueryParams() {
    final params = <String, String>{};
    if (message != null) params['message'] = message!;
    if (code != null) params['code'] = code!;
    return params;
  }
}
