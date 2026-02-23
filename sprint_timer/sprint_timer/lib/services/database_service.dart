import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/timing_session.dart';
import '../models/time_record.dart';
import '../models/athlete.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._internal();
  DatabaseService._internal();

  Database? _db;

  Future<void> initialize() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'sprint_timer.db');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Database get db {
    if (_db == null) throw Exception('Database not initialized');
    return _db!;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE sessions (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        distance TEXT,
        location TEXT,
        created_at INTEGER NOT NULL,
        started_at INTEGER,
        ended_at INTEGER,
        status INTEGER DEFAULT 0,
        notes TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE time_records (
        id TEXT PRIMARY KEY,
        session_id TEXT NOT NULL,
        athlete_id TEXT,
        athlete_name TEXT,
        duration_ms INTEGER NOT NULL,
        split_ms INTEGER,
        recorded_at INTEGER NOT NULL,
        lane INTEGER DEFAULT 1,
        raw_packet TEXT,
        FOREIGN KEY (session_id) REFERENCES sessions(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE athletes (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        bib_number TEXT,
        category TEXT
      )
    ''');
  }

  // ─── Sessions ────────────────────────────────────────────────────────────

  Future<void> insertSession(TimingSession session) async {
    await db.insert('sessions', session.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateSession(TimingSession session) async {
    await db.update('sessions', session.toMap(), where: 'id = ?', whereArgs: [session.id]);
  }

  Future<void> deleteSession(String id) async {
    await db.delete('sessions', where: 'id = ?', whereArgs: [id]);
    await db.delete('time_records', where: 'session_id = ?', whereArgs: [id]);
  }

  Future<List<TimingSession>> getSessions() async {
    final rows = await db.query('sessions', orderBy: 'created_at DESC');
    final sessions = rows.map((r) => TimingSession.fromMap(r)).toList();
    for (final session in sessions) {
      session.records = await getRecordsForSession(session.id);
    }
    return sessions;
  }

  Future<TimingSession?> getSession(String id) async {
    final rows = await db.query('sessions', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    final session = TimingSession.fromMap(rows.first);
    session.records = await getRecordsForSession(id);
    return session;
  }

  // ─── Time Records ─────────────────────────────────────────────────────────

  Future<void> insertRecord(TimeRecord record) async {
    await db.insert('time_records', record.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteRecord(String id) async {
    await db.delete('time_records', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<TimeRecord>> getRecordsForSession(String sessionId) async {
    final rows = await db.query(
      'time_records',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'recorded_at ASC',
    );
    return rows.map((r) => TimeRecord.fromMap(r)).toList();
  }

  // ─── Athletes ─────────────────────────────────────────────────────────────

  Future<void> insertAthlete(Athlete athlete) async {
    await db.insert('athletes', athlete.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateAthlete(Athlete athlete) async {
    await db.update('athletes', athlete.toMap(), where: 'id = ?', whereArgs: [athlete.id]);
  }

  Future<void> deleteAthlete(String id) async {
    await db.delete('athletes', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Athlete>> getAthletes() async {
    final rows = await db.query('athletes', orderBy: 'name ASC');
    return rows.map((r) => Athlete.fromMap(r)).toList();
  }
}
