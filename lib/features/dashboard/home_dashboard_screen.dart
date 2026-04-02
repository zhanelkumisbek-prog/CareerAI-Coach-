import 'package:careerai_coach/app/app.dart';
import 'package:careerai_coach/data/models/models.dart';
import 'package:careerai_coach/data/providers/providers.dart';
import 'package:careerai_coach/features/shared/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeDashboardScreen extends ConsumerWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(sessionUserProvider);
    final profileAsync = ref.watch(profileProvider);
    final analysisAsync = ref.watch(latestAnalysisProvider);
    final resumeAsync = ref.watch(resumeProvider);
    final tasksAsync = ref.watch(roadmapTasksProvider);
    final templatesAsync = ref.watch(templatesProvider);

    return userAsync.when(
      data: (user) {
        if (user == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return CareerScaffold(
          title: 'Главная',
          currentRoute: CareerAiCoachApp.dashboardRoute,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              HeroBanner(
                title: 'С возвращением',
                subtitle: user.plan == UserPlan.free
                    ? 'Активен бесплатный тариф. Запустите анализ, загрузите резюме и получите персональный план.'
                    : user.plan == UserPlan.premium
                    ? 'Активен премиум-тариф. Вам доступны более глубокие рекомендации и больше задач.'
                    : 'Активно B2B-пространство для развития сотрудников и планирования карьерной готовности.',
                trailing: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    planLabel(user.plan),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              profileAsync.when(
                data: (profile) {
                  if (user.role == UserRole.employerHr ||
                      user.role == UserRole.university) {
                    return templatesAsync.when(
                      data: (templates) =>
                          _institutionView(context, user, templates),
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (error, _) => Text('$error'),
                    );
                  }
                  return Column(
                    children: <Widget>[
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: <Widget>[
                          MetricTile(
                            label: 'Текущая цель',
                            value: profile?.careerGoal ?? 'Заполнить профиль',
                            icon: Icons.flag_rounded,
                          ),
                          analysisAsync.when(
                            data: (analysis) => MetricTile(
                              label: 'Готовность к карьере',
                              value: '${analysis?.readinessScore ?? 0}%',
                              icon: Icons.trending_up_rounded,
                            ),
                            loading: () => const MetricTile(
                              label: 'Готовность к карьере',
                              value: '...',
                              icon: Icons.trending_up_rounded,
                            ),
                            error: (error, _) => MetricTile(
                              label: 'Готовность к карьере',
                              value: 'Ошибка',
                              icon: Icons.error_outline_rounded,
                            ),
                          ),
                          resumeAsync.when(
                            data: (resume) => MetricTile(
                              label: 'Резюме',
                              value: resume == null
                                  ? 'Не загружено'
                                  : 'Загружено',
                              icon: Icons.description_rounded,
                            ),
                            loading: () => const MetricTile(
                              label: 'Резюме',
                              value: '...',
                              icon: Icons.description_rounded,
                            ),
                            error: (error, _) => MetricTile(
                              label: 'Резюме',
                              value: 'Ошибка',
                              icon: Icons.error_outline_rounded,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _quickActions(context),
                      const SizedBox(height: 20),
                      analysisAsync.when(
                        data: (analysis) => analysis == null
                            ? const EmptyStateCard(
                                title: 'Запустите первый анализ',
                                subtitle:
                                    'После анализа профиля и генерации плана этот экран станет намного полезнее.',
                              )
                            : InfoCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      'Сводка по пробелам в навыках',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleLarge,
                                    ),
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: analysis.missingSkills
                                          .map(
                                            (skill) => Chip(label: Text(skill)),
                                          )
                                          .toList(),
                                    ),
                                    const SizedBox(height: 14),
                                    Text(analysis.summary),
                                  ],
                                ),
                              ),
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (error, _) => Text('$error'),
                      ),
                      const SizedBox(height: 20),
                      tasksAsync.when(
                        data: (tasks) => InfoCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'Активные задачи плана',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 14),
                              if (tasks.isEmpty)
                                const Text(
                                  'Пока нет задач. Сначала выполните анализ и создайте план.',
                                )
                              else
                                ...tasks
                                    .take(4)
                                    .map(
                                      (task) => ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        title: Text(task.title),
                                        subtitle: Text(task.description),
                                        trailing: Text(taskStatusLabel(task.status)),
                                      ),
                                    ),
                            ],
                          ),
                        ),
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (error, _) => Text('$error'),
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Text('$error'),
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

  Widget _quickActions(BuildContext context) {
    final actions = <Map<String, Object>>[
      {
        'label': 'Профиль',
        'icon': Icons.edit_rounded,
        'route': CareerAiCoachApp.profileRoute,
      },
      {
        'label': 'Загрузить резюме',
        'icon': Icons.upload_file_rounded,
        'route': CareerAiCoachApp.resumeRoute,
      },
      {
        'label': 'Запустить анализ',
        'icon': Icons.analytics_rounded,
        'route': CareerAiCoachApp.analysisRoute,
      },
      {
        'label': 'Открыть план',
        'icon': Icons.route_rounded,
        'route': CareerAiCoachApp.roadmapRoute,
      },
      {
        'label': 'Задачи недели',
        'icon': Icons.calendar_month_rounded,
        'route': CareerAiCoachApp.weeklyRoute,
      },
      {
        'label': 'Отзыв',
        'icon': Icons.reviews_rounded,
        'route': CareerAiCoachApp.feedbackRoute,
      },
    ];
    final screenWidth = MediaQuery.sizeOf(context).width;
    final itemWidth = screenWidth < 420 ? (screenWidth - 46) / 2 : 170.0;

    return Wrap(
      spacing: 14,
      runSpacing: 14,
      children: actions
          .map(
            (action) => SizedBox(
              width: itemWidth,
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () => Navigator.pushReplacementNamed(
                  context,
                  action['route']! as String,
                ),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: <Color>[Color(0xFF18182D), Color(0xFF121224)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFF313152)),
                    boxShadow: const <BoxShadow>[
                      BoxShadow(
                        color: Color(0x229B30FF),
                        blurRadius: 22,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: <Color>[
                                Color(0x339B30FF),
                                Color(0x22D946EF),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0x449B30FF)),
                          ),
                          child: Icon(
                            action['icon']! as IconData,
                            color: const Color(0xFFD946EF),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          action['label']! as String,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(height: 1.2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _institutionView(
    BuildContext context,
    AppUser user,
    List<RoleTemplate> templates,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: <Widget>[
            MetricTile(
              label: 'Аудитория',
              value: roleLabel(user.role),
              icon: Icons.groups_rounded,
            ),
            MetricTile(
              label: 'Шаблоны',
              value: '${templates.length}',
              icon: Icons.article_rounded,
            ),
            const MetricTile(
              label: 'Рекомендованное развитие',
              value: 'Активно',
              icon: Icons.school_rounded,
            ),
          ],
        ),
        const SizedBox(height: 20),
        InfoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Шаблоны требований к ролям',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              ...templates.map(
                (template) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.work_history_rounded),
                  title: Text(template.title),
                  subtitle: Text(
                    '${template.description}\nФокус навыков: ${template.skillFocus}',
                  ),
                  trailing: Text(template.pathLabel),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
