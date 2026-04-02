import 'dart:convert';

enum UserRole { student, jobSeeker, employerHr, university }

enum UserPlan { free, premium, b2b }

enum TaskStatus { pending, completed }

enum TaskPriority { high, medium, low }

class AppUser {
  const AppUser({
    this.id,
    required this.email,
    required this.password,
    required this.role,
    required this.plan,
    required this.isLoggedIn,
    required this.createdAt,
  });

  final int? id;
  final String email;
  final String password;
  final UserRole role;
  final UserPlan plan;
  final bool isLoggedIn;
  final DateTime createdAt;

  Map<String, Object?> toMap() => <String, Object?>{
    'id': id,
    'email': email,
    'password': password,
    'role': role.name,
    'plan': plan.name,
    'is_logged_in': isLoggedIn ? 1 : 0,
    'created_at': createdAt.toIso8601String(),
  };

  factory AppUser.fromMap(Map<String, Object?> map) => AppUser(
    id: map['id'] as int?,
    email: map['email'] as String,
    password: map['password'] as String,
    role: UserRole.values.byName(map['role'] as String),
    plan: UserPlan.values.byName(
      (map['plan'] as String?) ?? UserPlan.free.name,
    ),
    isLoggedIn: (map['is_logged_in'] as int) == 1,
    createdAt: DateTime.parse(map['created_at'] as String),
  );

  AppUser copyWith({
    int? id,
    String? email,
    String? password,
    UserRole? role,
    UserPlan? plan,
    bool? isLoggedIn,
    DateTime? createdAt,
  }) => AppUser(
    id: id ?? this.id,
    email: email ?? this.email,
    password: password ?? this.password,
    role: role ?? this.role,
    plan: plan ?? this.plan,
    isLoggedIn: isLoggedIn ?? this.isLoggedIn,
    createdAt: createdAt ?? this.createdAt,
  );
}

class UserProfile {
  const UserProfile({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.role,
    required this.profession,
    required this.experienceLevel,
    required this.education,
    required this.skills,
    required this.careerGoal,
    required this.countryRegion,
    required this.preferredIndustry,
    required this.salaryGoal,
    required this.shortBio,
  });

  final int userId;
  final String fullName;
  final String email;
  final UserRole role;
  final String profession;
  final String experienceLevel;
  final String education;
  final String skills;
  final String careerGoal;
  final String countryRegion;
  final String preferredIndustry;
  final String salaryGoal;
  final String shortBio;

  Map<String, Object?> toMap() => <String, Object?>{
    'user_id': userId,
    'full_name': fullName,
    'email': email,
    'role': role.name,
    'profession': profession,
    'experience_level': experienceLevel,
    'education': education,
    'skills': skills,
    'career_goal': careerGoal,
    'country_region': countryRegion,
    'preferred_industry': preferredIndustry,
    'salary_goal': salaryGoal,
    'short_bio': shortBio,
  };

  factory UserProfile.fromMap(Map<String, Object?> map) => UserProfile(
    userId: map['user_id'] as int,
    fullName: map['full_name'] as String,
    email: map['email'] as String,
    role: UserRole.values.byName(map['role'] as String),
    profession: map['profession'] as String,
    experienceLevel: map['experience_level'] as String,
    education: map['education'] as String,
    skills: map['skills'] as String,
    careerGoal: map['career_goal'] as String,
    countryRegion: map['country_region'] as String,
    preferredIndustry: map['preferred_industry'] as String,
    salaryGoal: map['salary_goal'] as String,
    shortBio: map['short_bio'] as String,
  );
}

class ResumeMeta {
  const ResumeMeta({
    this.id,
    required this.userId,
    required this.path,
    required this.fileName,
    required this.fileType,
    required this.uploadedAt,
  });

  final int? id;
  final int userId;
  final String path;
  final String fileName;
  final String fileType;
  final DateTime uploadedAt;

  Map<String, Object?> toMap() => <String, Object?>{
    'id': id,
    'user_id': userId,
    'path': path,
    'file_name': fileName,
    'file_type': fileType,
    'uploaded_at': uploadedAt.toIso8601String(),
  };

  factory ResumeMeta.fromMap(Map<String, Object?> map) => ResumeMeta(
    id: map['id'] as int?,
    userId: map['user_id'] as int,
    path: map['path'] as String,
    fileName: map['file_name'] as String,
    fileType: map['file_type'] as String,
    uploadedAt: DateTime.parse(map['uploaded_at'] as String),
  );
}

class CareerAnalysisRecord {
  const CareerAnalysisRecord({
    this.id,
    required this.userId,
    required this.profession,
    required this.experience,
    required this.skillsInput,
    required this.targetRole,
    required this.industry,
    required this.salaryGoal,
    required this.country,
    required this.strongSkills,
    required this.missingSkills,
    required this.readinessScore,
    required this.recommendedNextStep,
    required this.summary,
    required this.createdAt,
  });

  final int? id;
  final int userId;
  final String profession;
  final String experience;
  final String skillsInput;
  final String targetRole;
  final String industry;
  final String salaryGoal;
  final String country;
  final List<String> strongSkills;
  final List<String> missingSkills;
  final int readinessScore;
  final String recommendedNextStep;
  final String summary;
  final DateTime createdAt;

