import 'time_record.dart';

enum SessionStatus { idle, active, paused, completed }

class TimingSession {
  final String id;
  String name;
  String? distance;       // e.g. "100m", "60m"
  String? location;
  DateTime createdAt;
  DateTime? startedAt;
  DateTime? endedAt;
  SessionStatus status;
  List<TimeRecord> records;
  String? notes;

  TimingSession({
    required this.id,
    required this.name,
    this.distance,
    this.location,
    required this.createdAt,
    this.startedAt,
    this.endedAt,
    this.status = SessionStatus.idle,
    List<TimeRecord>? records,
    this.notes,
  }) : records = records ?? [];

  int? get bestTimeMs {
    if (records.isEmpty) return null;
    return records.map((r) => r.durationMs).reduce((a, b) => a < b ? a : b);
  }

  int? get averageTimeMs {
    if (records.isEmpty) return null;
    return records.map((r) => r.durationMs).reduce((a, b) => a + b) ~/ records.length;
  }

  int? get worstTimeMs {
    if (records.isEmpty) return null;
    return records.map((r) => r.durationMs).reduce((a, b) => a > b ? a : b);
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'distance': distance,
    'location': location,
    'created_at': createdAt.millisecondsSinceEpoch,
    'started_at': startedAt?.millisecondsSinceEpoch,
    'ended_at': endedAt?.millisecondsSinceEpoch,
    'status': status.index,
    'notes': notes,
  };

  factory TimingSession.fromMap(Map<String, dynamic> map) => TimingSession(
    id: map['id'],
    name: map['name'],
    distance: map['distance'],
    location: map['location'],
    createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
    startedAt: map['started_at'] != null
        ? DateTime.fromMillisecondsSinceEpoch(map['started_at'])
        : null,
    endedAt: map['ended_at'] != null
        ? DateTime.fromMillisecondsSinceEpoch(map['ended_at'])
        : null,
    status: SessionStatus.values[map['status'] ?? 0],
    notes: map['notes'],
  );
}
