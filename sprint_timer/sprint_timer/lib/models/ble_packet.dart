/// Defines the BLE communication protocol between the timing chip and the app.
///
/// PACKET FORMAT (8 bytes):
/// [0]     Event type  (1 byte)
/// [1]     Lane number (1 byte, 1-8)
/// [2-5]   Timestamp   (4 bytes, big-endian uint32, milliseconds since start)
/// [6]     Sequence    (1 byte, rolling counter to detect missed packets)
/// [7]     Checksum    (1 byte, XOR of bytes 0-6)
///
/// EVENT TYPES:
/// 0x01 = START  — chip detected start gate trigger
/// 0x02 = SPLIT  — intermediate gate trigger
/// 0x03 = FINISH — finish line trigger
/// 0xFF = HEARTBEAT — periodic keep-alive from chip
///
/// SERVICE UUID:  your-device-service-uuid (configure in BleService)
/// CHAR UUID:     your-device-char-uuid    (configure in BleService)

enum BleEventType { start, split, finish, heartbeat, unknown }

class BlePacket {
  final BleEventType eventType;
  final int lane;
  final int timestampMs;
  final int sequence;
  final bool isValid;
  final List<int> rawBytes;

  BlePacket({
    required this.eventType,
    required this.lane,
    required this.timestampMs,
    required this.sequence,
    required this.isValid,
    required this.rawBytes,
  });

  static BlePacket parse(List<int> bytes) {
    if (bytes.length < 8) {
      return BlePacket(
        eventType: BleEventType.unknown,
        lane: 0,
        timestampMs: 0,
        sequence: 0,
        isValid: false,
        rawBytes: bytes,
      );
    }

    // Validate checksum (XOR of bytes 0-6)
    int checksum = 0;
    for (int i = 0; i < 7; i++) checksum ^= bytes[i];
    final isValid = checksum == bytes[7];

    final eventType = _parseEventType(bytes[0]);
    final lane = bytes[1];
    final timestamp = (bytes[2] << 24) | (bytes[3] << 16) | (bytes[4] << 8) | bytes[5];
    final sequence = bytes[6];

    return BlePacket(
      eventType: eventType,
      lane: lane,
      timestampMs: timestamp,
      sequence: sequence,
      isValid: isValid,
      rawBytes: bytes,
    );
  }

  static BleEventType _parseEventType(int byte) {
    switch (byte) {
      case 0x01: return BleEventType.start;
      case 0x02: return BleEventType.split;
      case 0x03: return BleEventType.finish;
      case 0xFF: return BleEventType.heartbeat;
      default:   return BleEventType.unknown;
    }
  }

  /// Build a test packet for debugging (simulates finish event)
  static List<int> buildTestPacket({
    int eventTypeByte = 0x03,
    int lane = 1,
    required int timestampMs,
    int sequence = 0,
  }) {
    final bytes = [
      eventTypeByte,
      lane,
      (timestampMs >> 24) & 0xFF,
      (timestampMs >> 16) & 0xFF,
      (timestampMs >> 8) & 0xFF,
      timestampMs & 0xFF,
      sequence,
      0, // checksum placeholder
    ];
    int checksum = 0;
    for (int i = 0; i < 7; i++) checksum ^= bytes[i];
    bytes[7] = checksum;
    return bytes;
  }

  String get rawHex => rawBytes.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ');

  @override
  String toString() => 'BlePacket(type=$eventType, lane=$lane, ts=${timestampMs}ms, seq=$sequence, valid=$isValid)';
}