  Map<String, Object?> toMap() => <String, Object?>{
    'id': id,
    'user_id': userId,
    'profession': profession,
    'experience': experience,
    'skills_input': skillsInput,
    'target_role': targetRole,
    'industry': industry,
    'salary_goal': salaryGoal,
    'country': country,
    'strong_skills': jsonEncode(strongSkills),
    'missing_skills': jsonEncode(missingSkills),
    'readiness_score': readinessScore,
    'recommended_next_step': recommendedNextStep,
    'summary': summary,
    'created_at': createdAt.toIso8601String(),
  };

  factory CareerAnalysisRecord.fromMap(Map<String, Object?> map) =>
      CareerAnalysisRecord(
        id: map['id'] as int?,
        userId: map['user_id'] as int,
        profession: map['profession'] as String,
        experience: map['experience'] as String,
        skillsInput: map['skills_input'] as String,
        targetRole: map['target_role'] as String,
        industry: map['industry'] as String,
        salaryGoal: map['salary_goal'] as String,
        country: map['country'] as String,
        strongSkills:
            (jsonDecode(map['strong_skills'] as String) as List<dynamic>)
                .cast<String>(),
        missingSkills:
            (jsonDecode(map['missing_skills'] as String) as List<dynamic>)
                .cast<String>(),
        readinessScore: map['readiness_score'] as int,
        recommendedNextStep: map['recommended_next_step'] as String,
        summary: map['summary'] as String,
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}

class RoadmapTask {
  const RoadmapTask({
    this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.priority,
    required this.deadline,
    required this.status,
    required this.isWeekly,
    this.weekStart,
    required this.source,
  });

  final int? id;
  final int userId;
  final String title;
  final String description;
  final TaskPriority priority;
  final DateTime deadline;
  final TaskStatus status;
  final bool isWeekly;
  final DateTime? weekStart;
  final String source;

  RoadmapTask copyWith({
    int? id,
    String? title,
    String? description,
    TaskPriority? priority,
    DateTime? deadline,
    TaskStatus? status,
    bool? isWeekly,
    DateTime? weekStart,
    String? source,
  }) {
    return RoadmapTask(
      id: id ?? this.id,
      userId: userId,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      deadline: deadline ?? this.deadline,
      status: status ?? this.status,
      isWeekly: isWeekly ?? this.isWeekly,
      weekStart: weekStart ?? this.weekStart,
      source: source ?? this.source,
    );
  }

  Map<String, Object?> toMap() => <String, Object?>{
    'id': id,
    'user_id': userId,
    'title': title,
    'description': description,
    'priority': priority.name,
    'deadline': deadline.toIso8601String(),
    'status': status.name,
    'is_weekly': isWeekly ? 1 : 0,
    'week_start': weekStart?.toIso8601String(),
    'source': source,
  };

  factory RoadmapTask.fromMap(Map<String, Object?> map) => RoadmapTask(
    id: map['id'] as int?,
    userId: map['user_id'] as int,
    title: map['title'] as String,
    description: map['description'] as String,
    priority: TaskPriority.values.byName(map['priority'] as String),
    deadline: DateTime.parse(map['deadline'] as String),
    status: TaskStatus.values.byName(map['status'] as String),
    isWeekly: (map['is_weekly'] as int) == 1,
    weekStart: map['week_start'] == null
        ? null
        : DateTime.parse(map['week_start'] as String),
    source: map['source'] as String,
  );
}

class FeedbackEntry {
  const FeedbackEntry({
    this.id,
    this.userId,
    required this.name,
    required this.role,
    required this.rating,
    required this.usefulText,
    required this.confusingText,
    required this.improveText,
    required this.wouldUseAgain,
    required this.createdAt,
  });

  final int? id;
  final int? userId;
  final String name;
  final String role;
  final int rating;
  final String usefulText;
  final String confusingText;
  final String improveText;
  final bool wouldUseAgain;
  final DateTime createdAt;

  Map<String, Object?> toMap() => <String, Object?>{
    'id': id,
    'user_id': userId,
    'name': name,
    'role': role,
    'rating': rating,
    'useful_text': usefulText,
    'confusing_text': confusingText,
    'improve_text': improveText,
    'would_use_again': wouldUseAgain ? 1 : 0,
    'created_at': createdAt.toIso8601String(),
  };
}

class RoleTemplate {
  const RoleTemplate({
    required this.id,
    required this.role,
    required this.title,
    required this.description,
    required this.skillFocus,
    required this.pathLabel,
  });

  final int id;
  final UserRole role;
  final String title;
  final String description;
  final String skillFocus;
  final String pathLabel;

  factory RoleTemplate.fromMap(Map<String, Object?> map) => RoleTemplate(
    id: map['id'] as int,
    role: UserRole.values.byName(map['role'] as String),
    title: map['title'] as String,
    description: map['description'] as String,
    skillFocus: map['skill_focus'] as String,
    pathLabel: map['path_label'] as String,
  );
}

class AnalysisInput {
  const AnalysisInput({
    required this.profession,
    required this.experience,
    required this.skills,
    required this.targetRole,
    required this.industry,
    required this.salaryGoal,
    required this.country,
  });

  final String profession;
  final String experience;
  final String skills;
  final String targetRole;
  final String industry;
  final String salaryGoal;
  final String country;
}
