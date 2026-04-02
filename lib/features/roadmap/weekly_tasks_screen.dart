import 'package:careerai_coach/app/app.dart';
import 'package:careerai_coach/data/models/models.dart';
import 'package:careerai_coach/data/providers/providers.dart';
import 'package:careerai_coach/features/shared/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WeeklyTasksScreen extends ConsumerWidget {
  const WeeklyTasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(sessionUserProvider);
    final weeklyAsync = ref.watch(weeklyTasksProvider);

    return userAsync.when(
      data: (user) {
        if (user == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return CareerScaffold(
          title: 'Задачи на неделю',
          body: weeklyAsync.when(
            data: (tasks) {
              final completed = tasks
                  .where((task) => task.status == TaskStatus.completed)
                  .length;
              final progress = tasks.isEmpty ? 0.0 : completed / tasks.length;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const HeroBanner(
                    title: 'Темп этой недели',
                    subtitle:
                        'Поддерживайте карьерный рост с помощью сфокусированного плана на неделю. Отмечайте прогресс и создавайте план на следующую неделю при необходимости.',
                  ),
                  const SizedBox(height: 20),
                  InfoCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Прогресс за неделю',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 14),
                        LinearProgressIndicator(
                          value: progress,
                          minHeight: 12,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        const SizedBox(height: 10),
                        Text('Выполнено: ${(progress * 100).round()}%'),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: <Widget>[
                            FilledButton(
                              onPressed: () async {
                                await ref
                                    .read(roadmapRepositoryProvider)
                                    .generateNextWeekPlan(user.id!);
                                refreshSessionData(ref);
                              },
                              child: const Text('Сгенерировать план на следующую неделю'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (tasks.isEmpty)
                    const EmptyStateCard(
                      title: 'Пока нет недельных задач',
                      subtitle:
                          'Создайте план развития или план на следующую неделю, чтобы начать отслеживание.',
                    )
                  else ...<Widget>[
                    Text(
                      'Текущие задачи',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    ...tasks
                        .where((task) => task.status == TaskStatus.pending)
                        .map((task) => _taskTile(ref, task)),
                    const SizedBox(height: 20),
                    Text(
                      'Выполненные задачи',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    ...tasks
                        .where((task) => task.status == TaskStatus.completed)
                        .map((task) => _taskTile(ref, task)),
                  ],
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Text('$error'),
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(body: Center(child: Text('$error'))),
    );
  }

  Widget _taskTile(WidgetRef ref, RoadmapTask task) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InfoCard(
        child: CheckboxListTile(
          value: task.status == TaskStatus.completed,
          onChanged: (_) async {
            await ref.read(roadmapRepositoryProvider).toggleStatus(task);
            refreshSessionData(ref);
          },
          title: Text(task.title),
          subtitle: Text(task.description),
          secondary: Chip(label: Text(taskPriorityLabel(task.priority))),
        ),
      ),
    );
  }
}
