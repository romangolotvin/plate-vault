import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app_state.dart';
import '../../core/theme.dart';
import '../../core/widgets/plate_badge.dart';
import '../../core/widgets/vault_cta.dart';
import '../../core/widgets/vault_scaffold.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  late final AnimationController _enter;
  final _nameCtrl = TextEditingController(text: 'Коллекционер');
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _enter.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return VaultScaffold(
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _enter,
          builder: (context, _) {
            final t = Curves.easeOutCubic.transform(_enter.value);
            return Opacity(
              opacity: t.clamp(0.0, 1.0),
              child: Transform.translate(
                offset: Offset(0, (1 - t) * 28),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                  children: [
                    Text(
                      'PLATE VAULT',
                      style:
                          Theme.of(context).textTheme.headlineLarge?.copyWith(
                                color: VaultColors.purpleBright,
                                letterSpacing: 2.2,
                                fontWeight: FontWeight.w800,
                                shadows: [
                                  Shadow(
                                    color: VaultColors.purple
                                        .withValues(alpha: 0.55),
                                    blurRadius: 22,
                                  ),
                                ],
                              ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Охоться за сериями на улице. Два ракурса камерой — Street в коллекции.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: VaultColors.mist,
                            height: 1.4,
                          ),
                    ),
                    const SizedBox(height: 22),
                    VaultHeroPanel(
                      padding: const EdgeInsets.all(16),
                      child: const PlateBadge(
                        text: 'МЕР777178',
                        countryCode: 'RU',
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (!state.cloudEnabled)
                      VaultHeroPanel(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Локальный профиль',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    color: VaultColors.purpleBright,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Firebase ещё не подключён — коллекция на устройстве. Street-рейтинг и счётчик находок работают локально.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: VaultColors.mist,
                                    height: 1.35,
                                  ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _nameCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Имя коллекционера',
                              ),
                            ),
                            const SizedBox(height: 16),
                            VaultCta(
                              label: 'Войти в коллекцию',
                              icon: Icons.lock_open_rounded,
                              busy: _busy,
                              onPressed: _busy
                                  ? null
                                  : () => _run(
                                        () => state.signInLocal(_nameCtrl.text),
                                      ),
                            ),
                          ],
                        ),
                      ),
                    if (state.cloudEnabled) ...[
                      TabBar(
                        controller: _tabs,
                        labelColor: VaultColors.purpleBright,
                        unselectedLabelColor: VaultColors.mist,
                        indicatorColor: VaultColors.purple,
                        tabs: const [
                          Tab(text: 'Вход'),
                          Tab(text: 'Регистрация'),
                        ],
                      ),
                      SizedBox(
                        height: 320,
                        child: TabBarView(
                          controller: _tabs,
                          children: [
                            _emailForm(signUp: false, state: state),
                            _emailForm(signUp: true, state: state),
                          ],
                        ),
                      ),
                      VaultCta(
                        label: 'Продолжить без облака',
                        secondary: true,
                        busy: _busy,
                        onPressed: _busy
                            ? null
                            : () =>
                                _run(() => state.signInLocal(_nameCtrl.text)),
                      ),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _emailForm({required bool signUp, required AppState state}) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        children: [
          if (signUp)
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Имя'),
            ),
          if (signUp) const SizedBox(height: 8),
          TextField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _passwordCtrl,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Пароль'),
          ),
          const SizedBox(height: 16),
          VaultCta(
            label: signUp ? 'Создать аккаунт' : 'Войти',
            icon: Icons.login_rounded,
            busy: _busy,
            onPressed: _busy
                ? null
                : () => _run(() async {
                      if (signUp) {
                        await state.registerEmail(
                          email: _emailCtrl.text,
                          password: _passwordCtrl.text,
                          displayName: _nameCtrl.text,
                        );
                      } else {
                        await state.signInEmail(
                          email: _emailCtrl.text,
                          password: _passwordCtrl.text,
                        );
                      }
                    }),
          ),
        ],
      ),
    );
  }
}
