import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_state.dart';
import 'core/theme.dart';
import 'core/widgets/vault_scaffold.dart';
import 'features/auth/auth_screen.dart';
import 'features/collection/collection_screen.dart';
import 'features/leaderboard/leaderboard_screen.dart';
import 'features/public/public_screen.dart';
import 'features/scan/scan_screen.dart';
import 'features/settings/settings_screen.dart';

class PlateVaultApp extends StatelessWidget {
  const PlateVaultApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Plate Vault',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: const _RootGate(),
    );
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
                        color: VaultColors.gold,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              const SizedBox(height: 20),
              const CircularProgressIndicator(),
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
  late final AnimationController _tabSpring;

  static const _pages = [
    CollectionScreen(),
    ScanScreen(),
    LeaderboardScreen(),
    PublicScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _tabSpring = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    )..value = 1;
  }

  @override
  void dispose() {
    _tabSpring.dispose();
    super.dispose();
  }

  void _select(int i) {
    if (i == _index) return;
    setState(() => _index = i);
    _tabSpring
      ..value = 0
      ..animateTo(1, curve: Curves.easeOutBack);
  }

  @override
  Widget build(BuildContext context) {
    return VaultScaffold(
      body: AnimatedBuilder(
        animation: _tabSpring,
        builder: (context, _) {
          final t = Curves.easeOutBack.transform(_tabSpring.value);
          return Transform.translate(
            offset: Offset(0, (1 - t) * 18),
            child: Opacity(
              opacity: t.clamp(0.0, 1.0),
              child: IndexedStack(index: _index, children: _pages),
            ),
          );
        },
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _select,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.collections_bookmark_outlined),
            selectedIcon: Icon(Icons.collections_bookmark),
            label: 'Коллекция',
          ),
          NavigationDestination(
            icon: Icon(Icons.photo_camera_outlined),
            selectedIcon: Icon(Icons.photo_camera),
            label: 'Скан',
          ),
          NavigationDestination(
            icon: Icon(Icons.emoji_events_outlined),
            selectedIcon: Icon(Icons.emoji_events),
            label: 'Рейтинг',
          ),
          NavigationDestination(
            icon: Icon(Icons.public_outlined),
            selectedIcon: Icon(Icons.public),
            label: 'Публичные',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Настройки',
          ),
        ],
      ),
    );
  }
}
