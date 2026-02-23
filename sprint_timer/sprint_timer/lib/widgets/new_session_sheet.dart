import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/session_service.dart';
import '../models/timing_session.dart';
import '../utils/app_theme.dart';

class NewSessionSheet extends StatefulWidget {
  final Function(TimingSession) onCreated;
  const NewSessionSheet({super.key, required this.onCreated});

  @override
  State<NewSessionSheet> createState() => _NewSessionSheetState();
}

class _NewSessionSheetState extends State<NewSessionSheet> {
  final _nameCtrl = TextEditingController();
  final _distCtrl = TextEditingController();
  final _locCtrl = TextEditingController();
  String _selectedDistance = '';

  final _presetDistances = ['60m', '100m', '200m', '400m', '110m H', '400m H', 'Custom'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            alignment: Alignment.center,
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(color: AppTheme.borderBright, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const Text('NEW SESSION', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
          const SizedBox(height: 20),

          TextField(
            controller: _nameCtrl,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Session Name *', hintText: 'e.g. Morning Training'),
          ),
          const SizedBox(height: 16),

          const Text('DISTANCE', style: TextStyle(fontSize: 10, color: AppTheme.textMuted, letterSpacing: 1.5)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _presetDistances.map((d) {
              final isSelected = _selectedDistance == d;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDistance = d;
                    if (d != 'Custom') _distCtrl.text = d;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.accent.withOpacity(0.15) : AppTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: isSelected ? AppTheme.accent : AppTheme.border),
                  ),
                  child: Text(d, style: TextStyle(fontSize: 12, color: isSelected ? AppTheme.accent : AppTheme.textSecondary, fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal)),
                ),
              );
            }).toList(),
          ),
          if (_selectedDistance == 'Custom') ...[
            const SizedBox(height: 12),
            TextField(controller: _distCtrl, decoration: const InputDecoration(labelText: 'Custom Distance', hintText: 'e.g. 150m')),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _locCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Location', hintText: 'e.g. National Stadium'),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _onCreate,
              child: const Text('CREATE SESSION'),
            ),
          ),
        ],
      ),
    );
  }

  void _onCreate() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    final service = context.read<SessionService>();
    final session = await service.createSession(
      name: name,
      distance: _distCtrl.text.trim().isEmpty ? null : _distCtrl.text.trim(),
      location: _locCtrl.text.trim().isEmpty ? null : _locCtrl.text.trim(),
    );
    widget.onCreated(session);
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _distCtrl.dispose();
    _locCtrl.dispose();
    super.dispose();
  }
}
