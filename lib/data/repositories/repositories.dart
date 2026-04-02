import 'dart:async';

import 'package:careerai_coach/core/database/app_database.dart';
import 'package:careerai_coach/core/services/file_service.dart';
import 'package:careerai_coach/core/services/notification_service.dart';
import 'package:careerai_coach/core/utils/analysis_engine.dart';
import 'package:careerai_coach/data/models/models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sqflite/sqflite.dart';

class AuthRepository {
  AuthRepository(
    this._database,
    this._auth,
    this._firestore,
    this._googleSignIn,
    this._firebaseEnabled,
  );

  final AppDatabase _database;
  final FirebaseAuth? _auth;
  final FirebaseFirestore? _firestore;
  final GoogleSignIn? _googleSignIn;
  final bool _firebaseEnabled;

  Future<AppUser?> currentUser() async {
    if (!_firebaseEnabled || _auth == null) {
      final db = await _database.database;
      final rows = await db.query(
        'users',
        where: 'is_logged_in = ?',
        whereArgs: [1],
        limit: 1,
      );
      if (rows.isEmpty) return null;
      return AppUser.fromMap(rows.first);
    }

    final auth = _auth;
    final firebaseUser = auth.currentUser;
    if (firebaseUser == null || firebaseUser.email == null) {
      return null;
    }

    final db = await _database.database;
    final localUser = await _findLocalUserByEmail(firebaseUser.email!, db);
    if (localUser != null) {
      await _markUserLoggedIn(localUser.id!, db);
      final loggedInUser = localUser.copyWith(isLoggedIn: true);
      unawaited(_syncFirebaseUserDocument(loggedInUser, firebaseUser));
      return loggedInUser;
    }

    final role = await _selectedRoleFromSettings(db) ?? UserRole.jobSeeker;
    final newUser = await _createLocalUser(
      email: firebaseUser.email!,
      role: role,
      db: db,
      password: 'firebase_auth',
    );
    unawaited(_syncFirebaseUserDocument(newUser, firebaseUser));
    return newUser;
  }

