import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../services/session_service.dart';
import '../models/athlete.dart';
import '../utils/app_theme.dart';

class AthletesScreen extends StatelessWidget {
  const AthletesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SessionService>(
      builder: (context, service, _) {
        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            title: const Text('ATHLETES'),
            actions: [
              IconButton(
                icon: const Icon(Icons.person_add_outlined),
                onPressed: () => _showAddAthlete(context, service),
              ),
            ],
          ),
          body: service.athletes.isEmpty
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
          const Icon(Icons.people_outline, size: 56, color: AppTheme.textMuted),
          const SizedBox(height: 16),
          const Text('No athletes yet', style: TextStyle(color: AppTheme.textSecondary, fontSize: 15)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddAthlete(context, service),
            icon: const Icon(Icons.add),
            label: const Text('ADD ATHLETE'),
          ),
        ],
      ).animate().fadeIn(),
    );
  }

  Widget _buildList(BuildContext context, SessionService service) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: service.athletes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final athlete = service.athletes[index];
        return _AthleteTile(
          athlete: athlete,
          onDelete: () => _confirmDelete(context, service, athlete),
        ).animate().fadeIn(delay: (index * 40).ms);
      },
    );
  }

  void _showAddAthlete(BuildContext context, SessionService service) {
    final nameCtrl = TextEditingController();
    final bibCtrl = TextEditingController();
    final catCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ADD ATHLETE', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
            const SizedBox(height: 20),
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name *'), textCapitalization: TextCapitalization.words),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: TextField(controller: bibCtrl, decoration: const InputDecoration(labelText: 'Bib #'), keyboardType: TextInputType.number)),
                const SizedBox(width: 12),
                Expanded(child: TextField(controller: catCtrl, decoration: const InputDecoration(labelText: 'Category'), textCapitalization: TextCapitalization.words)),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (nameCtrl.text.trim().isNotEmpty) {
                    service.createAthlete(name: nameCtrl.text.trim(), bibNumber: bibCtrl.text.trim().isEmpty ? null : bibCtrl.text.trim(), category: catCtrl.text.trim().isEmpty ? null : catCtrl.text.trim());
                    Navigator.pop(ctx);
                  }
                },
                child: const Text('ADD ATHLETE'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, SessionService service, Athlete athlete) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Delete Athlete'),
        content: Text('Remove ${athlete.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL', style: TextStyle(color: AppTheme.textSecondary))),
          ElevatedButton(
            onPressed: () { service.deleteAthlete(athlete.id); Navigator.pop(ctx); },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }
}

class _AthleteTile extends StatelessWidget {
  final Athlete athlete;
  final VoidCallback onDelete;
  const _AthleteTile({required this.athlete, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: AppTheme.accent.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Center(
              child: Text(
                athlete.name.substring(0, 1).toUpperCase(),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.accent),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(athlete.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                if (athlete.bibNumber != null || athlete.category != null)
                  Text(
                    [if (athlete.bibNumber != null) '#${athlete.bibNumber}', if (athlete.category != null) athlete.category!].join(' · '),
                    style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                  ),
              ],
            ),
          ),
          IconButton(icon: const Icon(Icons.delete_outline, color: AppTheme.textMuted, size: 20), onPressed: onDelete),
        ],
      ),
    );
  }
}
