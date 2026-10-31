import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'app_state.dart';
import 'core/theme.dart';
import 'core/widgets/vault_anim.dart';
import 'core/widgets/vault_scaffold.dart';
import 'features/auth/auth_screen.dart';
import 'features/collection/collection_screen.dart';
import 'features/leaderboard/leaderboard_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/public/public_screen.dart';
import 'features/scan/scan_screen.dart';

class PlateVaultApp extends StatelessWidget {
  const PlateVaultApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Plate Vault',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark().copyWith(
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: _VaultPageTransitionsBuilder(),
            TargetPlatform.iOS: _VaultPageTransitionsBuilder(),
            TargetPlatform.windows: _VaultPageTransitionsBuilder(),
          },
        ),
      ),
      home: const _RootGate(),
    );
  }
}

class _VaultPageTransitionsBuilder extends PageTransitionsBuilder {
  const _VaultPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return vaultSlideSwitch(child, animation);
  }
}

class _RootGate extends StatelessWidget {
  const _RootGate();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (!state.ready) {
      return VaultScaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.92, end: 1),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutBack,
                builder: (context, scale, child) =>
                    Transform.scale(scale: scale, child: child),
                child: Text(
                  'Plate Vault',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: VaultColors.purpleBright,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              const SizedBox(height: 20),
              const CircularProgressIndicator(color: VaultColors.purple),
            ],
          ),
        ),
      );
    }
    if (!state.isSignedIn) {
      return const AuthScreen();
    }
    return const HomeShell();
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with TickerProviderStateMixin {
  int _index = 0;
  late final AnimationController _tabMotion;

  static const _pages = [
    CollectionScreen(),
    ScanScreen(),
    LeaderboardScreen(),
    PublicScreen(),
    ProfileScreen(isTab: true),
  ];

  @override
  void initState() {
    super.initState();
    _tabMotion = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
      value: 1,
    );
  }

  @override
  void dispose() {
    _tabMotion.dispose();
    super.dispose();
  }

  void _select(int i) {
    if (i == _index) return;
    HapticFeedback.selectionClick();
    setState(() => _index = i);
    _tabMotion
      ..value = 0
      ..animateTo(1, curve: Curves.easeOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    return VaultScaffold(
      body: AnimatedBuilder(
        animation: _tabMotion,
        builder: (context, _) {
          // Slide + scale only — never fade the whole tab to 0.
          final t = Curves.easeOutCubic.transform(_tabMotion.value);
          return Transform.translate(
            offset: Offset(0, (1 - t) * 10),
            child: Transform.scale(
              scale: 0.985 + 0.015 * t,
              alignment: Alignment.topCenter,
              child: IndexedStack(index: _index, children: _pages),
            ),
          );
        },
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _select,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        height: 68,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront),
            label: 'Витрина',
          ),
          NavigationDestination(
            icon: Icon(Icons.photo_camera_outlined),
            selectedIcon: Icon(Icons.photo_camera),
            label: 'Скан',
          ),
          NavigationDestination(
            icon: Icon(Icons.emoji_events_outlined),
            selectedIcon: Icon(Icons.emoji_events),
            label: 'Топ',
          ),
          NavigationDestination(
            icon: Icon(Icons.public_outlined),
            selectedIcon: Icon(Icons.public),
            label: 'Мир',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Профиль',
          ),
        ],
      ),
    );
  }
}
