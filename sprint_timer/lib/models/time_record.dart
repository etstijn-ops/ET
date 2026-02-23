class TimeRecord {
  final String id;
  final String sessionId;
  final String? athleteId;
  final String? athleteName;
  final int durationMs;        // Total time in milliseconds
  final int? splitMs;          // Split time if applicable
  final DateTime recordedAt;
  final int lane;              // Lane number (1-8)
  final String? rawPacket;     // Raw BLE packet for debugging

  TimeRecord({
    required this.id,
    required this.sessionId,
    this.athleteId,
    this.athleteName,
    required this.durationMs,
    this.splitMs,
    required this.recordedAt,
    this.lane = 1,
    this.rawPacket,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'session_id': sessionId,
    'athlete_id': athleteId,
    'athlete_name': athleteName,
    'duration_ms': durationMs,
    'split_ms': splitMs,
    'recorded_at': recordedAt.millisecondsSinceEpoch,
    'lane': lane,
    'raw_packet': rawPacket,
  };

  factory TimeRecord.fromMap(Map<String, dynamic> map) => TimeRecord(
    id: map['id'],
    sessionId: map['session_id'],
    athleteId: map['athlete_id'],
    athleteName: map['athlete_name'],
    durationMs: map['duration_ms'],
    splitMs: map['split_ms'],
    recordedAt: DateTime.fromMillisecondsSinceEpoch(map['recorded_at']),
    lane: map['lane'] ?? 1,
    rawPacket: map['raw_packet'],
  );
}
