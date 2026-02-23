import 'package:flutter/material.dart';
import '../models/time_record.dart';
import '../utils/app_theme.dart';
import '../utils/time_formatter.dart';

class TimeCard extends StatelessWidget {
  final TimeRecord record;
  final int rank;
  final bool isBest;
  final bool isNew;
  final VoidCallback? onDelete;

  const TimeCard({
    super.key,
    required this.record,
    required this.rank,
    this.isBest = false,
    this.isNew = false,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isBest ? AppTheme.accent.withOpacity(0.07) : AppTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isBest ? AppTheme.accent.withOpacity(0.4) : isNew ? AppTheme.accent.withOpacity(0.2) : AppTheme.border,
          width: isBest ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          // Rank
          SizedBox(
            width: 28,
            child: Text(
              '#$rank',
              style: TextStyle(
                fontSize: 11,
                color: isBest ? AppTheme.accent : AppTheme.textMuted,
                fontWeight: isBest ? FontWeight.w700 : FontWeight.normal,
              ),
            ),
          ),
          // Athlete / Lane
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.athleteName ?? 'Lane ${record.lane}',
                  style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  TimeFormatter.formatDateTime(record.recordedAt),
                  style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
          // Time
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                TimeFormatter.format(record.durationMs),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isBest ? AppTheme.accent : AppTheme.textPrimary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              if (isBest)
                const Text('BEST', style: TextStyle(fontSize: 9, color: AppTheme.accent, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
            ],
          ),
          if (onDelete != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onDelete,
              child: const Icon(Icons.close, size: 16, color: AppTheme.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}
