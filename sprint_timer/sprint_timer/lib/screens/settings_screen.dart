import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ble_service.dart';
import '../utils/app_theme.dart';
import 'ble_scan_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BleService>(
      builder: (context, ble, _) {
        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(title: const Text('SETTINGS')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _Section(title: 'DEVICE', children: [
                _Tile(
                  icon: Icons.bluetooth,
                  title: 'Timing Chip',
                  subtitle: ble.isConnected ? 'Connected: ${ble.deviceName}' : ble.isMockMode ? 'Simulator active' : 'Not connected',
                  trailing: Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(
                      color: (ble.isConnected || ble.isMockMode) ? AppTheme.accent : AppTheme.textMuted,
                      shape: BoxShape.circle,
                    ),
                  ),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BleScanScreen())),
                ),
              ]),

              const SizedBox(height: 16),
              _Section(title: 'PROTOCOL', children: [
                _InfoTile(label: 'Service UUID', value: '0000ABCD-...'),
                _InfoTile(label: 'Characteristic UUID', value: '0000ABCE-...'),
                _InfoTile(label: 'Packet Size', value: '8 bytes'),
                _InfoTile(label: 'Format', value: '[type][lane][ts×4][seq][crc]'),
              ]),

              const SizedBox(height: 16),
              _Section(title: 'EVENT CODES', children: [
                _InfoTile(label: '0x01', value: 'START trigger'),
                _InfoTile(label: '0x02', value: 'SPLIT gate'),
                _InfoTile(label: '0x03', value: 'FINISH trigger'),
                _InfoTile(label: '0xFF', value: 'HEARTBEAT'),
              ]),

              const SizedBox(height: 16),
              _Section(title: 'ABOUT', children: [
                _InfoTile(label: 'App', value: 'Sprint Timer v1.0'),
                _InfoTile(label: 'Protocol', value: 'BLE (GATT custom service)'),
                _InfoTile(label: 'Precision', value: '1ms'),
              ]),
            ],
          ),
        );
      },
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(title, style: const TextStyle(fontSize: 10, color: AppTheme.textMuted, letterSpacing: 2)),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  const _Tile({required this.icon, required this.title, required this.subtitle, this.trailing, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.accent, size: 22),
      title: Text(title, style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
      trailing: trailing ?? const Icon(Icons.chevron_right, color: AppTheme.textMuted, size: 18),
      onTap: onTap,
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  const _InfoTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
        ],
      ),
    );
  }
}
