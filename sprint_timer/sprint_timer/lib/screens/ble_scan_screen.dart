import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';
import '../services/ble_service.dart';
import '../utils/app_theme.dart';

class BleScanScreen extends StatefulWidget {
  const BleScanScreen({super.key});

  @override
  State<BleScanScreen> createState() => _BleScanScreenState();
}

class _BleScanScreenState extends State<BleScanScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ble = context.read<BleService>();
      if (!ble.isConnected && !ble.isScanning) {
        ble.startScan();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BleService>(
      builder: (context, ble, _) {
        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            title: const Text('CONNECT CHIP'),
            actions: [
              if (ble.isConnected || ble.isMockMode)
                TextButton(
                  onPressed: () { ble.disconnect(); },
                  child: const Text('DISCONNECT', style: TextStyle(color: AppTheme.danger, fontSize: 11, letterSpacing: 1)),
                )
              else if (ble.isScanning)
                TextButton(
                  onPressed: () => ble.stopScan(),
                  child: const Text('STOP', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, letterSpacing: 1)),
                ),
            ],
          ),
          body: Column(
            children: [
              _buildStatusBanner(ble),
              Expanded(child: _buildBody(context, ble)),
              _buildSimulatorButton(context, ble),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusBanner(BleService ble) {
    Color color;
    String text;
    switch (ble.connectionState) {
      case BleConnectionState.connected:
        color = AppTheme.accent;
        text = 'Connected to ${ble.deviceName}';
      case BleConnectionState.scanning:
        color = AppTheme.warning;
        text = 'Scanning for devices...';
      case BleConnectionState.connecting:
        color = AppTheme.warning;
        text = 'Connecting...';
      case BleConnectionState.error:
        color = AppTheme.danger;
        text = 'Connection error';
      default:
        color = AppTheme.textMuted;
        text = ble.isMockMode ? 'Simulator active' : 'Disconnected';
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      color: color.withOpacity(0.1),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Text(text, style: TextStyle(color: color, fontSize: 13, letterSpacing: 0.5)),
          if (ble.isScanning) ...[
            const Spacer(),
            SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: color)),
          ],
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, BleService ble) {
    if (ble.isConnected) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bluetooth_connected, size: 64, color: AppTheme.accent),
            const SizedBox(height: 16),
            Text('Connected to ${ble.deviceName}', style: const TextStyle(fontSize: 16, color: AppTheme.textPrimary)),
            const SizedBox(height: 8),
            const Text('Ready to receive timing data', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('START TIMING'),
            ),
          ],
        ).animate().fadeIn(),
      );
    }

    if (ble.isMockMode) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.science_outlined, size: 64, color: AppTheme.warning),
            const SizedBox(height: 16),
            const Text('Simulator Active', style: TextStyle(fontSize: 16, color: AppTheme.textPrimary)),
            const SizedBox(height: 8),
            const Text('Use the SIM buttons on the timing screen\nto generate test events', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary), textAlign: TextAlign.center),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('GO TO TIMER'),
            ),
          ],
        ).animate().fadeIn(),
      );
    }

    if (ble.scanResults.isEmpty && !ble.isScanning) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bluetooth_searching, size: 56, color: AppTheme.textMuted),
            const SizedBox(height: 16),
            const Text('No devices found', style: TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 8),
            const Text('Make sure your timing chip is powered on\nand within range', style: TextStyle(color: AppTheme.textMuted, fontSize: 12), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => ble.startScan(),
              icon: const Icon(Icons.refresh),
              label: const Text('SCAN AGAIN'),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: ble.scanResults.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final result = ble.scanResults[index];
        return _DeviceTile(
          result: result,
          onConnect: () => ble.connectToDevice(result.device),
        ).animate().fadeIn(delay: (index * 50).ms);
      },
    );
  }

  Widget _buildSimulatorButton(BuildContext context, BleService ble) {
    if (ble.isConnected) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppTheme.border))),
      child: Column(
        children: [
          const Text('No real chip? Test with the simulator', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: ble.isMockMode ? null : () { ble.enableSimulator(); },
              icon: const Icon(Icons.science_outlined, size: 16),
              label: const Text('ENABLE SIMULATOR', style: TextStyle(fontSize: 11, letterSpacing: 1)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.warning,
                side: const BorderSide(color: AppTheme.warning),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeviceTile extends StatelessWidget {
  final ScanResult result;
  final VoidCallback onConnect;
  const _DeviceTile({required this.result, required this.onConnect});

  @override
  Widget build(BuildContext context) {
    final name = result.device.platformName.isEmpty ? 'Unknown Device' : result.device.platformName;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.bluetooth, color: AppTheme.accent, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                Text(result.device.remoteId.str, style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                Text('RSSI: ${result.rssi} dBm', style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onConnect,
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
            child: const Text('CONNECT', style: TextStyle(fontSize: 11, letterSpacing: 1)),
          ),
        ],
      ),
    );
  }
}
