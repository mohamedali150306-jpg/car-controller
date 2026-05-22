import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'bluetooth_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ParkingCard — fully driven by real Arduino PARK:x messages.
// No fake timers. Every phase change comes from the car via bluetooth_service.
//
// Arduino sends (autopark1.cpp):
//   PARK:1  → Scanning for slot
//   PARK:2  → Positioning (approaching)
//   PARK:3  → Maneuvering
//   PARK:4  → Done ✓
//   PARK:5  → Failed ✗
// ─────────────────────────────────────────────────────────────────────────────

class ParkingCard extends StatefulWidget {
  final bool connected;
  final BluetoothService bt;

  const ParkingCard({super.key, required this.connected, required this.bt});

  @override
  State<ParkingCard> createState() => ParkingCardState();
}

class ParkingCardState extends State<ParkingCard> {
  bool _started = false;

  // Phase labels and icons (index 0 = stepper dot 1, etc.)
  static const _labels = ['Scan', 'Approach', 'Maneuver', 'Done'];
  static const _icons  = [
    Icons.radar_outlined,
    Icons.arrow_forward_outlined,
    Icons.rotate_right_outlined,
    Icons.check_circle_outline,
  ];
  static const _status = [
    '',
    'Scanning for slot...',
    'Approaching slot...',
    'Executing maneuver...',
    'Parking complete ✓',
    'Parking failed ✗',
  ];

  @override
  void initState() {
    super.initState();
    widget.bt.addListener(_onBtUpdate);
  }

  @override
  void dispose() {
    widget.bt.removeListener(_onBtUpdate);
    super.dispose();
  }

  // Rebuild whenever bt.parkingPhase changes — no timers needed
  void _onBtUpdate() {
    if (mounted) setState(() {});
  }

  // Called by home_screen when user presses Activate Auto-Park
  void startParking() {
    if (!widget.connected || _started) return;
    setState(() => _started = true);
    // Arduino starts sending PARK:1,2,3,4/5 automatically
    // bt.parkingPhase is updated by bluetooth_service._parseLine()
  }

  void _reset() {
    setState(() => _started = false);
    widget.bt.send('m');  // back to manual, stops motors
  }

  @override
  Widget build(BuildContext context) {
    // Use the real phase from Arduino — not a local counter
    final phase     = _started ? widget.bt.parkingPhase : 0;
    final isRunning = phase > 0 && phase < 4;
    final isDone    = phase == 4;
    final isFailed  = phase == 5;

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

          // ── Header ───────────────────────────────────────────────────────
          Row(children: [
            const Text('PARKING SEQUENCE',
                style: TextStyle(fontSize: 10, color: AppTheme.textDim,
                    letterSpacing: 1.2, fontWeight: FontWeight.w500)),
            const Spacer(),
            // Live phase badge
            if (_started)
              _PhaseBadge(phase: phase),
          ]),

          const SizedBox(height: 14),

          // ── Phase stepper ─────────────────────────────────────────────────
          Row(
            children: List.generate(7, (i) {
              if (i.isOdd) {
                final lineIdx = i ~/ 2;
                final done    = phase > lineIdx + 1;
                return Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    height: 2,
                    color: done ? AppTheme.green : AppTheme.borderColor,
                    margin: const EdgeInsets.only(bottom: 20),
                  ),
                );
              }
              final idx    = i ~/ 2;
              final active = phase == idx + 1;
              final done   = phase > idx + 1 || (isDone && idx == 3);
              return _Dot(
                icon:   _icons[idx],
                label:  _labels[idx],
                active: active,
                done:   done,
                failed: isFailed && idx == (phase - 1).clamp(0, 3),
              );
            }),
          ),

          const SizedBox(height: 8),

          // ── Status text ───────────────────────────────────────────────────
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              phase < _status.length ? _status[phase] : '',
              key: ValueKey(phase),
              style: TextStyle(
                fontSize: 11,
                color: isDone   ? AppTheme.green
                     : isFailed ? AppTheme.red
                     : AppTheme.textMuted,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── Bottom action area ────────────────────────────────────────────
          if (!widget.connected)
            _InfoBox(
              color: AppTheme.redBg, border: AppTheme.redBorder,
              icon: Icons.bluetooth_disabled,
              text: 'Connect to car first, then activate Auto-Park mode',
              textColor: AppTheme.red,
            )
          else if (!_started)
            _InfoBox(
              color: AppTheme.bgBlue, border: AppTheme.borderBlue,
              icon: Icons.info_outline,
              text: 'Press "Activate Auto-Park mode" above to start parking',
              textColor: AppTheme.blueLight,
            )
          else if (isRunning)
            _RunningBar(phase: phase)
          else if (isDone)
            _StatusBar(
              color: AppTheme.greenBg, border: AppTheme.greenBorder,
              icon: Icons.check_circle, text: 'Parking Complete ✓',
              textColor: AppTheme.green, onReset: _reset,
            )
          else if (isFailed)
            _StatusBar(
              color: AppTheme.redBg, border: AppTheme.redBorder,
              icon: Icons.error_outline, text: 'Parking Failed — Tap to Retry',
              textColor: AppTheme.red, onReset: _reset,
            )
          else
            // Started but waiting for first PARK:1 from Arduino
            _InfoBox(
              color: AppTheme.bgBlue, border: AppTheme.borderBlue,
              icon: Icons.hourglass_top,
              text: 'Waiting for car to start scanning...',
              textColor: AppTheme.blueLight,
            ),
        ],
      ),
    );
  }
}

