# Routing Composer Example

Example application demonstrating the **routing_composer** package.

## Features Demonstrated

- ✅ **Auth Guard Flow** - Login redirect for protected routes
- ✅ **Bottom Tab Navigation** - Persistent shell with multiple tabs
- ✅ **Deep Link Handling** - Cross-platform URI parsing
- ✅ **Error Handling** - Custom 404 pages and error recovery
- ✅ **Type-Safe Navigation** - Strongly typed routes and parameters
- ✅ **Route Observers** - Navigation event logging

## Running the Example

```bash
cd example
flutter run -d macos  # or ios, android, chrome
```

## Project Structure

```
example/
├── lib/
│   └── main.dart          # Complete example with all features
├── pubspec.yaml           # Dependencies (routing_composer from parent)
└── README.md              # This file
```

## Code Overview

The example shows how to:

1. **Define Routes**
   ```dart
   abstract final class AppRoutes {
     static const home = RouteDefinition(path: '/', name: 'home');
     static const profile = RouteDefinition(
       path: '/profile/:id',
       name: 'profile',
       requiresAuth: true,
     );
   }
   ```

2. **Create Router with Guards**
   ```dart
   final router = GoRouterAdapter(
     configuration: RouterConfiguration(
       routes: AppRoutes.all,
       initialRoute: AppRoutes.splash,
       globalGuards: [AuthGuard(authService)],
     ),
     pageBuilder: _buildPage,
   );
   ```

3. **Navigate Type-Safely**
   ```dart
   await router.goTo(
     AppRoutes.profile,
     params: ProfileParams(userId: '123'),
   );
   ```

## Try It Out

1. Run the app
2. See the splash screen transition
3. Get redirected to login (auth guard)
4. "Login" and navigate through the app
5. Test navigation features:
   - Go to different routes
   - Use browser back/forward (web)
   - Try deep links
   - Check error handling

## Learn More

- [Routing Composer Package](../)
- [Package Documentation](../README.md)
- [Unit Tests](../test/)
