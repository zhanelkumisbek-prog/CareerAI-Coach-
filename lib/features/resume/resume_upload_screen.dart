import 'package:careerai_coach/data/providers/providers.dart';
import 'package:careerai_coach/features/shared/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ResumeUploadScreen extends ConsumerWidget {
  const ResumeUploadScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(sessionUserProvider);
    final resumeAsync = ref.watch(resumeProvider);

    return userAsync.when(
      data: (user) {
        if (user == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return CareerScaffold(
          title: 'Резюме',
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const HeroBanner(
                title: 'Загрузите резюме или CV',
                subtitle:
                    'Выберите PDF, DOC, DOCX, изображение или текстовый файл. Приложение сохранит локальную копию и привяжет метаданные к вашему аккаунту.',
              ),
              const SizedBox(height: 20),
              resumeAsync.when(
                data: (resume) => SizedBox(
                  width: double.infinity,
                  child: InfoCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Загруженный файл',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF6FAFD),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFFD9E6F2),
                            ),
                          ),
                          child: resume == null
                              ? const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Icon(
                                      Icons.description_outlined,
                                      size: 28,
                                      color: Color(0xFF6D7A8C),
                                    ),
                                    SizedBox(height: 12),
                                    Text(
                                      'Файл еще не загружен.',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(height: 6),
                                    Text(
                                      'Добавьте резюме, чтобы использовать анализ и персональный план развития.',
                                    ),
                                  ],
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Row(
                                      children: <Widget>[
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFE0F4F7),
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.insert_drive_file_rounded,
                                            color: Color(0xFF0A7B83),
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: <Widget>[
                                              Text(
                                                resume.fileName,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Тип: ${resume.fileType}',
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                    Text('Путь: ${resume.path}'),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Загружен: ${formatDate(resume.uploadedAt)}',
                                    ),
                                  ],
                                ),
                        ),
                        const SizedBox(height: 18),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: <Widget>[
                            FilledButton.icon(
                              onPressed: () async {
                                final saved = await ref
                                    .read(resumeRepositoryProvider)
                                    .pickAndSaveResume(user.id!);
                                refreshSessionData(ref);
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      saved == null
                                          ? 'Выбор файла отменен.'
                                          : 'Резюме сохранено локально.',
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.upload_file_rounded),
                              label: Text(
                                resume == null
                                    ? 'Выбрать файл'
                                    : 'Заменить файл',
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: resume == null
                                  ? null
                                  : () async {
                                      await ref
                                          .read(resumeRepositoryProvider)
                                          .deleteResume(user.id!);
                                      refreshSessionData(ref);
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Ссылка на резюме удалена.',
                                          ),
                                        ),
                                      );
                                    },
                              icon: const Icon(Icons.delete_outline_rounded),
                              label: const Text('Удалить файл'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
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
}
