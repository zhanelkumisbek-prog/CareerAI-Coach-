import 'package:careerai_coach/app/app.dart';
import 'package:careerai_coach/data/models/models.dart';
import 'package:careerai_coach/data/providers/providers.dart';
import 'package:careerai_coach/features/shared/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  static const List<String> _experienceOptions = <String>[
    'Начальный',
    'Средний',
    'Продвинутый',
  ];

  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _email = TextEditingController();
  final _profession = TextEditingController();
  final _education = TextEditingController();
  final _skills = TextEditingController();
  final _careerGoal = TextEditingController();
  final _country = TextEditingController();
  final _industry = TextEditingController();
  final _salary = TextEditingController();
  final _bio = TextEditingController();
  String _experience = 'Начальный';
  bool _initialized = false;

  @override
  void dispose() {
    _fullName.dispose();
    _email.dispose();
    _profession.dispose();
    _education.dispose();
    _skills.dispose();
    _careerGoal.dispose();
    _country.dispose();
    _industry.dispose();
    _salary.dispose();
    _bio.dispose();
    super.dispose();
  }

  void _prefill(AppUser user, UserProfile? profile) {
    if (_initialized) return;
    _initialized = true;
    _email.text = profile?.email ?? user.email;
    _fullName.text = profile?.fullName ?? '';
    _profession.text = profile?.profession ?? '';
    _education.text = profile?.education ?? '';
    _skills.text = profile?.skills ?? '';
    _careerGoal.text = profile?.careerGoal ?? '';
    _country.text = profile?.countryRegion ?? '';
    _industry.text = profile?.preferredIndustry ?? '';
    _salary.text = profile?.salaryGoal ?? '';
    _bio.text = profile?.shortBio ?? '';
    _experience = _normalizeExperience(profile?.experienceLevel);
  }

  Future<void> _save(AppUser user) async {
    if (!_formKey.currentState!.validate()) return;
    final profile = UserProfile(
      userId: user.id!,
      fullName: _fullName.text.trim(),
      email: _email.text.trim(),
      role: user.role,
      profession: _profession.text.trim(),
      experienceLevel: _experience,
      education: _education.text.trim(),
      skills: _skills.text.trim(),
      careerGoal: _careerGoal.text.trim(),
      countryRegion: _country.text.trim(),
      preferredIndustry: _industry.text.trim(),
      salaryGoal: _salary.text.trim(),
      shortBio: _bio.text.trim(),
    );
    await ref.read(profileRepositoryProvider).saveProfile(profile);
    refreshSessionData(ref);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Профиль успешно сохранен.')),
    );
    Navigator.pushReplacementNamed(context, CareerAiCoachApp.dashboardRoute);
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
            _prefill(user, profile);
            return CareerScaffold(
              title: 'Профиль',
              currentRoute: CareerAiCoachApp.profileRoute,
              body: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    HeroBanner(
                      title: 'Создайте карьерный профиль',
                      subtitle:
                          'Расскажите о себе, чтобы приложение смогло построить более точный анализ навыков и план развития.',
                      trailing: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          roleLabel(user.role),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: <Widget>[
                        _field(_fullName, 'Полное имя'),
                        _field(_email, 'Email'),
                        _field(_profession, 'Текущая или желаемая профессия'),
                        _dropdown(),
                        _field(_education, 'Образование'),
                        _field(_skills, 'Навыки (через запятую)'),
                        _field(_careerGoal, 'Карьерная цель'),
                        _field(_country, 'Страна / регион'),
                        _field(_industry, 'Предпочтительная индустрия'),
                        _field(_salary, 'Желаемая зарплата'),
                        _field(_bio, 'Кратко о себе', lines: 4, full: true),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => _save(user),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            profile == null ? 'Сохранить профиль' : 'Обновить профиль',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
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

  Widget _field(
    TextEditingController controller,
    String label, {
    int lines = 1,
    bool full = false,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final targetWidth = full ? 880.0 : 420.0;
        return SizedBox(
          width: maxWidth < targetWidth ? maxWidth : targetWidth,
          child: TextFormField(
            controller: controller,
            minLines: lines,
            maxLines: lines,
            decoration: InputDecoration(labelText: label),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Обязательное поле';
              }
              return null;
            },
          ),
        );
      },
    );
  }

  Widget _dropdown() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth < 420 ? constraints.maxWidth : 420.0;
        return SizedBox(
          width: width,
          child: DropdownButtonFormField<String>(
            initialValue: _experience,
            decoration: const InputDecoration(labelText: 'Уровень опыта'),
            items: _experienceOptions
                .map(
                  (value) => DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  ),
                )
                .toList(),
            onChanged: (value) =>
                setState(() => _experience = value ?? 'Начальный'),
          ),
        );
      },
    );
  }

  String _normalizeExperience(String? value) {
    switch (value?.trim().toLowerCase()) {
      case 'beginner':
      case 'начальный':
        return 'Начальный';
      case 'intermediate':
      case 'средний':
        return 'Средний';
      case 'advanced':
      case 'продвинутый':
        return 'Продвинутый';
      default:
        return 'Начальный';
    }
  }
}
