import 'package:careerai_coach/app/app.dart';
import 'package:careerai_coach/data/models/models.dart';
import 'package:careerai_coach/data/providers/providers.dart';
import 'package:careerai_coach/features/shared/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CareerAnalysisScreen extends ConsumerStatefulWidget {
  const CareerAnalysisScreen({super.key});

  @override
  ConsumerState<CareerAnalysisScreen> createState() =>
      _CareerAnalysisScreenState();
}

class _CareerAnalysisScreenState extends ConsumerState<CareerAnalysisScreen> {
  final _formKey = GlobalKey<FormState>();
  final _profession = TextEditingController();
  final _experience = TextEditingController();
  final _skills = TextEditingController();
  final _targetRole = TextEditingController();
  final _industry = TextEditingController();
  final _salaryGoal = TextEditingController();
  final _country = TextEditingController();
  CareerAnalysisRecord? _generated;
  bool _initialized = false;

  @override
  void dispose() {
    _profession.dispose();
    _experience.dispose();
    _skills.dispose();
    _targetRole.dispose();
    _industry.dispose();
    _salaryGoal.dispose();
    _country.dispose();
    super.dispose();
  }

  void _prefill(UserProfile? profile) {
    if (_initialized || profile == null) return;
    _initialized = true;
    _profession.text = profile.profession;
    _experience.text = profile.experienceLevel;
    _skills.text = profile.skills;
    _targetRole.text = profile.profession;
    _industry.text = profile.preferredIndustry;
    _salaryGoal.text = profile.salaryGoal;
    _country.text = profile.countryRegion;
  }

  Future<void> _run(int userId) async {
    if (!_formKey.currentState!.validate()) return;
    final record = await ref
        .read(analysisRepositoryProvider)
        .generate(
          userId,
          AnalysisInput(
            profession: _profession.text.trim(),
            experience: _experience.text.trim(),
            skills: _skills.text.trim(),
            targetRole: _targetRole.text.trim(),
            industry: _industry.text.trim(),
            salaryGoal: _salaryGoal.text.trim(),
            country: _country.text.trim(),
          ),
        );
    setState(() => _generated = record);
  }

  Future<void> _save() async {
    final record = _generated;
    if (record == null) return;
    await ref.read(analysisRepositoryProvider).save(record);
    refreshSessionData(ref);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Анализ сохранен локально.')));
  }

  Future<void> _generateRoadmap(AppUser user) async {
    final record = _generated ?? await ref.read(latestAnalysisProvider.future);
    if (!mounted) return;
    if (record == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Сначала запустите или загрузите анализ.')),
      );
      return;
    }
    final saved = record.id == null
        ? await ref.read(analysisRepositoryProvider).save(record)
        : record;
    await ref
        .read(roadmapRepositoryProvider)
        .generateRoadmap(userId: user.id!, analysis: saved, plan: user.plan);
    refreshSessionData(ref);
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, CareerAiCoachApp.roadmapRoute);
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(sessionUserProvider);
    final profileAsync = ref.watch(profileProvider);

    return userAsync.when(
      data: (user) {
        if (user == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return profileAsync.when(
          data: (profile) {
            _prefill(profile);
            return CareerScaffold(
              title: 'Анализ карьеры',
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const HeroBanner(
                    title: 'Локальный анализ в стиле AI',
                    subtitle:
                        'Этот офлайн-движок превращает ваш профиль в реалистичную оценку карьерной готовности, сводку по пробелам в навыках и рекомендацию по следующему шагу.',
                  ),
                  const SizedBox(height: 20),
                  InfoCard(
                    child: Form(
                      key: _formKey,
                      child: Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: <Widget>[
                          _field(_profession, 'Профессия'),
                          _field(_experience, 'Опыт'),
                          _field(_skills, 'Навыки (через запятую)'),
                          _field(_targetRole, 'Желаемая роль'),
                          _field(_industry, 'Индустрия'),
                          _field(_salaryGoal, 'Желаемая зарплата'),
                          _field(_country, 'Страна'),
                          SizedBox(
                            width: double.infinity,
                            child: Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: <Widget>[
                                FilledButton(
                                  onPressed: () => _run(user.id!),
                                  child: const Text('Запустить анализ'),
                                ),
                                OutlinedButton(
                                  onPressed: _generated == null ? null : _save,
                                  child: const Text('Сохранить анализ'),
                                ),
                                OutlinedButton(
                                  onPressed: () => _generateRoadmap(user),
                                  child: const Text('Создать план'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_generated != null)
                    InfoCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Результат анализа',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 14),
                          LinearProgressIndicator(
                            value: _generated!.readinessScore / 100,
                            minHeight: 12,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Индекс карьерной готовности: ${_generated!.readinessScore}%',
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Сильные навыки: ${_generated!.strongSkills.join(', ')}',
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Недостающие навыки: ${_generated!.missingSkills.join(', ')}',
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Рекомендуемый следующий шаг: ${_generated!.recommendedNextStep}',
                          ),
                          const SizedBox(height: 8),
                          Text(_generated!.summary),
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
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(body: Center(child: Text('$error'))),
    );
  }

  Widget _field(TextEditingController controller, String label) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth < 420 ? constraints.maxWidth : 420.0;
        return SizedBox(
          width: width,
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(labelText: label),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Обязательное поле'
                : null,
          ),
        );
      },
    );
  }
}
