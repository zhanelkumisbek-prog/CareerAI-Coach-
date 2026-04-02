import 'package:careerai_coach/app/app.dart';
import 'package:careerai_coach/data/providers/providers.dart';
import 'package:careerai_coach/features/shared/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(sessionUserProvider);
    final notificationsAsync = ref.watch(notificationEnabledProvider);

    return userAsync.when(
      data: (user) {
        if (user == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return CareerScaffold(
          title: 'Настройки',
          currentRoute: CareerAiCoachApp.settingsRoute,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const HeroBanner(
                title: 'Настройки и аккаунт',
                subtitle:
                    'Управляйте уведомлениями, состоянием аккаунта и локальным режимом работы приложения.',
              ),
              const SizedBox(height: 20),
              InfoCard(
                child: Column(
                  children: <Widget>[
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.person_outline_rounded),
                      title: const Text('Редактировать профиль'),
                      onTap: () => Navigator.pushReplacementNamed(
                        context,
                        CareerAiCoachApp.profileRoute,
                      ),
                    ),
                    notificationsAsync.when(
                      data: (enabled) => SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: enabled,
                        onChanged: (value) async {
                          await ref
                              .read(settingsRepositoryProvider)
                              .setNotificationsEnabled(value);
                          refreshSessionData(ref);
                        },
                        title: const Text('Уведомления'),
                        subtitle: const Text(
                          'Еженедельные напоминания и подсказки по незавершенным задачам',
                        ),
                      ),
                      loading: () => const ListTile(
                        title: Text('Загрузка уведомлений...'),
                      ),
                      error: (error, _) => Text('$error'),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.workspace_premium_rounded),
                      title: const Text('Посмотреть тарифы'),
                      subtitle: Text(
                        'Текущий тариф: ${planLabel(user.plan)}',
                      ),
                      onTap: () => Navigator.pushReplacementNamed(
                        context,
                        CareerAiCoachApp.pricingRoute,
                      ),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.logout_rounded),
                      title: const Text('Выйти'),
                      onTap: () async {
                        await ref.read(authRepositoryProvider).logout();
                        refreshSessionData(ref);
                        if (!context.mounted) return;
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          CareerAiCoachApp.authRoute,
                          (route) => false,
                        );
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.delete_forever_rounded,
                        color: Colors.red,
                      ),
                      title: const Text('Удалить аккаунт'),
                      onTap: () async {
                        await ref
                            .read(authRepositoryProvider)
                            .deleteAccount(user.id!);
                        refreshSessionData(ref);
                        if (!context.mounted) return;
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          CareerAiCoachApp.roleRoute,
                          (route) => false,
                        );
                      },
                    ),
                    const ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.info_outline_rounded),
                      title: Text('О приложении'),
                      subtitle: Text(
                        'CareerAI Coach v1.0.0\nОфлайн-прототип, созданный на Flutter, SQLite и локальных уведомлениях.',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(body: Center(child: Text('$error'))),
    );
  }
}
