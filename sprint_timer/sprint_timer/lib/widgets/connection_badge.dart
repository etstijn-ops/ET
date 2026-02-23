import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ble_service.dart';
import '../utils/app_theme.dart';

class ConnectionBadge extends StatelessWidget {
  const ConnectionBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BleService>(
      builder: (context, ble, _) {
        final connected = ble.isConnected || ble.isMockMode;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: connected ? AppTheme.accent.withOpacity(0.1) : AppTheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: connected ? AppTheme.accent.withOpacity(0.4) : AppTheme.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                width: 6, height: 6,
                decoration: BoxDecoration(
                  color: connected ? AppTheme.accent : AppTheme.textMuted,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Icon(
                ble.isMockMode ? Icons.science_outlined : Icons.bluetooth,
                size: 14,
                color: connected ? AppTheme.accent : AppTheme.textMuted,
              ),
            ],
          ),
        );
      },
    );
  }
}
