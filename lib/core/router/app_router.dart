import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/home_screen.dart';
import '../../features/radar/radar_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/warnings/warnings_screen.dart';
import '../ads/banner_ad_view.dart';

/// Wraps the [GoRouter] so it can be exposed through Riverpod.
class GoRouterConfig {
  GoRouterConfig(this.config);
  final GoRouter config;
}

final Provider<GoRouterConfig> appRouterProvider =
    Provider<GoRouterConfig>((Ref ref) {
  return GoRouterConfig(_buildRouter());
});

class BrollyRoutes {
  BrollyRoutes._();
  static const String home = '/';
  static const String radar = '/radar';
  static const String warnings = '/warnings';
  static const String settings = '/settings';

  // Warnings is registered as a route but intentionally not in `ordered`
  // so it doesn't appear in the bottom nav for now. The route + screen code
  // are kept so it can be re-enabled later by adding `warnings` back here.
  static const List<String> ordered = <String>[home, radar, settings];
}

GoRouter _buildRouter() {
  return GoRouter(
    initialLocation: BrollyRoutes.home,
    routes: <RouteBase>[
      ShellRoute(
        builder: (BuildContext context, GoRouterState state, Widget child) {
          return _RootScaffold(child: child);
        },
        routes: <RouteBase>[
          GoRoute(
            path: BrollyRoutes.home,
            pageBuilder: (BuildContext c, GoRouterState s) =>
                const NoTransitionPage<void>(child: HomeScreen()),
          ),
          GoRoute(
            path: BrollyRoutes.radar,
            pageBuilder: (BuildContext c, GoRouterState s) =>
                const NoTransitionPage<void>(child: RadarScreen()),
          ),
          GoRoute(
            path: BrollyRoutes.warnings,
            pageBuilder: (BuildContext c, GoRouterState s) =>
                const NoTransitionPage<void>(child: WarningsScreen()),
          ),
          GoRoute(
            path: BrollyRoutes.settings,
            pageBuilder: (BuildContext c, GoRouterState s) =>
                const NoTransitionPage<void>(child: SettingsScreen()),
          ),
        ],
      ),
    ],
  );
}

class _RootScaffold extends StatelessWidget {
  const _RootScaffold({required this.child});
  final Widget child;

  static const List<NavigationDestination> _destinations = <NavigationDestination>[
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home),
      label: 'Home',
    ),
    NavigationDestination(
      icon: Icon(Icons.radar_outlined),
      selectedIcon: Icon(Icons.radar),
      label: 'Radar',
    ),
    NavigationDestination(
      icon: Icon(Icons.settings_outlined),
      selectedIcon: Icon(Icons.settings),
      label: 'Settings',
    ),
  ];

  int _indexFor(String location) {
    for (int i = 0; i < BrollyRoutes.ordered.length; i++) {
      if (location == BrollyRoutes.ordered[i] ||
          (location != '/' && BrollyRoutes.ordered[i] != '/' &&
              location.startsWith(BrollyRoutes.ordered[i]))) {
        return i;
      }
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final String location = GoRouterState.of(context).matchedLocation;
    final int index = _indexFor(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const HomeBannerAd(),
          NavigationBar(
            selectedIndex: index,
            destinations: _destinations,
            onDestinationSelected:
                (int i) => context.go(BrollyRoutes.ordered[i]),
          ),
        ],
      ),
    );
  }
}