// ── Live phase badge ──────────────────────────────────────────────────────────
class _PhaseBadge extends StatelessWidget {
  final int phase;
  const _PhaseBadge({required this.phase});

  @override
  Widget build(BuildContext context) {
    Color  color;
    String label;
    switch (phase) {
      case 1:  color = AppTheme.blueLight; label = 'SCANNING';    break;
      case 2:  color = AppTheme.yellow;    label = 'APPROACHING'; break;
      case 3:  color = AppTheme.yellow;    label = 'MANEUVERING'; break;
      case 4:  color = AppTheme.green;     label = 'DONE ✓';      break;
      case 5:  color = AppTheme.red;       label = 'FAILED ✗';    break;
      default: color = AppTheme.textDim;   label = 'WAITING';     break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.4), width: 0.5),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 9, color: color,
              letterSpacing: 1, fontWeight: FontWeight.w700)),
    );
  }
}

// ── Phase dot ─────────────────────────────────────────────────────────────────
class _Dot extends StatefulWidget {
  final IconData icon;
  final String   label;
  final bool     active;
  final bool     done;
  final bool     failed;
  const _Dot({required this.icon, required this.label,
    required this.active, required this.done, required this.failed});

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 700));
    _scale = Tween<double>(begin: 1.0, end: 1.2).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    if (widget.active) _ctrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_Dot old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) {
      _ctrl.repeat(reverse: true);
    } else if (!widget.active) {
      _ctrl.stop(); _ctrl.reset();
    }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    Color bg, border, fg;
    if (widget.failed) {
      bg = AppTheme.redBg;     border = AppTheme.redBorder;   fg = AppTheme.red;
    } else if (widget.done) {
      bg = AppTheme.greenBg;   border = AppTheme.greenBorder; fg = AppTheme.green;
    } else if (widget.active) {
      bg = AppTheme.bgBlueDark; border = AppTheme.blueLight;  fg = AppTheme.blueLight;
    } else {
      bg = AppTheme.bgDeep;    border = AppTheme.borderColor; fg = AppTheme.textDim;
    }

    return Column(children: [
      ScaleTransition(
        scale: widget.active ? _scale : const AlwaysStoppedAnimation(1.0),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: bg, shape: BoxShape.circle,
            border: Border.all(color: border,
                width: widget.active ? 2.0 : 1.5),
            boxShadow: widget.active ? [
              BoxShadow(color: AppTheme.blue.withOpacity(0.5),
                  blurRadius: 8, spreadRadius: 1)
            ] : widget.done ? [
              BoxShadow(color: AppTheme.green.withOpacity(0.3),
                  blurRadius: 6, spreadRadius: 1)
            ] : [],
          ),
          child: Icon(widget.icon, size: 15, color: fg),
        ),
      ),
      const SizedBox(height: 4),
      Text(widget.label,
        style: TextStyle(fontSize: 9, color: fg,
            fontWeight: widget.active ? FontWeight.w600 : FontWeight.w400)),
    ]);
  }
}

// ── Running bar with phase label ──────────────────────────────────────────────
class _RunningBar extends StatelessWidget {
  final int phase;
  const _RunningBar({required this.phase});

  String get _label {
    switch (phase) {
      case 1:  return 'Scanning for parking slot...';
      case 2:  return 'Approaching slot...';
      case 3:  return 'Executing parking maneuver...';
      default: return 'Parking in progress...';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.bgBlueDark,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderBlue, width: 0.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(width: 12, height: 12,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: AppTheme.blueLight)),
          const SizedBox(width: 8),
          Text(_label,
            style: const TextStyle(fontSize: 12, color: AppTheme.blueLight,
                fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ── Info box ──────────────────────────────────────────────────────────────────
class _InfoBox extends StatelessWidget {
  final Color color, border, textColor;
  final IconData icon;
  final String text;
  const _InfoBox({required this.color, required this.border,
    required this.icon, required this.text, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border, width: 0.5),
      ),
      child: Row(children: [
        Icon(icon, color: textColor, size: 14),
        const SizedBox(width: 8),
        Expanded(child: Text(text,
            style: TextStyle(fontSize: 11, color: textColor))),
      ]),
    );
  }
}

// ── Status bar with reset button ──────────────────────────────────────────────
class _StatusBar extends StatelessWidget {
  final Color color, border, textColor;
  final IconData icon;
  final String text;
  final VoidCallback onReset;
  const _StatusBar({required this.color, required this.border,
    required this.icon, required this.text,
    required this.textColor, required this.onReset});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onReset,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: border, width: 0.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor, size: 16),
            const SizedBox(width: 6),
            Text(text, style: TextStyle(fontSize: 12,
                color: textColor, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
