import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/timing_session.dart';
import '../utils/time_formatter.dart';

class ExportService {
  static final ExportService instance = ExportService._internal();
  ExportService._internal();

  Future<void> exportSessionToCsv(TimingSession session) async {
    final rows = <List<dynamic>>[
      // Header
      ['#', 'Athlete', 'Lane', 'Time', 'Time (ms)', 'Date', 'Time of Day'],
    ];

    for (int i = 0; i < session.records.length; i++) {
      final r = session.records[i];
      rows.add([
        i + 1,
        r.athleteName ?? '-',
        r.lane,
        TimeFormatter.format(r.durationMs),
        r.durationMs,
        TimeFormatter.formatDate(r.recordedAt),
        TimeFormatter.formatDateTime(r.recordedAt),
      ]);
    }

    // Summary rows
    rows.add([]);
    rows.add(['SUMMARY']);
    rows.add(['Session', session.name]);
    rows.add(['Distance', session.distance ?? '-']);
    rows.add(['Location', session.location ?? '-']);
    rows.add(['Athletes', session.records.length]);
    if (session.bestTimeMs != null) {
      rows.add(['Best Time', TimeFormatter.format(session.bestTimeMs!)]);
      rows.add(['Average Time', TimeFormatter.format(session.averageTimeMs!)]);
      rows.add(['Worst Time', TimeFormatter.format(session.worstTimeMs!)]);
    }

    final csv = const ListToCsvConverter().convert(rows);
    final dir = await getTemporaryDirectory();
    final safeName = session.name.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final file = File('${dir.path}/${safeName}_${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(csv);

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'text/csv')],
      subject: 'Sprint Timer — ${session.name}',
    );
  }

  String buildCsvString(TimingSession session) {
    final rows = <List<dynamic>>[
      ['#', 'Athlete', 'Lane', 'Time', 'Time (ms)', 'Date', 'Time of Day'],
    ];
    for (int i = 0; i < session.records.length; i++) {
      final r = session.records[i];
      rows.add([
        i + 1,
        r.athleteName ?? '-',
        r.lane,
        TimeFormatter.format(r.durationMs),
        r.durationMs,
        TimeFormatter.formatDate(r.recordedAt),
        TimeFormatter.formatDateTime(r.recordedAt),
      ]);
    }
    return const ListToCsvConverter().convert(rows);
  }
}
