import 'package:flutter/material.dart';
import 'app_theme.dart';

class SensorCard extends StatelessWidget {
  final int left;
  final int front;
  final int right;
  final bool connected;

  const SensorCard({
    super.key,
    required this.left,
    required this.front,
    required this.right,
    required this.connected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ULTRASONIC SENSORS (cm)',
              style: TextStyle(fontSize: 10, color: AppTheme.textDim,
                  letterSpacing: 1.2, fontWeight: FontWeight.w500)),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _SensorCell(
              icon: Icons.arrow_back,
              label: 'Left',
              value: connected ? left : null,
            )),
            const SizedBox(width: 8),
            Expanded(child: _SensorCell(
              icon: Icons.arrow_upward,
              label: 'Front',
              value: connected ? front : null,
              warn: connected && front < 25,
            )),
            const SizedBox(width: 8),
            Expanded(child: _SensorCell(
              icon: Icons.arrow_forward,
              label: 'Right',
              value: connected ? right : null,
            )),
          ]),
        ],
      ),
    );
  }
}

class _SensorCell extends StatelessWidget {
  final IconData icon;
  final String   label;
  final int?     value;
  final bool     warn;

  const _SensorCell({
    required this.icon,
    required this.label,
    required this.value,
    this.warn = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = warn ? AppTheme.red : AppTheme.skyBlue;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: AppTheme.bgDeep,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderColor, width: 0.5),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 4),
          Text(label,
            style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
          const SizedBox(height: 2),
          Text(
            value != null ? '$value' : '—',
            style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w500,
              color: value != null ? (warn ? AppTheme.red : AppTheme.textPrimary)
                                   : AppTheme.textDim,
            ),
          ),
          const Text('cm',
            style: TextStyle(fontSize: 9, color: AppTheme.textMuted)),
        ],
      ),
    );
  }
}
