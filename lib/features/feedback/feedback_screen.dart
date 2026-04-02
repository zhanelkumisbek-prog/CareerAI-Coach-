import 'package:careerai_coach/app/app.dart';
import 'package:careerai_coach/data/models/models.dart';
import 'package:careerai_coach/data/providers/providers.dart';
import 'package:careerai_coach/features/shared/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FeedbackScreen extends ConsumerStatefulWidget {
  const FeedbackScreen({super.key});

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _role = TextEditingController();
  final _useful = TextEditingController();
  final _confusing = TextEditingController();
  final _improve = TextEditingController();
  double _rating = 4;
  bool _again = true;

  @override
  void dispose() {
    _name.dispose();
    _role.dispose();
    _useful.dispose();
    _confusing.dispose();
    _improve.dispose();
    super.dispose();
  }

  Future<void> _save(AppUser? user) async {
    if (!_formKey.currentState!.validate()) return;
    await ref
        .read(feedbackRepositoryProvider)
        .saveFeedback(
          FeedbackEntry(
            userId: user?.id,
            name: _name.text.trim(),
            role: _role.text.trim(),
            rating: _rating.round(),
            usefulText: _useful.text.trim(),
            confusingText: _confusing.text.trim(),
            improveText: _improve.text.trim(),
            wouldUseAgain: _again,
            createdAt: DateTime.now(),
          ),
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Отзыв сохранен локально. Спасибо!')),
    );
    Navigator.pushReplacementNamed(context, CareerAiCoachApp.dashboardRoute);
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(sessionUserProvider);
    final profileAsync = ref.watch(profileProvider);

    return userAsync.when(
      data: (user) => profileAsync.when(
        data: (profile) {
          if (_name.text.isEmpty) {
            _name.text = profile?.fullName ?? '';
            _role.text = profile == null
                ? (user == null ? '' : roleLabel(user.role))
                : roleLabel(profile.role);
          }
          return CareerScaffold(
            title: 'Обратная связь',
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const HeroBanner(
                  title: 'Отзыв по ранней версии',
                  subtitle:
                      'Расскажите, что сработало хорошо, что было непонятно и готов ли MVP к реальному тестированию.',
                ),
                const SizedBox(height: 20),
                InfoCard(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: <Widget>[
                        _field(_name, 'Имя'),
                        const SizedBox(height: 14),
                        _field(_role, 'Роль'),
                        const SizedBox(height: 14),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Оценка: ${_rating.round()}/5'),
                        ),
                        Slider(
                          value: _rating,
                          min: 1,
                          max: 5,
                          divisions: 4,
                          label: _rating.round().toString(),
                          onChanged: (value) => setState(() => _rating = value),
                        ),
                        _field(_useful, 'Что было полезно?', lines: 3),
                        const SizedBox(height: 14),
                        _field(_confusing, 'Что было непонятно?', lines: 3),
                        const SizedBox(height: 14),
                        _field(_improve, 'Что стоит улучшить?', lines: 3),
                        const SizedBox(height: 14),
                        SwitchListTile(
                          value: _again,
                          onChanged: (value) => setState(() => _again = value),
                          title: const Text('Вы бы воспользовались этим снова?'),
                          contentPadding: EdgeInsets.zero,
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: () => _save(user),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Text('Отправить отзыв'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (error, _) => Scaffold(body: Center(child: Text('$error'))),
      ),
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(body: Center(child: Text('$error'))),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    int lines = 1,
  }) {
    return TextFormField(
      controller: controller,
      minLines: lines,
      maxLines: lines,
      decoration: InputDecoration(labelText: label),
      validator: (value) =>
          value == null || value.trim().isEmpty ? 'Обязательное поле' : null,
    );
  }
}
