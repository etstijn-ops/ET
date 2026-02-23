import 'package:flutter/material.dart';
import '../models/timing_session.dart';
import '../utils/app_theme.dart';
import '../utils/time_formatter.dart';

class SessionPickerSheet extends StatelessWidget {
  final List<TimingSession> sessions;
  final TimingSession? activeSession;
  final Function(TimingSession) onSelect;
  final VoidCallback onNew;

  const SessionPickerSheet({
    super.key,
    required this.sessions,
    required this.activeSession,
    required this.onSelect,
    required this.onNew,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              width: 36, height: 4,
              decoration: BoxDecoration(color: AppTheme.borderBright, borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Row(
                children: [
                  const Text('SELECT SESSION', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: onNew,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('NEW', style: TextStyle(fontSize: 11, letterSpacing: 1)),
                    style: TextButton.styleFrom(foregroundColor: AppTheme.accent),
                  ),
                ],
              ),
            ),
            Expanded(
              child: sessions.isEmpty
                ? const Center(child: Text('No sessions yet', style: TextStyle(color: AppTheme.textSecondary)))
                : ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: sessions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final s = sessions[index];
                      final isSelected = s.id == activeSession?.id;
                      return GestureDetector(
                        onTap: () => onSelect(s),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.accent.withOpacity(0.08) : AppTheme.surfaceElevated,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: isSelected ? AppTheme.accent : AppTheme.border),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(s.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${s.records.length} runs · ${TimeFormatter.formatDate(s.createdAt)}',
                                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected) const Icon(Icons.check, color: AppTheme.accent, size: 18),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
            ),
          ],
        );
      },
    );
  }
}
