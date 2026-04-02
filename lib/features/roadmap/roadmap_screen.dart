import 'package:careerai_coach/app/app.dart';
import 'package:careerai_coach/data/models/models.dart';
import 'package:careerai_coach/data/providers/providers.dart';
import 'package:careerai_coach/features/shared/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RoadmapScreen extends ConsumerWidget {
  const RoadmapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(sessionUserProvider);
    final tasksAsync = ref.watch(roadmapTasksProvider);
    final analysisAsync = ref.watch(latestAnalysisProvider);

    return userAsync.when(
      data: (user) {
        if (user == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return CareerScaffold(
          title: 'План развития',
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const HeroBanner(
                title: 'Ваш персональный план',
                subtitle:
                    'Управляйте сгенерированными задачами, добавляйте свои этапы и держите фокус на ближайшем реальном результате.',
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: <Widget>[
                  FilledButton.icon(
                    onPressed: () => _openTaskDialog(context, ref, user.id!),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Добавить задачу'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final analysis = await ref.read(
                        latestAnalysisProvider.future,
                      );
                      if (analysis == null) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Сначала выполните анализ, а потом пересоздавайте план.',
                            ),
                          ),
                        );
                        return;
                      }
                      await ref
                          .read(roadmapRepositoryProvider)
                          .generateRoadmap(
                            userId: user.id!,
                            analysis: analysis,
                            plan: user.plan,
                          );
                      refreshSessionData(ref);
                    },
                    icon: const Icon(Icons.autorenew_rounded),
                    label: const Text('Пересоздать план'),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              analysisAsync.when(
                data: (analysis) => analysis == null
                    ? const SizedBox.shrink()
                    : InfoCard(
                        child: Text(
                          'Текущий фокус: ${analysis.recommendedNextStep}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                loading: () => const SizedBox.shrink(),
                error: (error, _) => Text('$error'),
              ),
              const SizedBox(height: 18),
              tasksAsync.when(
                data: (tasks) => tasks.isEmpty
                    ? const EmptyStateCard(
                        title: 'План пока не создан',
                        subtitle:
                            'Выполните анализ карьеры и создайте первый план, чтобы увидеть здесь задачи.',
                      )
                    : Column(
                        children: tasks
                            .map(
                              (task) => InfoCard(
                                padding: const EdgeInsets.all(18),
                                child: ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: Checkbox(
                                    value: task.status == TaskStatus.completed,
                                    onChanged: (_) async {
                                      await ref
                                          .read(roadmapRepositoryProvider)
                                          .toggleStatus(task);
                                      refreshSessionData(ref);
                                    },
                                  ),
                                  title: Text(task.title),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      const SizedBox(height: 6),
                                      Text(task.description),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 8,
                                        children: <Widget>[
                                          Chip(
                                            label: Text(taskPriorityLabel(task.priority)),
                                            backgroundColor: priorityColor(
                                              task.priority,
                                            ).withValues(alpha: 0.12),
                                          ),
                                          Chip(
                                            label: Text(
                                              formatDate(task.deadline),
                                            ),
                                          ),
                                          Chip(label: Text(task.source)),
                                        ],
                                      ),
                                    ],
                                  ),
                                  trailing: PopupMenuButton<String>(
                                    onSelected: (value) async {
                                      if (value == 'edit') {
                                        _openTaskDialog(
                                          context,
                                          ref,
                                          user.id!,
                                          task: task,
                                        );
                                      }
                                      if (value == 'delete' &&
                                          task.id != null) {
                                        await ref
                                            .read(roadmapRepositoryProvider)
                                            .deleteTask(task.id!);
                                        refreshSessionData(ref);
                                      }
                                    },
                                    itemBuilder: (context) =>
                                        const <PopupMenuEntry<String>>[
                                          PopupMenuItem(
                                            value: 'edit',
                                            child: Text('Изменить'),
                                          ),
                                          PopupMenuItem(
                                            value: 'delete',
                                            child: Text('Удалить'),
                                          ),
                                        ],
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
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

  Future<void> _openTaskDialog(
    BuildContext context,
    WidgetRef ref,
    int userId, {
    RoadmapTask? task,
  }) async {
    final title = TextEditingController(text: task?.title ?? '');
    final description = TextEditingController(text: task?.description ?? '');
    TaskPriority priority = task?.priority ?? TaskPriority.medium;
    DateTime deadline =
        task?.deadline ?? DateTime.now().add(const Duration(days: 7));

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Text(task == null ? 'Добавить задачу' : 'Изменить задачу'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextField(
                    controller: title,
                    decoration: const InputDecoration(labelText: 'Название'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: description,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Описание'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<TaskPriority>(
                    initialValue: priority,
                    items: TaskPriority.values
                        .map(
                          (value) => DropdownMenuItem<TaskPriority>(
                            value: value,
                            child: Text(taskPriorityLabel(value)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setState(() => priority = value ?? TaskPriority.medium),
                    decoration: const InputDecoration(labelText: 'Приоритет'),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Срок: ${formatDate(deadline)}'),
                    trailing: const Icon(Icons.calendar_today_rounded),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: deadline,
                        firstDate: DateTime.now().subtract(
                          const Duration(days: 1),
                        ),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setState(() => deadline = picked);
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Отмена'),
              ),
              FilledButton(
                onPressed: () async {
                  await ref
                      .read(roadmapRepositoryProvider)
                      .saveTask(
                        RoadmapTask(
                          id: task?.id,
                          userId: userId,
                          title: title.text.trim(),
                          description: description.text.trim(),
                          priority: priority,
                          deadline: deadline,
                          status: task?.status ?? TaskStatus.pending,
                          isWeekly: task?.isWeekly ?? false,
                          weekStart: task?.weekStart,
                          source: task?.source ?? 'manual',
                        ),
                      );
                  refreshSessionData(ref);
                  if (!context.mounted) return;
                  Navigator.pop(context);
                },
                child: const Text('Сохранить'),
              ),
            ],
          ),
        );
      },
    );
  }
}
