class TimeFormatter {
  /// Format milliseconds to MM:SS.mmm
  static String format(int milliseconds) {
    if (milliseconds < 0) return '--:--.---';
    final ms = milliseconds % 1000;
    final seconds = (milliseconds ~/ 1000) % 60;
    final minutes = (milliseconds ~/ 60000);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.${ms.toString().padLeft(3, '0')}';
  }

  /// Format as S.mmm for short sprints (under 60s)
  static String formatShort(int milliseconds) {
    if (milliseconds < 0) return '--.---';
    final ms = milliseconds % 1000;
    final seconds = milliseconds ~/ 1000;
    return '${seconds.toString()}.${ms.toString().padLeft(3, '0')}';
  }

  /// Format as HH:MM:SS for display
  static String formatDateTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}:${dt.second.toString().padLeft(2,'0')}';
  }

  /// Format date for session list
  static String formatDate(DateTime dt) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${dt.day} ${months[dt.month-1]} ${dt.year}';
  }

  /// Parse milliseconds from BLE packet bytes (big-endian uint32)
  static int parseFromBytes(List<int> bytes, {int offset = 0}) {
    if (bytes.length < offset + 4) return -1;
    return (bytes[offset] << 24) |
           (bytes[offset + 1] << 16) |
           (bytes[offset + 2] << 8) |
           bytes[offset + 3];
  }
}
