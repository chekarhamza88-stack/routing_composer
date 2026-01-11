/// Example application demonstrating the routing abstraction.
///
/// This example shows:
/// - Auth guard flow with login redirect
/// - Bottom tab navigation with shell
/// - Deep link handling
/// - Error handling UI
///
/// Run with: `flutter run -t lib/example/example_app.dart`
library;

import 'package:flutter/material.dart';

import 'package:routing_composer/routing_composer.dart';



// ═══════════════════════════════════════════════════════════════════
// App Entry Point
// ═══════════════════════════════════════════════════════════════════

void main() {
  runApp(const ExampleApp());
}

class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key});

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  late final AppRouter _router;
  final _authService = ExampleAuthService();

  @override
  void initState() {
    super.initState();
    _router = _createRouter();
  }

  AppRouter _createRouter() {
    return GoRouterAdapter(
      configuration: RouterConfiguration(
        routes: AppRoutes.all,
        initialRoute: AppRoutes.splash,
        notFoundRoute: AppRoutes.notFound,
        globalGuards: [
          ExampleAuthGuard(_authService),
        ],
        observers: [
          LoggingNavigationObserver(),
        ],
      ),
      pageBuilder: _buildPage,
      shellBuilder: _buildShell,
    );
  }

  Widget _buildPage(
    BuildContext context,
    RouteDefinition route,
    Map<String, String> pathParams,
    Map<String, String> queryParams,
    Object? extra,
  ) {
    return switch (route.name) {
      'splash' => SplashPage(router: _router, authService: _authService),
      'login' => LoginPage(router: _router, authService: _authService),
      'home' => HomePage(router: _router),
      'userProfile' => UserProfilePage(
          router: _router,
          userId: pathParams['id'] ?? 'unknown',
          tab: queryParams['tab'],
        ),
      'settings' => SettingsPage(router: _router, authService: _authService),
      'search' => SearchPage(router: _router, query: queryParams['q']),
      'notifications' => NotificationsPage(router: _router),
      'notFound' => NotFoundPage(router: _router),
      _ => NotFoundPage(router: _router),
    };
  }

  Widget _buildShell(
    BuildContext context,
    dynamic state,
    Widget child,
  ) {
    return MainShell(router: _router, child: child);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Routing Composer Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      routerConfig: _router.routerConfig,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Auth Service
// ═══════════════════════════════════════════════════════════════════

class ExampleAuthService {
  bool _isAuthenticated = false;
  String? _userId;

  bool get isAuthenticated => _isAuthenticated;
  String? get userId => _userId;

  Future<void> login(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));
    _isAuthenticated = true;
    _userId = 'user_123';
  }

  Future<void> logout() async {
    _isAuthenticated = false;
    _userId = null;
  }
}

// ═══════════════════════════════════════════════════════════════════
// Auth Guard
// ═══════════════════════════════════════════════════════════════════

class ExampleAuthGuard implements RouteGuard {
  final ExampleAuthService _authService;

  ExampleAuthGuard(this._authService);

  @override
  String get name => 'ExampleAuthGuard';

  @override
  Future<GuardResult> canActivate(GuardContext context) async {
    // Allow public routes
    if (!context.destination.requiresAuth) {
      return const GuardAllow();
    }

    // Check authentication
    if (_authService.isAuthenticated) {
      return const GuardAllow();
    }

    // Redirect to login
    return const GuardRedirect(AppRoutes.login);
  }
}

// ═══════════════════════════════════════════════════════════════════
// Pages
// ═══════════════════════════════════════════════════════════════════

class SplashPage extends StatefulWidget {
  final AppRouter router;
  final ExampleAuthService authService;

