import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/timing_session.dart';
import '../models/time_record.dart';
import '../models/athlete.dart';
import '../models/ble_packet.dart';
import 'database_service.dart';

class SessionService extends ChangeNotifier {
  final _uuid = const Uuid();
  final _db = DatabaseService.instance;

  List<TimingSession> _sessions = [];
  TimingSession? _activeSession;
  List<Athlete> _athletes = [];

  // Live timing state
  bool _isListening = false;
  int? _startTimestampMs;
  StreamSubscription? _packetSub;
  final List<TimeRecord> _liveRecords = [];

  // ─── Getters ───────────────────────────────────────────────────────────────

  List<TimingSession> get sessions => _sessions;
  TimingSession? get activeSession => _activeSession;
  List<Athlete> get athletes => _athletes;
  List<TimeRecord> get liveRecords => List.unmodifiable(_liveRecords);
  bool get isListening => _isListening;
  bool get hasActiveSession => _activeSession != null;

  // ─── Init ──────────────────────────────────────────────────────────────────

  Future<void> loadData() async {
    _sessions = await _db.getSessions();
    _athletes = await _db.getAthletes();
    notifyListeners();
  }

  // ─── Sessions ──────────────────────────────────────────────────────────────

  Future<TimingSession> createSession({
    required String name,
    String? distance,
    String? location,
    String? notes,
  }) async {
    final session = TimingSession(
      id: _uuid.v4(),
      name: name,
      distance: distance,
      location: location,
      createdAt: DateTime.now(),
      notes: notes,
    );
    await _db.insertSession(session);
    _sessions.insert(0, session);
    notifyListeners();
    return session;
  }

  Future<void> updateSession(TimingSession session) async {
    await _db.updateSession(session);
    final idx = _sessions.indexWhere((s) => s.id == session.id);
    if (idx != -1) _sessions[idx] = session;
    notifyListeners();
  }

  Future<void> deleteSession(String id) async {
    await _db.deleteSession(id);
    _sessions.removeWhere((s) => s.id == id);
    if (_activeSession?.id == id) _activeSession = null;
    notifyListeners();
  }

  void setActiveSession(TimingSession? session) {
    _activeSession = session;
    _liveRecords.clear();
    if (session != null) {
      _liveRecords.addAll(session.records);
    }
    notifyListeners();
  }

  // ─── Live Timing ───────────────────────────────────────────────────────────

  void startListening(Stream<BlePacket> packetStream) {
    if (_isListening) return;
    _isListening = true;
    _startTimestampMs = null;
    notifyListeners();

    _packetSub = packetStream.listen((packet) {
      if (!packet.isValid) {
        debugPrint('Invalid packet received: ${packet.rawHex}');
        return;
      }
      _handlePacket(packet);
    });
  }

  void stopListening() {
    _packetSub?.cancel();
    _isListening = false;
    _startTimestampMs = null;
    notifyListeners();
  }

  void _handlePacket(BlePacket packet) async {
    switch (packet.eventType) {
      case BleEventType.start:
        _startTimestampMs = packet.timestampMs;
        if (_activeSession != null) {
          _activeSession!.startedAt = DateTime.now();
          _activeSession!.status = SessionStatus.active;
          await _db.updateSession(_activeSession!);
        }
        notifyListeners();
        break;

      case BleEventType.finish:
        int durationMs;
        if (_startTimestampMs != null) {
          durationMs = packet.timestampMs - _startTimestampMs!;
          _startTimestampMs = null; // reset for next runner
        } else {
          // No explicit start received — use chip's timestamp as total time
          durationMs = packet.timestampMs;
        }
        await _recordTime(durationMs: durationMs, lane: packet.lane, rawPacket: packet.rawHex);
        break;

      case BleEventType.split:
        if (_startTimestampMs != null) {
          final splitMs = packet.timestampMs - _startTimestampMs!;
          debugPrint('Split time: ${splitMs}ms on lane ${packet.lane}');
          // Splits are stored as split_ms on the next finish record
          // or handled separately as needed
        }
        break;

      case BleEventType.heartbeat:
        debugPrint('Heartbeat from chip');
        break;

      default:
        debugPrint('Unknown packet type: ${packet.rawHex}');
    }
  }

  Future<void> _recordTime({
    required int durationMs,
    int lane = 1,
    String? athleteId,
    String? rawPacket,
  }) async {
    if (_activeSession == null) return;

    // Find athlete assigned to this lane if any
    final athleteName = _getAthleteForLane(lane)?.name;

    final record = TimeRecord(
      id: _uuid.v4(),
      sessionId: _activeSession!.id,
      athleteId: athleteId,
      athleteName: athleteName,
      durationMs: durationMs,
      recordedAt: DateTime.now(),
      lane: lane,
      rawPacket: rawPacket,
    );

    await _db.insertRecord(record);
    _activeSession!.records.add(record);
    _liveRecords.add(record);

    // Update session in memory list too
    final idx = _sessions.indexWhere((s) => s.id == _activeSession!.id);
    if (idx != -1) _sessions[idx] = _activeSession!;

    notifyListeners();
  }

  /// Manually add a time (for manual entry)
  Future<void> addManualTime({
    required int durationMs,
    int lane = 1,
    String? athleteId,
    String? athleteName,
  }) async {
    if (_activeSession == null) return;

    final record = TimeRecord(
      id: _uuid.v4(),
      sessionId: _activeSession!.id,
      athleteId: athleteId,
      athleteName: athleteName,
      durationMs: durationMs,
      recordedAt: DateTime.now(),
      lane: lane,
    );

    await _db.insertRecord(record);
    _activeSession!.records.add(record);
    _liveRecords.add(record);
    notifyListeners();
  }

  Future<void> deleteRecord(String recordId) async {
    await _db.deleteRecord(recordId);
    _liveRecords.removeWhere((r) => r.id == recordId);
    _activeSession?.records.removeWhere((r) => r.id == recordId);
    notifyListeners();
  }

  // ─── Athletes ──────────────────────────────────────────────────────────────

  Future<Athlete> createAthlete({
    required String name,
    String? bibNumber,
    String? category,
  }) async {
    final athlete = Athlete(
      id: _uuid.v4(),
      name: name,
      bibNumber: bibNumber,
      category: category,
    );
    await _db.insertAthlete(athlete);
    _athletes.add(athlete);
    _athletes.sort((a, b) => a.name.compareTo(b.name));
    notifyListeners();
    return athlete;
  }

  Future<void> deleteAthlete(String id) async {
    await _db.deleteAthlete(id);
    _athletes.removeWhere((a) => a.id == id);
    notifyListeners();
  }

  // ─── Lane assignment ───────────────────────────────────────────────────────
  // Simple map: lane number -> athlete id (session-scoped, not persisted)
  final Map<int, String> _laneAthleteMap = {};

  void assignAthleteToLane(int lane, String? athleteId) {
    if (athleteId == null) {
      _laneAthleteMap.remove(lane);
    } else {
      _laneAthleteMap[lane] = athleteId;
    }
    notifyListeners();
  }

  Athlete? _getAthleteForLane(int lane) {
    final id = _laneAthleteMap[lane];
    if (id == null) return null;
    try {
      return _athletes.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  Map<int, String> get laneAthleteMap => Map.unmodifiable(_laneAthleteMap);

  @override
  void dispose() {
    _packetSub?.cancel();
    super.dispose();
  }
}
