import 'package:flutter/material.dart';
import 'app_theme.dart';

class AutonomousCard extends StatelessWidget {
  final bool active;
  const AutonomousCard({super.key, required this.active});

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
          const Text('AUTONOMOUS NAVIGATION',
              style: TextStyle(fontSize: 10, color: AppTheme.textDim,
                  letterSpacing: 1.2, fontWeight: FontWeight.w500)),
          const SizedBox(height: 12),
          Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: AppTheme.greenBg,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.greenBorder, width: 1.5),
              ),
              child: const Icon(Icons.radar, color: AppTheme.green, size: 18),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  active ? 'Active — obstacle avoidance on' : 'Standby',
                  style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                const Text('Scanning with ultrasonic sensors',
                  style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
              ],
            ),
          ]),
          const SizedBox(height: 12),
          // Animated wave indicator
          _WaveBar(active: active),
        ],
      ),
    );
  }
}

class _WaveBar extends StatefulWidget {
  final bool active;
  const _WaveBar({required this.active});

  @override
  State<_WaveBar> createState() => _WaveBarState();
}

class _WaveBarState extends State<_WaveBar> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.2, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) return const SizedBox.shrink();
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Row(
        children: List.generate(20, (i) {
          final h = 4.0 + ((i % 5) * 3.0) * _anim.value;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: Container(
                height: h,
                decoration: BoxDecoration(
                color: AppTheme.green.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
