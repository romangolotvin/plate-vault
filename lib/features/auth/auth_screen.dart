import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app_state.dart';
import '../../core/theme.dart';
import '../../core/widgets/plate_badge.dart';
import '../../core/widgets/vault_scaffold.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _nameCtrl = TextEditingController(text: 'Коллекционер');
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
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
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          children: [
            Text(
              'PLATE VAULT',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: VaultColors.gold,
                    letterSpacing: 2.6,
                    fontWeight: FontWeight.w700,
                    shadows: [
                      Shadow(
                        color: VaultColors.gold.withValues(alpha: 0.35),
                        blurRadius: 18,
                      ),
                    ],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Охоться за сериями. МЕР, ВОР, столицы — сейф считает редкость и цену.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: VaultColors.mist,
                    height: 1.35,
                  ),
            ),
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: VaultColors.gold.withValues(alpha: 0.3),
                ),
                gradient: LinearGradient(
                  colors: [
                    VaultColors.panel.withValues(alpha: 0.9),
                    VaultColors.legendary.withValues(alpha: 0.1),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: VaultColors.gold.withValues(alpha: 0.16),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const PlateBadge(text: 'МЕР777178', countryCode: 'RU'),
            ),
            const SizedBox(height: 28),
            if (!state.cloudEnabled)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Локальный сейф',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: VaultColors.teal,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Firebase ещё не подключён — коллекция хранится на устройстве. Позже добавьте flutterfire configure.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: VaultColors.mist,
                            ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Имя коллекционера',
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _busy
                              ? null
                              : () => _run(
                                    () => state.signInLocal(_nameCtrl.text),
                                  ),
                          child: const Text('Открыть сейф'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (state.cloudEnabled) ...[
              TabBar(
                controller: _tabs,
                labelColor: VaultColors.gold,
                unselectedLabelColor: VaultColors.mist,
                indicatorColor: VaultColors.gold,
                tabs: const [
                  Tab(text: 'Вход'),
                  Tab(text: 'Регистрация'),
                ],
              ),
              SizedBox(
                height: 300,
                child: TabBarView(
                  controller: _tabs,
                  children: [
                    _emailForm(signUp: false, state: state),
                    _emailForm(signUp: true, state: state),
                  ],
                ),
              ),
              TextButton(
                onPressed: _busy
                    ? null
                    : () => _run(() => state.signInLocal(_nameCtrl.text)),
                child: const Text('Продолжить без облака'),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            if (_busy) ...[
              const SizedBox(height: 16),
              const Center(child: CircularProgressIndicator()),
            ],
          ],
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
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
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
              child: Text(signUp ? 'Создать аккаунт' : 'Войти'),
            ),
          ),
        ],
      ),
    );
  }
}
