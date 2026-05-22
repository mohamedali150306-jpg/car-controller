import 'package:flutter/material.dart';
import 'app_theme.dart';

class BatteryCard extends StatelessWidget {
  final int pct;
  final double volts;
  final bool connected;

  const BatteryCard({
    super.key,
    required this.pct,
    required this.volts,
    required this.connected,
  });

  Color get _fillColor {
    if (pct > 50) return AppTheme.green;
    if (pct > 20) return AppTheme.yellow;
    return AppTheme.red;
  }

  String get _statusText {
    if (!connected) return '—';
    if (pct > 50) return 'Normal';
    if (pct > 20) return 'Low';
    return 'Critical';
  }

  Color get _statusColor {
    if (!connected) return AppTheme.textMuted;
    if (pct > 50) return AppTheme.green;
    if (pct > 20) return AppTheme.yellow;
    return AppTheme.red;
  }

  @override
  Widget build(BuildContext context) {
    final displayPct = connected ? pct : 0;
    final displayV   = connected ? volts : 0.0;

    return _Card(
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: label + percentage
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.battery_charging_full,
                          size: 13, color: AppTheme.textMuted),
                      const SizedBox(width: 4),
                      const Text('Battery',
                          style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                    ]),
                    const SizedBox(height: 2),
                    Text('$displayPct%',
                      style: const TextStyle(
                        fontSize: 26, fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary)),
                  ],
                ),
              ),
              // Right: volts + status
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${displayV.toStringAsFixed(1)} V',
                      style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                  const SizedBox(height: 2),
                  Text(_statusText,
                      style: TextStyle(fontSize: 11, color: _statusColor)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: connected ? displayPct / 100 : 0,
              minHeight: 8,
              backgroundColor: AppTheme.borderColor,
              valueColor: AlwaysStoppedAnimation(_fillColor),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared card shell ─────────────────────────────────────────────────────
class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor, width: 0.5),
      ),
      child: child,
    );
  }
}
