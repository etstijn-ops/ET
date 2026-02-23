import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../services/session_service.dart';
import '../services/export_service.dart';
import '../models/timing_session.dart';
import '../utils/app_theme.dart';
import '../utils/time_formatter.dart';
import '../widgets/new_session_sheet.dart';
import 'session_detail_screen.dart';

class SessionsScreen extends StatelessWidget {
  const SessionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SessionService>(
      builder: (context, service, _) {
        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            title: const Text('SESSIONS'),
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _showNewSession(context, service),
              ),
            ],
          ),
          body: service.sessions.isEmpty
              ? _buildEmpty(context, service)
              : _buildList(context, service),
        );
      },
    );
  }

  Widget _buildEmpty(BuildContext context, SessionService service) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.folder_open, size: 56, color: AppTheme.textMuted),
          const SizedBox(height: 16),
          const Text('No sessions yet', style: TextStyle(color: AppTheme.textSecondary, fontSize: 15)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showNewSession(context, service),
            icon: const Icon(Icons.add),
            label: const Text('NEW SESSION'),
          ),
        ],
      ).animate().fadeIn(),
    );
  }

  Widget _buildList(BuildContext context, SessionService service) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: service.sessions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final session = service.sessions[index];
        return _SessionTile(
          session: session,
          isActive: service.activeSession?.id == session.id,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => SessionDetailScreen(session: session)),
          ),
          onActivate: () => service.setActiveSession(session),
          onExport: () => ExportService.instance.exportSessionToCsv(session),
          onDelete: () => _confirmDelete(context, service, session),
        ).animate().fadeIn(delay: (index * 40).ms);
      },
    );
  }

  void _showNewSession(BuildContext context, SessionService service) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => NewSessionSheet(onCreated: (s) => service.setActiveSession(s)),
    );
  }

  void _confirmDelete(BuildContext context, SessionService service, TimingSession session) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Delete Session'),
        content: Text('Delete "${session.name}" and all its records? This cannot be undone.', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL', style: TextStyle(color: AppTheme.textSecondary))),
          ElevatedButton(
            onPressed: () { service.deleteSession(session.id); Navigator.pop(ctx); },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  final TimingSession session;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onActivate;
  final VoidCallback onExport;
  final VoidCallback onDelete;

  const _SessionTile({
    required this.session,
    required this.isActive,
    required this.onTap,
    required this.onActivate,
    required this.onExport,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isActive ? AppTheme.accent : AppTheme.border, width: isActive ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: (isActive ? AppTheme.accent : AppTheme.textMuted).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.timer, color: isActive ? AppTheme.accent : AppTheme.textMuted, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(session.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.textPrimary), overflow: TextOverflow.ellipsis)),
                      if (isActive) Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: AppTheme.accent.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                        child: const Text('ACTIVE', style: TextStyle(fontSize: 9, color: AppTheme.accent, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (session.distance != null) ...[
                        Text(session.distance!, style: const TextStyle(fontSize: 11, color: AppTheme.accent)),
                        const Text(' · ', style: TextStyle(color: AppTheme.textMuted)),
                      ],
                      Text('${session.records.length} runs', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                      if (session.bestTimeMs != null) ...[
                        const Text(' · ', style: TextStyle(color: AppTheme.textMuted)),
                        Text('Best: ${TimeFormatter.formatShort(session.bestTimeMs!)}', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(TimeFormatter.formatDate(session.createdAt), style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                ],
              ),
            ),
            PopupMenuButton<String>(
              color: AppTheme.surfaceElevated,
              icon: const Icon(Icons.more_vert, color: AppTheme.textSecondary, size: 20),
              onSelected: (val) {
                if (val == 'activate') onActivate();
                if (val == 'export') onExport();
                if (val == 'delete') onDelete();
              },
              itemBuilder: (_) => [
                if (!isActive) const PopupMenuItem(value: 'activate', child: Text('Set as Active')),
                const PopupMenuItem(value: 'export', child: Text('Export CSV')),
                const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: AppTheme.danger))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
