import 'package:careerai_coach/app/app.dart';
import 'package:careerai_coach/data/models/models.dart';
import 'package:careerai_coach/data/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  static const UserRole _fallbackRole = UserRole.jobSeeker;

  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _isLogin = false;
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final isSignUpFlow = !_isLogin;
    try {
      final auth = ref.read(authRepositoryProvider);
      AppUser user;
      if (_isLogin) {
        user = await auth.login(email: _email.text, password: _password.text);
      } else {
        final role = await ref.read(selectedRoleProvider.future) ?? _fallbackRole;
        await ref.read(settingsRepositoryProvider).saveSelectedRole(role);
        user = await auth.signUp(
          email: _email.text,
          password: _password.text,
          role: role,
        );
        try {
          await ref
              .read(notificationServiceProvider)
              .showWelcomeReminder(user.email);
        } catch (error) {
          debugPrint('[AuthScreen._submit] welcome reminder skipped: $error');
        }
      }

      await _completeAuth(
        user,
        successMessage: _isLogin
            ? 'Вход выполнен успешно.'
            : 'Аккаунт успешно создан.',
      );
    } catch (error) {
      debugPrint(
        '[AuthScreen._submit] ${isSignUpFlow ? 'sign-up' : 'login'} failed: $error',
      );
      if (!mounted) return;
      final message = error.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final email = TextEditingController(text: _email.text);
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Восстановление пароля'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: email,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () async {
                try {
                  await ref
                      .read(authRepositoryProvider)
                      .resetPassword(email: email.text);
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Письмо для сброса пароля отправлено на email.',
                      ),
                    ),
                  );
                } catch (error) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        error.toString().replaceFirst('Exception: ', ''),
                      ),
                    ),
                  );
                }
              },
              child: const Text('Сбросить'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _loading = true);
    try {
      final existingUser = await ref.read(sessionUserProvider.future);
      final role =
          existingUser?.role ??
          await ref.read(selectedRoleProvider.future) ??
          _fallbackRole;
      await ref.read(settingsRepositoryProvider).saveSelectedRole(role);

      final user = await ref
          .read(authRepositoryProvider)
          .signInWithGoogle(role: role);
      _email.text = user.email;
      await _completeAuth(
        user,
        successMessage: 'Вход через Google выполнен успешно.',
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _completeAuth(
    AppUser user, {
    required String successMessage,
  }) async {
    refreshSessionData(ref);
    final profile = await ref
        .read(profileRepositoryProvider)
        .getProfile(user.id!);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(successMessage)));
    Navigator.pushReplacementNamed(
      context,
      profile == null
          ? CareerAiCoachApp.profileRoute
          : CareerAiCoachApp.dashboardRoute,
    );
  }

  @override
  Widget build(BuildContext context) {
    final promoPanel = Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFF151428), Color(0xFF24153F), Color(0xFF100F1D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: const Color(0xFF303050)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x449B30FF),
            blurRadius: 30,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          CircleAvatar(
            radius: 34,
            backgroundColor: Color(0x229B30FF),
            child: Icon(
              Icons.psychology_alt_rounded,
              size: 34,
              color: Color(0xFFD946EF),
            ),
          ),
          SizedBox(height: 18),
          Text(
            'Постройте более ясный карьерный путь.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'CareerAI Coach помогает находить пробелы в навыках, планировать следующие шаги, улучшать резюме и двигаться вперед каждую неделю.',
            style: TextStyle(color: Color(0xFFA7A0C8), fontSize: 16),
          ),
        ],
      ),
    );

    final formCard = Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                _isLogin ? 'Войти' : 'Создайте аккаунт',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 10),
              Text(
                _isLogin
                    ? 'Продолжите путь развития с того места, где остановились.'
                    : 'Зарегистрируйтесь по email и паролю, чтобы начать свой карьерный план.',
              ),
              const SizedBox(height: 22),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFFF5F1FF),
                  letterSpacing: 0.2,
                ),
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'you@example.com',
                ),
                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty ||
                      !value.contains('@')) {
                    return 'Введите корректный email.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _password,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Пароль'),
                validator: (value) {
                  if (value == null || value.length < 6) {
                    return 'Минимум 6 символов.';
                  }
                  return null;
                },
              ),
              if (!_isLogin) ...<Widget>[
                const SizedBox(height: 14),
                TextFormField(
                  controller: _confirm,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Подтвердите пароль',
                  ),
                  validator: (value) {
                    if (value != _password.text) {
                      return 'Пароли не совпадают.';
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _loading ? null : _submit,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: _loading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.2),
                          )
                        : Text(_isLogin ? 'Войти' : 'Зарегистрироваться'),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Divider(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'или',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  Expanded(
                    child: Divider(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _loading ? null : _signInWithGoogle,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Container(
                        width: 26,
                        height: 26,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(13),
                          color: const Color(0xFFF1F5F9),
                        ),
                        child: const Text(
                          'G',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF102033),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text('Войти через Google'),
                    ],
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _forgotPassword,
                  child: const Text('Забыли пароль?'),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(_isLogin ? 'Впервые здесь?' : 'Уже есть аккаунт?'),
                  TextButton(
                    onPressed: () => setState(() => _isLogin = !_isLogin),
                    child: Text(_isLogin ? 'Регистрация' : 'Войти'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.pushReplacementNamed(context, CareerAiCoachApp.roleRoute);
          },
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Назад',
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            Positioned(
              top: -70,
              left: -30,
              child: Container(
                width: 220,
                height: 220,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: <Color>[Color(0x449B30FF), Color(0x009B30FF)],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -100,
              right: -30,
              child: Container(
                width: 260,
                height: 260,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: <Color>[Color(0x33D946EF), Color(0x00D946EF)],
                  ),
                ),
              ),
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 700;
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1020),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: isCompact
                          ? formCard
                          : Row(
                              children: <Widget>[
                                Expanded(child: promoPanel),
                                const SizedBox(width: 20),
                                Expanded(child: formCard),
                              ],
                            ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