  Future<AppUser> signUp({
    required String email,
    required String password,
    required UserRole role,
  }) async {
    final db = await _database.database;
    final normalizedEmail = email.trim().toLowerCase();
    if (!_firebaseEnabled || _auth == null) {
      final existing = await _findLocalUserByEmail(normalizedEmail, db);
      if (existing != null) {
        await db.update(
          'users',
          {
            'password': password,
            'role': role.name,
            'plan': role == UserRole.employerHr || role == UserRole.university
                ? UserPlan.b2b.name
                : UserPlan.free.name,
            'created_at': existing.createdAt.toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [existing.id],
        );
        await db.insert('settings', {
          'key': 'selected_role',
          'value': role.name,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
        await _markUserLoggedIn(existing.id!, db);
        return existing.copyWith(
          password: password,
          role: role,
          plan: role == UserRole.employerHr || role == UserRole.university
              ? UserPlan.b2b
              : UserPlan.free,
          isLoggedIn: true,
        );
      }

      final newUser = await _createLocalUser(
        email: normalizedEmail,
        role: role,
        db: db,
        password: password,
      );
      return newUser;
    }

    debugPrint(
      '[AuthRepository.signUp] start projectId=${Firebase.app().options.projectId} email=$normalizedEmail role=${role.name}',
    );

    UserCredential credential;
    try {
      final auth = _auth;
      credential = await auth.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );
    } on FirebaseAuthException catch (error) {
      debugPrint(
        '[AuthRepository.signUp] FirebaseAuthException code=${error.code} message=${error.message}',
      );
      throw Exception(_mapAuthError(error));
    }

    final firebaseUser = credential.user;
    debugPrint(
      '[AuthRepository.signUp] credential.user?.uid=${firebaseUser?.uid}',
    );
    if (firebaseUser == null || firebaseUser.email == null) {
      debugPrint(
        '[AuthRepository.signUp] Firebase returned null user after sign-up',
      );
      throw Exception(
        'Firebase registration failed: no authenticated user returned.',
      );
    }

    final existing = await _findLocalUserByEmail(normalizedEmail, db);
    if (existing != null) {
      await _markUserLoggedIn(existing.id!, db);
      final loggedInUser = existing.copyWith(isLoggedIn: true);
      unawaited(_syncFirebaseUserDocument(loggedInUser, firebaseUser));
      return loggedInUser;
    }

    final newUser = await _createLocalUser(
      email: normalizedEmail,
      role: role,
      db: db,
      password: 'firebase_auth',
    );
    unawaited(_syncFirebaseUserDocument(newUser, firebaseUser));
    return newUser;
  }

  Future<AppUser> login({
    required String email,
    required String password,
  }) async {
    final db = await _database.database;
    final normalizedEmail = email.trim().toLowerCase();
    if (!_firebaseEnabled || _auth == null) {
      final existing = await _findLocalUserByEmail(normalizedEmail, db);
      if (existing == null || existing.password != password) {
        throw Exception('Неверный email или пароль.');
      }

      await _markUserLoggedIn(existing.id!, db);
      return existing.copyWith(isLoggedIn: true);
    }

    try {
      final auth = _auth;
      await auth.signInWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );
    } on FirebaseAuthException catch (error) {
      throw Exception(_mapAuthError(error));
    }

    final existing = await _findLocalUserByEmail(normalizedEmail, db);
    final firebaseUser = _auth.currentUser;
    if (existing != null) {
      await _markUserLoggedIn(existing.id!, db);
      final loggedInUser = existing.copyWith(isLoggedIn: true);
      unawaited(_syncFirebaseUserDocument(loggedInUser, firebaseUser));
      return loggedInUser;
    }

    final role = await _selectedRoleFromSettings(db) ?? UserRole.jobSeeker;
    final newUser = await _createLocalUser(
      email: normalizedEmail,
      role: role,
      db: db,
      password: 'firebase_auth',
    );
    unawaited(_syncFirebaseUserDocument(newUser, firebaseUser));
    return newUser;
  }

  Future<AppUser> signInWithGoogle({required UserRole role}) async {
    if (!_firebaseEnabled || _auth == null || _googleSignIn == null) {
      throw Exception('Google вход доступен только на Android в этой сборке.');
    }

    final db = await _database.database;
    try {
      final googleSignIn = _googleSignIn;
      final auth = _auth;

      await googleSignIn.signOut();
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Вход через Google отменен.');
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await auth.signInWithCredential(credential);
      final firebaseUser = userCredential.user;
      final email = firebaseUser?.email?.trim().toLowerCase();
      if (email == null || email.isEmpty) {
        throw Exception('Не удалось получить email Google-аккаунта.');
      }

      final results = await _findLocalUserByEmail(email, db);

      await db.update('users', {'is_logged_in': 0});

      if (results != null) {
        await _markUserLoggedIn(results.id!, db);
        final loggedInUser = results.copyWith(isLoggedIn: true);
        unawaited(_syncFirebaseUserDocument(loggedInUser, firebaseUser));
        return loggedInUser;
      }

      final newUser = await _createLocalUser(
        email: email,
        role: role,
        db: db,
        password: 'google_oauth_local',
      );
      unawaited(_syncFirebaseUserDocument(newUser, firebaseUser));
      return newUser;
    } on FirebaseAuthException catch (error) {
      throw Exception(_mapAuthError(error));
    } on PlatformException catch (error) {
      throw Exception(_mapGoogleSignInError(error));
    } catch (error) {
      if (error is Exception) rethrow;
      throw Exception('Ошибка входа через Google.');
    }
  }

  Future<void> resetPassword({required String email}) async {
    if (!_firebaseEnabled || _auth == null) {
      throw Exception(
        'Сброс пароля недоступен в локальном режиме. Войдите по сохраненному паролю.',
      );
    }

    try {
      final auth = _auth;
      await auth.sendPasswordResetEmail(email: email.trim().toLowerCase());
    } on FirebaseAuthException catch (error) {
      throw Exception(_mapAuthError(error));
    }
  }

  Future<void> logout() async {
    final db = await _database.database;
    await db.update('users', {'is_logged_in': 0});
    await _googleSignIn?.signOut();
    await _auth?.signOut();
  }

  Future<void> updatePlan(int userId, UserPlan plan) async {
    final db = await _database.database;
    await db.update(
      'users',
      {'plan': plan.name},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<void> deleteAccount(int userId) async {
    final db = await _database.database;
    await db.delete('profiles', where: 'user_id = ?', whereArgs: [userId]);
    await db.delete('resumes', where: 'user_id = ?', whereArgs: [userId]);
    await db.delete('analyses', where: 'user_id = ?', whereArgs: [userId]);
    await db.delete('roadmap_tasks', where: 'user_id = ?', whereArgs: [userId]);
    await db.delete(
      'feedback_entries',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    await db.delete('users', where: 'id = ?', whereArgs: [userId]);
    final firebaseUser = _auth?.currentUser;
    if (firebaseUser != null) {
      await firebaseUser.delete();
    }
  }

  Future<AppUser?> _findLocalUserByEmail(String email, Database db) async {
    final rows = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email.trim().toLowerCase()],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return AppUser.fromMap(rows.first);
  }

  Future<void> _markUserLoggedIn(int userId, Database db) async {
    await db.update('users', {'is_logged_in': 0});
    await db.update(
      'users',
      {'is_logged_in': 1},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<UserRole?> _selectedRoleFromSettings(Database db) async {
    final rows = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: ['selected_role'],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return UserRole.values.byName(rows.first['value'] as String);
  }

  Future<AppUser> _createLocalUser({
    required String email,
    required UserRole role,
    required Database db,
    required String password,
  }) async {
    final user = AppUser(
      email: email.trim().toLowerCase(),
      password: password,
      role: role,
      plan: role == UserRole.employerHr || role == UserRole.university
          ? UserPlan.b2b
          : UserPlan.free,
      isLoggedIn: true,
      createdAt: DateTime.now(),
    );
    final id = await db.insert('users', user.toMap()..remove('id'));
    await db.insert('settings', {
      'key': 'selected_role',
      'value': role.name,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    await _markUserLoggedIn(id, db);
    return user.copyWith(id: id, isLoggedIn: true);
  }

  String _mapAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'account-exists-with-different-credential':
        return 'Бұл email басқа кіру тәсілімен тіркелген.';
      case 'network-request-failed':
        return 'Интернетке қосылу қатесі. Қайта көріңіз.';
      case 'operation-not-allowed':
        return 'Firebase ішінде Google Sign-In әлі қосылмаған.';
      case 'email-already-in-use':
        return 'Аккаунт с таким email уже существует.';
      case 'invalid-email':
        return 'Введите корректный email.';
      case 'weak-password':
        return 'Пароль слишком слабый.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Неверный email или пароль.';
      case 'too-many-requests':
        return 'Слишком много попыток. Попробуйте позже.';
      default:
        return error.message ?? 'Ошибка авторизации.';
    }
  }

  String _mapGoogleSignInError(PlatformException error) {
    final message = error.message ?? '';
    if (message.contains('10') ||
        message.toLowerCase().contains('developer error')) {
      return 'Google Sign-In конфигурациясы толық емес. Firebase-ке SHA-1 және SHA-256 қосу керек.';
    }
    switch (error.code) {
      case 'network_error':
        return 'Интернетке қосылу қатесі. Қайта көріңіз.';
      case 'sign_in_canceled':
        return 'Google арқылы кіру тоқтатылды.';
      case 'sign_in_failed':
        return 'Google арқылы кіру сәтсіз аяқталды. Firebase конфигін тексеріңіз.';
      default:
        return message.isNotEmpty ? message : 'Google арқылы кіру қатесі.';
    }
  }

  Future<void> _syncFirebaseUserDocument(
    AppUser localUser,
    User? firebaseUser,
  ) async {
    if (!_firebaseEnabled || _firestore == null || firebaseUser == null) return;
    try {
      final firestore = _firestore;
      await firestore.collection('users').doc(firebaseUser.uid).set({
        'uid': firebaseUser.uid,
        'email': firebaseUser.email ?? localUser.email,
        'role': localUser.role.name,
        'plan': localUser.plan.name,
        'localUserId': localUser.id,
        'providerIds': firebaseUser.providerData
            .map((provider) => provider.providerId)
            .toList(),
        'displayName': firebaseUser.displayName,
        'photoUrl': firebaseUser.photoURL,
        'lastLoginAt': FieldValue.serverTimestamp(),
        'createdAt': firebaseUser.metadata.creationTime?.toIso8601String(),
      }, SetOptions(merge: true));
    } on FirebaseException catch (error) {
      debugPrint(
        '[AuthRepository._syncFirebaseUserDocument] skipped: '
        'code=${error.code} message=${error.message}',
      );
    } catch (error) {
      debugPrint(
        '[AuthRepository._syncFirebaseUserDocument] skipped unexpected error: '
        '$error',
      );
    }
  }
}

class SettingsRepository {
  SettingsRepository(this._database, this._notifications);

  final AppDatabase _database;
  final NotificationService _notifications;

  Future<void> saveSelectedRole(UserRole role) async {
    final db = await _database.database;
    await db.insert('settings', {
      'key': 'selected_role',
      'value': role.name,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<UserRole?> selectedRole() async {
    final db = await _database.database;
    final rows = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: ['selected_role'],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return UserRole.values.byName(rows.first['value'] as String);
  }

  Future<bool> notificationsEnabled() async {
    final db = await _database.database;
    final rows = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: ['notifications_enabled'],
      limit: 1,
    );
    if (rows.isEmpty) return true;
    return rows.first['value'] == '1';
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    final db = await _database.database;
    await db.insert('settings', {
      'key': 'notifications_enabled',
      'value': enabled ? '1' : '0',
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    if (enabled) {
      await _notifications.scheduleWeeklyReminder();
      await _notifications.scheduleIncompleteTaskReminder();
    } else {
      await _notifications.cancelAllRecurring();
    }
  }
}

class ProfileRepository {
  ProfileRepository(this._database);

  final AppDatabase _database;

  Future<UserProfile?> getProfile(int userId) async {
    final db = await _database.database;
    final rows = await db.query(
      'profiles',
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return UserProfile.fromMap(rows.first);
  }

  Future<void> saveProfile(UserProfile profile) async {
    final db = await _database.database;
    await db.insert(
      'profiles',
      profile.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}

class ResumeRepository {
  ResumeRepository(this._database, this._fileService);

  final AppDatabase _database;
  final FileService _fileService;

  Future<ResumeMeta?> getResume(int userId) async {
    final db = await _database.database;
    final rows = await db.query(
      'resumes',
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return ResumeMeta.fromMap(rows.first);
  }

  Future<ResumeMeta?> pickAndSaveResume(int userId) async {
    final previous = await getResume(userId);
    final picked = await _fileService.pickAndCopyResume(userId);
    if (picked == null) return null;

    if (previous != null) {
      await _fileService.deleteStoredFile(previous.path);
    }

    final db = await _database.database;
    final meta = ResumeMeta(
      userId: userId,
      path: picked.path,
      fileName: picked.fileName,
      fileType: picked.fileType,
      uploadedAt: DateTime.now(),
    );
    await db.insert(
      'resumes',
      meta.toMap()..remove('id'),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return meta;
  }

  Future<void> deleteResume(int userId) async {
    final db = await _database.database;
    final existing = await getResume(userId);
    if (existing != null) {
      await _fileService.deleteStoredFile(existing.path);
    }
    await db.delete('resumes', where: 'user_id = ?', whereArgs: [userId]);
  }
}

class AnalysisRepository {
  AnalysisRepository(this._database);

  final AppDatabase _database;

  Future<CareerAnalysisRecord?> latestAnalysis(int userId) async {
    final db = await _database.database;
    final rows = await db.query(
      'analyses',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return CareerAnalysisRecord.fromMap(rows.first);
  }

  Future<CareerAnalysisRecord> generate(int userId, AnalysisInput input) async {
    return AnalysisEngine.generate(userId: userId, input: input);
  }

  Future<CareerAnalysisRecord> save(CareerAnalysisRecord analysis) async {
    final db = await _database.database;
    final id = await db.insert('analyses', analysis.toMap()..remove('id'));
    return CareerAnalysisRecord(
      id: id,
      userId: analysis.userId,
      profession: analysis.profession,
      experience: analysis.experience,
      skillsInput: analysis.skillsInput,
      targetRole: analysis.targetRole,
      industry: analysis.industry,
      salaryGoal: analysis.salaryGoal,
      country: analysis.country,
      strongSkills: analysis.strongSkills,
      missingSkills: analysis.missingSkills,
      readinessScore: analysis.readinessScore,
      recommendedNextStep: analysis.recommendedNextStep,
      summary: analysis.summary,
      createdAt: analysis.createdAt,
    );
  }
}

class RoadmapRepository {
  RoadmapRepository(this._database, this._notifications);

  final AppDatabase _database;
  final NotificationService _notifications;

  Future<List<RoadmapTask>> tasks(int userId) async {
    final db = await _database.database;
    final rows = await db.query(
      'roadmap_tasks',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'deadline ASC',
    );
    return rows.map(RoadmapTask.fromMap).toList();
  }

  Future<List<RoadmapTask>> weeklyTasks(int userId) async {
    final db = await _database.database;
    final weekStart = _startOfWeek(DateTime.now()).toIso8601String();
    final rows = await db.query(
      'roadmap_tasks',
      where: 'user_id = ? AND is_weekly = ? AND week_start = ?',
      whereArgs: [userId, 1, weekStart],
      orderBy: 'deadline ASC',
    );
    return rows.map(RoadmapTask.fromMap).toList();
  }

  Future<void> saveTask(RoadmapTask task) async {
    final db = await _database.database;
    await db.insert(
      'roadmap_tasks',
      task.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteTask(int id) async {
    final db = await _database.database;
    await db.delete('roadmap_tasks', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> toggleStatus(RoadmapTask task) async {
    final db = await _database.database;
    final next = task.status == TaskStatus.completed
        ? TaskStatus.pending
        : TaskStatus.completed;
    await db.update(
      'roadmap_tasks',
      {'status': next.name},
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<void> generateRoadmap({
    required int userId,
    required CareerAnalysisRecord analysis,
    required UserPlan plan,
  }) async {
    final db = await _database.database;
    await db.delete('roadmap_tasks', where: 'user_id = ?', whereArgs: [userId]);

    final missing = analysis.missingSkills;
    final backlog = <RoadmapTask>[
      RoadmapTask(
        userId: userId,
        title: 'Усилить ${missing.isNotEmpty ? missing.first : 'портфолио'}',
        description:
            'Пройдите один сфокусированный учебный спринт и превратите его в видимый результат.',
        priority: TaskPriority.high,
        deadline: DateTime.now().add(const Duration(days: 7)),
        status: TaskStatus.pending,
        isWeekly: true,
        weekStart: _startOfWeek(DateTime.now()),
        source: 'сгенерировано',
      ),
      RoadmapTask(
        userId: userId,
        title: 'Обновить резюме для роли ${analysis.targetRole}',
        description:
            'Перепишите summary, добавьте измеримый результат и подстройте ключевые слова под целевую роль.',
        priority: TaskPriority.high,
        deadline: DateTime.now().add(const Duration(days: 10)),
        status: TaskStatus.pending,
        isWeekly: false,
        source: 'сгенерировано',
      ),
      RoadmapTask(
        userId: userId,
        title: 'Сделать один показательный проект',
        description:
            'Создайте проект, который покажет ${analysis.strongSkills.take(2).join(' и ')}.',
        priority: TaskPriority.medium,
        deadline: DateTime.now().add(const Duration(days: 14)),
        status: TaskStatus.pending,
        isWeekly: true,
        weekStart: _startOfWeek(DateTime.now()),
        source: 'сгенерировано',
      ),
      RoadmapTask(
        userId: userId,
        title: 'Откликнуться на 5 подходящих вакансий',
        description:
            'Используйте новый план, чтобы выбрать роли в сфере ${analysis.industry}.',
        priority: TaskPriority.medium,
        deadline: DateTime.now().add(const Duration(days: 21)),
        status: TaskStatus.pending,
        isWeekly: false,
        source: 'сгенерировано',
      ),
      if (plan != UserPlan.free)
        RoadmapTask(
          userId: userId,
          title: 'Премиум-симуляция карьерного коучинга',
          description:
              'Проведите более глубокую симуляцию собеседования и расширенный разбор пробелов для более быстрого роста.',
          priority: TaskPriority.low,
          deadline: DateTime.now().add(const Duration(days: 28)),
          status: TaskStatus.pending,
          isWeekly: false,
          source: 'премиум',
        ),
    ];

    for (final task in backlog) {
      await db.insert('roadmap_tasks', task.toMap()..remove('id'));
    }

    await _notifications.showRoadmapUpdated();
  }

  Future<void> generateNextWeekPlan(int userId) async {
    final tasksList = await tasks(userId);
    final nextWeek = _startOfWeek(DateTime.now().add(const Duration(days: 7)));
    final template = tasksList
        .where((task) => task.status == TaskStatus.pending)
        .take(3)
        .toList();

    final db = await _database.database;
    for (final task in template) {
      await db.insert(
        'roadmap_tasks',
        task
            .copyWith(
              id: null,
              deadline: nextWeek.add(
                Duration(days: template.indexOf(task) + 2),
              ),
              weekStart: nextWeek,
              isWeekly: true,
              source: 'weekly_plan',
            )
            .toMap()
          ..remove('id'),
      );
    }
  }

  DateTime _startOfWeek(DateTime date) {
    final diff = date.weekday - DateTime.monday;
    final normalized = DateTime(date.year, date.month, date.day);
    return normalized.subtract(Duration(days: diff));
  }
}

class FeedbackRepository {
  FeedbackRepository(this._database);

  final AppDatabase _database;

  Future<void> saveFeedback(FeedbackEntry entry) async {
    final db = await _database.database;
    await db.insert('feedback_entries', entry.toMap()..remove('id'));
  }
}

class TemplateRepository {
  TemplateRepository(this._database);

  final AppDatabase _database;

  Future<List<RoleTemplate>> templatesForRole(UserRole role) async {
    final db = await _database.database;
    final rows = await db.query(
      'role_templates',
      where: 'role = ?',
      whereArgs: [role.name],
      orderBy: 'id ASC',
    );
    return rows.map(RoleTemplate.fromMap).toList();
  }
}
