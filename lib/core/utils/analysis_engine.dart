import 'package:careerai_coach/data/models/models.dart';

class AnalysisEngine {
  static const Map<String, List<String>> _roleSkillMap = <String, List<String>>{
    'frontend developer': <String>[
      'html',
      'css',
      'javascript',
      'react',
      'git',
      'api integration',
      'testing',
    ],
    'backend developer': <String>[
      'dart',
      'apis',
      'sql',
      'system design',
      'testing',
      'git',
      'cloud basics',
    ],
    'product manager': <String>[
      'roadmapping',
      'stakeholder management',
      'analytics',
      'research',
      'prioritization',
      'communication',
    ],
    'data analyst': <String>[
      'sql',
      'excel',
      'statistics',
      'dashboards',
      'python',
      'data storytelling',
    ],
    'ui/ux designer': <String>[
      'figma',
      'user research',
      'wireframing',
      'design systems',
      'prototyping',
      'communication',
    ],
  };

  static CareerAnalysisRecord generate({
    required int userId,
    required AnalysisInput input,
  }) {
    final normalizedSkills = input.skills
        .split(',')
        .map((skill) => skill.trim().toLowerCase())
        .where((skill) => skill.isNotEmpty)
        .toSet()
        .toList();

    final target = input.targetRole.trim().toLowerCase();
    final requiredSkills =
        _roleSkillMap[target] ??
        <String>[
          'communication',
          'problem solving',
          'industry knowledge',
          'portfolio',
          'project ownership',
        ];

    final strong = requiredSkills
        .where((skill) => normalizedSkills.contains(skill))
        .toList();
    final missing = requiredSkills
        .where((skill) => !normalizedSkills.contains(skill))
        .toList();

    final skillMatch = requiredSkills.isEmpty
        ? 0
        : ((strong.length / requiredSkills.length) * 70).round();

    final experienceBonus = switch (input.experience.toLowerCase()) {
      'beginner' || 'начальный' => 10,
      'intermediate' || 'средний' => 18,
      'advanced' || 'продвинутый' => 25,
      _ => 14,
    };

    final breadthBonus = normalizedSkills.length >= 8
        ? 10
        : normalizedSkills.length;
    final score = (skillMatch + experienceBonus + breadthBonus).clamp(20, 96);
    final nextStep = missing.isNotEmpty
        ? 'Сфокусируйтесь на ${missing.take(2).join(' и ')} через один проект и один короткий курс.'
        : 'Вы уже близки к готовности к роли. Усильте портфолио и начните регулярно откликаться.';

    final summary =
        'У вас хорошее соответствие роли ${input.targetRole} в сфере ${input.industry}. '
        'Ваши сильные стороны: ${strong.isEmpty ? 'коммуникация и мотивация' : strong.join(', ')}. '
        'Чтобы быстрее повысить готовность, закройте пробелы в ${missing.isEmpty ? 'качестве портфолио и подготовке к собеседованиям' : missing.join(', ')}.';

    return CareerAnalysisRecord(
      id: null,
      userId: userId,
      profession: input.profession,
      experience: input.experience,
      skillsInput: input.skills,
      targetRole: input.targetRole,
      industry: input.industry,
      salaryGoal: input.salaryGoal,
      country: input.country,
      strongSkills: strong,
      missingSkills: missing,
      readinessScore: score,
      recommendedNextStep: nextStep,
      summary: summary,
      createdAt: DateTime.now(),
    );
  }
}
