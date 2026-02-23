import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../services/ble_service.dart';
import '../services/session_service.dart';
import '../models/timing_session.dart';
import '../models/time_record.dart';
import '../utils/app_theme.dart';
import '../utils/time_formatter.dart';
import '../widgets/time_card.dart';
import '../widgets/session_picker_sheet.dart';
import '../widgets/new_session_sheet.dart';

class TimingScreen extends StatefulWidget {
  const TimingScreen({super.key});

  @override
  State<TimingScreen> createState() => _TimingScreenState();
}

class _TimingScreenState extends State<TimingScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  TimeRecord? _lastRecord;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _onNewRecord(TimeRecord record) {
    setState(() => _lastRecord = record);
    _pulseController.forward(from: 0);
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<BleService, SessionService>(
      builder: (context, ble, session, _) {
        // Listen for new records
        final records = session.liveRecords;
        if (records.isNotEmpty && records.last != _lastRecord) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (records.isNotEmpty && records.last != _lastRecord) {
              _onNewRecord(records.last);
            }
          });
        }

        return Scaffold(
          backgroundColor: AppTheme.background,
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(context, ble, session),
                Expanded(child: _buildBody(context, ble, session)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, BleService ble, SessionService session) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('SPRINT TIMER', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: 2, color: AppTheme.textPrimary)),
              const SizedBox(height: 2),
              GestureDetector(
                onTap: () => _showSessionPicker(context, session),
                child: Row(
                  children: [
                    Text(
                      session.activeSession?.name ?? 'No session selected',
                      style: const TextStyle(fontSize: 12, color: AppTheme.accent, letterSpacing: 0.5),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.expand_more, size: 14, color: AppTheme.accent),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          if (session.activeSession != null)
            _buildListenToggle(ble, session),
        ],
      ),
    );
  }

  Widget _buildListenToggle(BleService ble, SessionService session) {
    final isListening = session.isListening;
    return GestureDetector(
      onTap: () {
        if (!ble.isConnected && !ble.isMockMode) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Connect to your timing chip first')),
          );
          return;
        }
        if (isListening) {
          session.stopListening();
        } else {
          session.startListening(ble.packetStream);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isListening ? AppTheme.danger.withOpacity(0.15) : AppTheme.accent.withOpacity(0.15),
          border: Border.all(color: isListening ? AppTheme.danger : AppTheme.accent, width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 6, height: 6,
              decoration: BoxDecoration(
                color: isListening ? AppTheme.danger : AppTheme.accent,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              isListening ? 'STOP' : 'START',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: isListening ? AppTheme.danger : AppTheme.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, BleService ble, SessionService session) {
    if (session.activeSession == null) {
      return _buildNoSession(context, session);
    }
    return Column(
      children: [
        _buildLastTimeDisplay(session),
        _buildStatsBar(session),
        Expanded(child: _buildRecordsList(session)),
        _buildActionBar(context, ble, session),
      ],
    );
  }

  Widget _buildNoSession(BuildContext context, SessionService session) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer_outlined, size: 64, color: AppTheme.textMuted),
          const SizedBox(height: 24),
          const Text('No session active', style: TextStyle(fontSize: 16, color: AppTheme.textSecondary)),
          const SizedBox(height: 8),
          const Text('Create or select a session to start timing', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _showNewSession(context, session),
            icon: const Icon(Icons.add),
            label: const Text('NEW SESSION'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => _showSessionPicker(context, session),
            child: const Text('OPEN EXISTING', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, letterSpacing: 1)),
          ),
        ],
      ).animate().fadeIn(duration: 400.ms),
    );
  }

  Widget _buildLastTimeDisplay(SessionService session) {
    final last = session.liveRecords.isEmpty ? null : session.liveRecords.last;
    final best = session.activeSession?.bestTimeMs;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        final glowOpacity = (1 - _pulseController.value) * 0.6;
        return Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _pulseController.value > 0
                  ? AppTheme.accent.withOpacity(glowOpacity + 0.3)
                  : AppTheme.border,
              width: 1.5,
            ),
            boxShadow: _pulseController.value > 0 ? [
              BoxShadow(
                color: AppTheme.accent.withOpacity(glowOpacity * 0.5),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ] : null,
          ),
          child: Column(
            children: [
              Text(
                last != null ? TimeFormatter.format(last.durationMs) : '--:--.---',
                style: const TextStyle(
                  fontSize: 52,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.accent,
                  letterSpacing: 2,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              if (last != null) ...[
                const SizedBox(height: 4),
                Text(
                  last.athleteName != null ? '${last.athleteName} · Lane ${last.lane}' : 'Lane ${last.lane}',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, letterSpacing: 0.5),
                ),
              ],
              if (best != null && last != null && last.durationMs == best) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('BEST', style: TextStyle(fontSize: 10, color: AppTheme.accent, fontWeight: FontWeight.w700, letterSpacing: 2)),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsBar(SessionService session) {
    final s = session.activeSession!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _StatChip(label: 'RUNS', value: s.records.length.toString()),
          const SizedBox(width: 8),
          _StatChip(label: 'BEST', value: s.bestTimeMs != null ? TimeFormatter.formatShort(s.bestTimeMs!) : '--'),
          const SizedBox(width: 8),
          _StatChip(label: 'AVG', value: s.averageTimeMs != null ? TimeFormatter.formatShort(s.averageTimeMs!) : '--'),
        ],
      ),
    );
  }

  Widget _buildRecordsList(SessionService session) {
    final records = session.liveRecords.reversed.toList();
    if (records.isEmpty) {
      return const Center(
        child: Text('Waiting for times...', style: TextStyle(color: AppTheme.textMuted, fontSize: 13, letterSpacing: 0.5)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[index];
        final isNew = index == 0;
        return TimeCard(
          record: record,
          isNew: isNew,
          rank: records.length - index,
          isBest: record.durationMs == session.activeSession!.bestTimeMs,
          onDelete: () => session.deleteRecord(record.id),
        ).animate(key: ValueKey(record.id)).fadeIn(duration: 300.ms).slideY(begin: -0.1, end: 0);
      },
    );
  }

  Widget _buildActionBar(BuildContext context, BleService ble, SessionService session) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          if (ble.isMockMode) ...[
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => ble.simulateStartEvent(),
                icon: const Icon(Icons.play_arrow, size: 16),
                label: const Text('SIM START', style: TextStyle(fontSize: 11, letterSpacing: 1)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.warning,
                  side: const BorderSide(color: AppTheme.warning),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => ble.simulateFinishEvent(),
                icon: const Icon(Icons.flag, size: 16),
                label: const Text('SIM FINISH', style: TextStyle(fontSize: 11, letterSpacing: 1)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.accent,
                  side: const BorderSide(color: AppTheme.accent),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ] else ...[
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showManualEntry(context, session),
                icon: const Icon(Icons.keyboard, size: 16),
                label: const Text('MANUAL ENTRY', style: TextStyle(fontSize: 11, letterSpacing: 1)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.textSecondary,
                  side: const BorderSide(color: AppTheme.borderBright),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showSessionPicker(BuildContext context, SessionService session) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SessionPickerSheet(
        sessions: session.sessions,
        activeSession: session.activeSession,
        onSelect: (s) {
          session.setActiveSession(s);
          Navigator.pop(context);
        },
        onNew: () {
          Navigator.pop(context);
          _showNewSession(context, session);
        },
      ),
    );
  }

  void _showNewSession(BuildContext context, SessionService session) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => NewSessionSheet(
        onCreated: (s) => session.setActiveSession(s),
      ),
    );
  }

  void _showManualEntry(BuildContext context, SessionService session) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Manual Time Entry', style: TextStyle(fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter time in seconds (e.g. 10.534)', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              style: const TextStyle(fontSize: 24, color: AppTheme.accent, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
              decoration: const InputDecoration(hintText: '0.000', suffixText: 's'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL', style: TextStyle(color: AppTheme.textSecondary))),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(controller.text);
              if (val != null && val > 0) {
                session.addManualTime(durationMs: (val * 1000).round());
                Navigator.pop(ctx);
              }
            },
            child: const Text('ADD'),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontSize: 9, color: AppTheme.textMuted, letterSpacing: 1.5)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontFeatures: [FontFeature.tabularFigures()])),
          ],
        ),
      ),
    );
  }
}
