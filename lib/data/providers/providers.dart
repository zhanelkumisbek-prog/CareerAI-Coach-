import 'package:careerai_coach/core/database/app_database.dart';
import 'package:careerai_coach/core/services/file_service.dart';
import 'package:careerai_coach/core/services/firebase_support.dart';
import 'package:careerai_coach/core/services/notification_service.dart';
import 'package:careerai_coach/data/models/models.dart';
import 'package:careerai_coach/data/repositories/repositories.dart';
import 'package:careerai_coach/firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase.instance;
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService.instance;
});

final fileServiceProvider = Provider<FileService>((ref) {
  return FileService();
});

final firebaseEnabledProvider = Provider<bool>((ref) {
  return supportsConfiguredFirebasePlatform;
});

final firebaseAuthProvider = Provider<FirebaseAuth?>((ref) {
  if (!ref.watch(firebaseEnabledProvider)) return null;
  return FirebaseAuth.instance;
});

final firestoreProvider = Provider<FirebaseFirestore?>((ref) {
  if (!ref.watch(firebaseEnabledProvider)) return null;
  return FirebaseFirestore.instance;
});

final googleSignInProvider = Provider<GoogleSignIn?>((ref) {
  if (!ref.watch(firebaseEnabledProvider)) return null;
  return GoogleSignIn(
    serverClientId: DefaultFirebaseOptions.androidServerClientId,
  );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(firebaseAuthProvider),
    ref.watch(firestoreProvider),
    ref.watch(googleSignInProvider),
    ref.watch(firebaseEnabledProvider),
  );
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(notificationServiceProvider),
  );
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(appDatabaseProvider));
});

final resumeRepositoryProvider = Provider<ResumeRepository>((ref) {
  return ResumeRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(fileServiceProvider),
  );
});

final analysisRepositoryProvider = Provider<AnalysisRepository>((ref) {
  return AnalysisRepository(ref.watch(appDatabaseProvider));
});

final roadmapRepositoryProvider = Provider<RoadmapRepository>((ref) {
  return RoadmapRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(notificationServiceProvider),
  );
});

final feedbackRepositoryProvider = Provider<FeedbackRepository>((ref) {
  return FeedbackRepository(ref.watch(appDatabaseProvider));
});

final templateRepositoryProvider = Provider<TemplateRepository>((ref) {
  return TemplateRepository(ref.watch(appDatabaseProvider));
});

final sessionUserProvider = FutureProvider<AppUser?>((ref) async {
  return ref.watch(authRepositoryProvider).currentUser();
});

final selectedRoleProvider = FutureProvider<UserRole?>((ref) async {
  return ref.watch(settingsRepositoryProvider).selectedRole();
});

final profileProvider = FutureProvider<UserProfile?>((ref) async {
  final user = await ref.watch(sessionUserProvider.future);
  if (user == null || user.id == null) return null;
  return ref.watch(profileRepositoryProvider).getProfile(user.id!);
});

final resumeProvider = FutureProvider<ResumeMeta?>((ref) async {
  final user = await ref.watch(sessionUserProvider.future);
  if (user == null || user.id == null) return null;
  return ref.watch(resumeRepositoryProvider).getResume(user.id!);
});

final latestAnalysisProvider = FutureProvider<CareerAnalysisRecord?>((
  ref,
) async {
  final user = await ref.watch(sessionUserProvider.future);
  if (user == null || user.id == null) return null;
  return ref.watch(analysisRepositoryProvider).latestAnalysis(user.id!);
});

final roadmapTasksProvider = FutureProvider<List<RoadmapTask>>((ref) async {
  final user = await ref.watch(sessionUserProvider.future);
  if (user == null || user.id == null) return <RoadmapTask>[];
  return ref.watch(roadmapRepositoryProvider).tasks(user.id!);
});

final weeklyTasksProvider = FutureProvider<List<RoadmapTask>>((ref) async {
  final user = await ref.watch(sessionUserProvider.future);
  if (user == null || user.id == null) return <RoadmapTask>[];
  return ref.watch(roadmapRepositoryProvider).weeklyTasks(user.id!);
});

final notificationEnabledProvider = FutureProvider<bool>((ref) async {
  return ref.watch(settingsRepositoryProvider).notificationsEnabled();
});

final templatesProvider = FutureProvider<List<RoleTemplate>>((ref) async {
  final user = await ref.watch(sessionUserProvider.future);
  if (user == null) return <RoleTemplate>[];
  return ref.watch(templateRepositoryProvider).templatesForRole(user.role);
});

void refreshSessionData(WidgetRef ref) {
  ref.invalidate(sessionUserProvider);
  ref.invalidate(profileProvider);
  ref.invalidate(resumeProvider);
  ref.invalidate(latestAnalysisProvider);
  ref.invalidate(roadmapTasksProvider);
  ref.invalidate(weeklyTasksProvider);
  ref.invalidate(notificationEnabledProvider);
  ref.invalidate(templatesProvider);
}
