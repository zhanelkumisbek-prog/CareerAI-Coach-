import 'package:careerai_coach/data/models/models.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _open();
    return _database!;
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      p.join(dbPath, 'career_ai_coach.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            email TEXT UNIQUE NOT NULL,
            password TEXT NOT NULL,
            role TEXT NOT NULL,
            plan TEXT NOT NULL DEFAULT 'free',
            is_logged_in INTEGER NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE profiles(
            user_id INTEGER PRIMARY KEY,
            full_name TEXT NOT NULL,
            email TEXT NOT NULL,
            role TEXT NOT NULL,
            profession TEXT NOT NULL,
            experience_level TEXT NOT NULL,
            education TEXT NOT NULL,
            skills TEXT NOT NULL,
            career_goal TEXT NOT NULL,
            country_region TEXT NOT NULL,
            preferred_industry TEXT NOT NULL,
            salary_goal TEXT NOT NULL,
            short_bio TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE resumes(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL UNIQUE,
            path TEXT NOT NULL,
            file_name TEXT NOT NULL,
            file_type TEXT NOT NULL,
            uploaded_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE analyses(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            profession TEXT NOT NULL,
            experience TEXT NOT NULL,
            skills_input TEXT NOT NULL,
            target_role TEXT NOT NULL,
            industry TEXT NOT NULL,
            salary_goal TEXT NOT NULL,
            country TEXT NOT NULL,
            strong_skills TEXT NOT NULL,
            missing_skills TEXT NOT NULL,
            readiness_score INTEGER NOT NULL,
            recommended_next_step TEXT NOT NULL,
            summary TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE roadmap_tasks(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            title TEXT NOT NULL,
            description TEXT NOT NULL,
            priority TEXT NOT NULL,
            deadline TEXT NOT NULL,
            status TEXT NOT NULL,
            is_weekly INTEGER NOT NULL DEFAULT 0,
            week_start TEXT,
            source TEXT NOT NULL DEFAULT 'manual'
          )
        ''');

        await db.execute('''
          CREATE TABLE feedback_entries(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER,
            name TEXT NOT NULL,
            role TEXT NOT NULL,
            rating INTEGER NOT NULL,
            useful_text TEXT NOT NULL,
            confusing_text TEXT NOT NULL,
            improve_text TEXT NOT NULL,
            would_use_again INTEGER NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE role_templates(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            role TEXT NOT NULL,
            title TEXT NOT NULL,
            description TEXT NOT NULL,
            skill_focus TEXT NOT NULL,
            path_label TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE settings(
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
          )
        ''');

        await _seedRoleTemplates(db);
        await db.insert('settings', {
          'key': 'notifications_enabled',
          'value': '1',
        });
      },
    );
  }

  Future<void> _seedRoleTemplates(Database db) async {
    final templates = <Map<String, Object>>[
      {
        'role': UserRole.employerHr.name,
        'title': 'Младший продуктовый аналитик',
        'description':
            'Базовый шаблон требований для специалистов в начале карьеры.',
        'skill_focus':
            'SQL, аналитика данных, дашборды, коммуникация со стейкхолдерами',
        'path_label': '6-недельный буткемп аналитика',
      },
      {
        'role': UserRole.employerHr.name,
        'title': 'Frontend-разработчик',
        'description': 'Современные веб-навыки, которые часто требуют работодатели.',
        'skill_focus': 'JavaScript, React, тестирование, интеграция API',
        'path_label': '8-недельный старт во frontend',
      },
      {
        'role': UserRole.university.name,
        'title': 'Трек карьерной готовности выпускника',
        'description':
            'Шаблон карьерного центра для студентов, готовящихся к стажировкам.',
        'skill_focus':
            'резюме, подготовка к интервью, коммуникация, LinkedIn',
        'path_label': 'семестровая программа готовности',
      },
      {
        'role': UserRole.university.name,
        'title': 'Старт карьеры в data',
        'description': 'Набор навыков, рекомендованный для выпускников, идущих в data.',
        'skill_focus': 'Python, SQL, статистика, проекты для портфолио',
        'path_label': '12-недельный путь в data',
      },
    ];

    for (final template in templates) {
      await db.insert('role_templates', template);
    }
  }
}
