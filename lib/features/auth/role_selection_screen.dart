import 'package:careerai_coach/app/app.dart';
import 'package:careerai_coach/data/models/models.dart';
import 'package:careerai_coach/data/providers/providers.dart';
import 'package:careerai_coach/features/shared/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RoleSelectionScreen extends ConsumerStatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  ConsumerState<RoleSelectionScreen> createState() =>
      _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends ConsumerState<RoleSelectionScreen> {
  UserRole? _selected;

  @override
  Widget build(BuildContext context) {
    final roles = <UserRole>[
      UserRole.student,
      UserRole.jobSeeker,
      UserRole.employerHr,
      UserRole.university,
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final crossAxisCount = width < 640 ? 1 : 2;
            final childAspectRatio = width < 640 ? 1.22 : 1.05;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const HeroBanner(
                        title: 'Кто вы?',
                        subtitle:
                            'Выберите роль, которая лучше всего соответствует вашему карьерному пути. Мы подстроим под нее onboarding и главный экран.',
                        trailing: CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.person_search_rounded,
                            color: Color(0xFF0A7B83),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: GridView.builder(
                          itemCount: roles.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 16,
                                childAspectRatio: childAspectRatio,
                              ),
                          itemBuilder: (context, index) {
                            final role = roles[index];
                            final selected = _selected == role;
                            return InkWell(
                              borderRadius: BorderRadius.circular(28),
                              onTap: () => setState(() => _selected = role),
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? const Color(0xFF24163F)
                                      : const Color(0xFF17172B),
                                  borderRadius: BorderRadius.circular(28),
                                  border: Border.all(
                                    color: selected
                                        ? Theme.of(context).colorScheme.primary
                                        : const Color(0xFF303050),
                                    width: selected ? 1.6 : 1,
                                  ),
                                  boxShadow: selected
                                      ? const <BoxShadow>[
                                          BoxShadow(
                                            color: Color(0x339B30FF),
                                            blurRadius: 26,
                                            offset: Offset(0, 12),
                                          ),
                                        ]
                                      : const <BoxShadow>[],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(0x229B30FF),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Icon(
                                        _iconForRole(role),
                                        size: 28,
                                        color:
                                            Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 18),
                                    Text(
                                      roleLabel(role),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(height: 1.15),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _roleDescription(role),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _selected == null
                              ? null
                              : () async {
                                  final navigator = Navigator.of(context);
                                  await ref
                                      .read(settingsRepositoryProvider)
                                      .saveSelectedRole(_selected!);
                                  if (!mounted) return;
                                  navigator.pushReplacementNamed(
                                    CareerAiCoachApp.authRoute,
                                  );
                                },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Text('Продолжить'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  IconData _iconForRole(UserRole role) {
    switch (role) {
      case UserRole.student:
        return Icons.school_rounded;
      case UserRole.jobSeeker:
        return Icons.work_outline_rounded;
      case UserRole.employerHr:
        return Icons.groups_2_rounded;
      case UserRole.university:
        return Icons.apartment_rounded;
    }
  }

  String _roleDescription(UserRole role) {
    switch (role) {
      case UserRole.student:
        return 'Поймите, чему учиться дальше, и подготовьтесь к стажировкам.';
      case UserRole.jobSeeker:
        return 'Превратите текущие навыки в четкий план действий для желаемой работы.';
      case UserRole.employerHr:
        return 'Просматривайте шаблоны навыков и определяйте потребности команды в развитии.';
      case UserRole.university:
        return 'Помогайте студентам повышать готовность к работе с понятной аналитикой по пробелам в навыках.';
    }
  }
}