  const SplashPage({
    super.key,
    required this.router,
    required this.authService,
  });

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(seconds: 2));

    if (widget.authService.isAuthenticated) {
      await widget.router.goTo(AppRoutes.home);
    } else {
      await widget.router.goTo(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading...'),
          ],
        ),
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  final AppRouter router;
  final ExampleAuthService authService;

  const LoginPage({
    super.key,
    required this.router,
    required this.authService,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() => _isLoading = true);

    try {
      await widget.authService.login('user@example.com', 'password');
      await widget.router.clearStackAndGoTo(AppRoutes.home);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Welcome to Routing Composer',
              style: TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _login,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  final AppRouter router;

  const HomePage({super.key, required this.router});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _NavigationCard(
            title: 'User Profile',
            subtitle: 'Navigate with path params',
            onTap: () => router.goTo(
              AppRoutes.userProfile,
              params: const UserProfileParams(userId: 'user_123', tab: 'posts'),
            ),
          ),
          _NavigationCard(
            title: 'Search',
            subtitle: 'Navigate with query params',
            onTap: () => router.goTo(
              AppRoutes.search,
              params: const SearchParams(query: 'flutter', category: 'apps'),
            ),
          ),
          _NavigationCard(
            title: 'Settings',
            subtitle: 'Simple navigation',
            onTap: () => router.goTo(AppRoutes.settings),
          ),
          _NavigationCard(
            title: 'Deep Link Test',
            subtitle: 'Handle /user/456?tab=likes',
            onTap: () => router.handleDeepLink(
              Uri.parse('/user/456?tab=likes'),
            ),
          ),
          _NavigationCard(
            title: '404 Page',
            subtitle: 'Navigate to unknown route',
            onTap: () => router.goToPath('/unknown/route'),
          ),
        ],
      ),
    );
  }
}

class UserProfilePage extends StatelessWidget {
  final AppRouter router;
  final String userId;
  final String? tab;

  const UserProfilePage({
    super.key,
    required this.router,
    required this.userId,
    this.tab,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile: $userId'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => router.goBack(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 50,
              child: Icon(Icons.person, size: 50),
            ),
            const SizedBox(height: 16),
            Text('User ID: $userId', style: const TextStyle(fontSize: 18)),
            if (tab != null)
              Text('Tab: $tab', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 32),
            Wrap(
              spacing: 8,
              children: [
                _TabChip(label: 'Overview', isSelected: tab == null),
                _TabChip(label: 'Posts', isSelected: tab == 'posts'),
                _TabChip(label: 'Likes', isSelected: tab == 'likes'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SearchPage extends StatelessWidget {
  final AppRouter router;
  final String? query;

  const SearchPage({super.key, required this.router, this.query});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            if (query != null)
              Text('Searching for: $query',
                  style: const TextStyle(fontSize: 18))
            else
              const Text('Enter a search query',
                  style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class NotificationsPage extends StatelessWidget {
  final AppRouter router;

  const NotificationsPage({super.key, required this.router});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView.builder(
        itemCount: 10,
        itemBuilder: (context, index) => ListTile(
          leading: const CircleAvatar(child: Icon(Icons.notifications)),
          title: Text('Notification ${index + 1}'),
          subtitle: const Text('Tap to view details'),
          onTap: () => router.goTo(
            AppRoutes.userProfile,
            params: UserProfileParams(userId: 'user_${index + 1}'),
          ),
        ),
      ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  final AppRouter router;
  final ExampleAuthService authService;

  const SettingsPage({
    super.key,
    required this.router,
    required this.authService,
  });

  Future<void> _logout(BuildContext context) async {
    await authService.logout();
    await router.clearStackAndGoTo(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Account'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Notifications'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.security),
            title: const Text('Privacy'),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () => _logout(context),
          ),
        ],
      ),
    );
  }
}

class NotFoundPage extends StatelessWidget {
  final AppRouter router;

  const NotFoundPage({super.key, required this.router});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Not Found')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text('404 - Page Not Found',
                style: TextStyle(fontSize: 24)),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => router.clearStackAndGoTo(AppRoutes.home),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Shell (Bottom Navigation)
// ═══════════════════════════════════════════════════════════════════

class MainShell extends StatefulWidget {
  final AppRouter router;
  final Widget child;

  const MainShell({super.key, required this.router, required this.child});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    widget.router.switchToTab(index);

    final routes = [
      AppRoutes.home,
      AppRoutes.search,
      AppRoutes.notifications,
      AppRoutes.settings,
    ];

    widget.router.goTo(routes[index]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications),
            label: 'Alerts',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Helper Widgets
// ═══════════════════════════════════════════════════════════════════

class _NavigationCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _NavigationCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final bool isSelected;

  const _TabChip({required this.label, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      backgroundColor:
          isSelected ? Theme.of(context).colorScheme.primaryContainer : null,
    );
  }
}
