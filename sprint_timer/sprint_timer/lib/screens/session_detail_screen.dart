import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/timing_session.dart';
import '../models/time_record.dart';
import '../services/export_service.dart';
import '../utils/app_theme.dart';
import '../utils/time_formatter.dart';
import '../widgets/time_card.dart';

class SessionDetailScreen extends StatelessWidget {
  final TimingSession session;
  const SessionDetailScreen({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final sorted = [...session.records]..sort((a, b) => a.durationMs.compareTo(b.durationMs));

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(session.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () => ExportService.instance.exportSessionToCsv(session),
          ),
        ],
      ),
      body: session.records.isEmpty
          ? const Center(child: Text('No records in this session', style: TextStyle(color: AppTheme.textSecondary)))
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildStats(session)),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  sliver: SliverList.separated(
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemCount: sorted.length,
                    itemBuilder: (context, index) {
                      final record = sorted[index];
                      return TimeCard(
                        record: record,
                        rank: index + 1,
                        isBest: index == 0,
                        onDelete: null,
                      ).animate().fadeIn(delay: (index * 30).ms);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStats(TimingSession session) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _Stat('RUNS', session.records.length.toString()),
              _Stat('DISTANCE', session.distance ?? '--'),
              _Stat('LOCATION', session.location ?? '--'),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppTheme.border),
          const SizedBox(height: 16),
          Row(
            children: [
              _Stat('BEST', session.bestTimeMs != null ? TimeFormatter.format(session.bestTimeMs!) : '--'),
              _Stat('AVERAGE', session.averageTimeMs != null ? TimeFormatter.format(session.averageTimeMs!) : '--'),
              _Stat('WORST', session.worstTimeMs != null ? TimeFormatter.format(session.worstTimeMs!) : '--'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 9, color: AppTheme.textMuted, letterSpacing: 1.5)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary, fontWeight: FontWeight.w700), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
