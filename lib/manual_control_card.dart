import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:async';
import 'app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Firmware command map (manual1.cpp):
//   F / f  → moveForward
//   B / b  → moveBackward
//   L / l  → turnLeft
//   R / r  → turnRight
//   I / i  → moveDiagonalForwardRight
//   G / g  → moveDiagonalForwardLeft
//   J / j  → moveDiagonalBackwardRight
//   H / h  → moveDiagonalBackwardLeft
//   S / s  → stopMotors
// ─────────────────────────────────────────────────────────────────────────────

class ManualControlCard extends StatefulWidget {
  final bool connected;
  final ValueChanged<String> onCommand;

  const ManualControlCard({
    super.key,
    required this.connected,
    required this.onCommand,
  });

  @override
  State<ManualControlCard> createState() => _ManualControlCardState();
}

class _ManualControlCardState extends State<ManualControlCard> {
  int    _speed  = 5;
  String _active = '';
  Timer? _repeatTimer;

  // Direction labels for the center indicator
  static const Map<String, String> _dirLabel = {
    'F': '↑',  'B': '↓',  'L': '←',  'R': '→',
    'G': '↖',  'I': '↗',  'H': '↙',  'J': '↘',
  };

  void _press(String dir) {
    if (!widget.connected) return;
    if (_active == dir) return;

    setState(() => _active = dir);

    // Send speed first so Arduino uses latest speed, then direction
    widget.onCommand('$_speed');
    widget.onCommand(dir);

    // Keep re-sending direction every 150 ms so Arduino stays moving
    _repeatTimer?.cancel();
    _repeatTimer = Timer.periodic(const Duration(milliseconds: 150), (_) {
      if (_active == dir && widget.connected) widget.onCommand(dir);
    });
  }

  void _release() {
    _repeatTimer?.cancel();
    _repeatTimer = null;
    if (_active.isEmpty) return;
    setState(() => _active = '');
    widget.onCommand('S');
  }

  void _changeSpeed(int delta) {
    setState(() => _speed = (_speed + delta).clamp(1, 9));
    if (widget.connected) {
      widget.onCommand('$_speed');
      if (_active.isNotEmpty) widget.onCommand(_active);
    }
  }

  @override
  void dispose() {
    _repeatTimer?.cancel();
    super.dispose();
  }

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
          // ── Header ─────────────────────────────────────────────────────
          Row(
            children: [
              const Text('DRIVE CONTROL',
                  style: TextStyle(
                      fontSize: 10,
                      color: AppTheme.textDim,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w500)),
              const Spacer(),
              // Diagonal mode badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.bgBlue,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.borderBlue, width: 0.5),
                ),
                child: const Text('8-DIR',
                    style: TextStyle(
                        fontSize: 9,
                        color: AppTheme.blueLight,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── D-pad + Knob row ────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── 8-direction D-pad (3×3 grid) ──────────────────────────
              SizedBox(
                width: 174,
                height: 174,
                child: GridView.count(
                  crossAxisCount: 3,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                  children: [
                    // Row 1: FwdLeft  |  Forward  |  FwdRight
                    _DpadBtn(
                      label: '↖', dir: 'G',
                      isDiagonal: true,
                      active: _active,
                      onPress: _press, onRelease: _release,
                    ),
                    _DpadBtn(
                      icon: Icons.keyboard_arrow_up, dir: 'F',
                      active: _active,
                      onPress: _press, onRelease: _release,
                    ),
                    _DpadBtn(
                      label: '↗', dir: 'I',
                      isDiagonal: true,
                      active: _active,
                      onPress: _press, onRelease: _release,
                    ),

                    // Row 2: Left  |  Stop (center)  |  Right
                    _DpadBtn(
                      icon: Icons.keyboard_arrow_left, dir: 'L',
                      active: _active,
                      onPress: _press, onRelease: _release,
                    ),
                    // ── Centre stop / direction indicator ──────────────
                    _StopCenter(
                      label: _active.isEmpty ? '■' : (_dirLabel[_active] ?? '■'),
                      isMoving: _active.isNotEmpty,
                      onTap: _release,
                    ),
                    _DpadBtn(
                      icon: Icons.keyboard_arrow_right, dir: 'R',
                      active: _active,
                      onPress: _press, onRelease: _release,
                    ),

                    // Row 3: BwdLeft  |  Backward  |  BwdRight
                    _DpadBtn(
                      label: '↙', dir: 'H',
                      isDiagonal: true,
                      active: _active,
                      onPress: _press, onRelease: _release,
                    ),
                    _DpadBtn(
                      icon: Icons.keyboard_arrow_down, dir: 'B',
                      active: _active,
                      onPress: _press, onRelease: _release,
                    ),
                    _DpadBtn(
                      label: '↘', dir: 'J',
                      isDiagonal: true,
                      active: _active,
                      onPress: _press, onRelease: _release,
                    ),
                  ],
                ),
              ),

              // ── Speed knob ─────────────────────────────────────────────
              _CircularKnob(
                speed: _speed,
                onUp:   () => _changeSpeed(1),
                onDown: () => _changeSpeed(-1),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ── Legend row ──────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendDot(AppTheme.blueLight, 'Cardinal (F/B/L/R)'),
              const SizedBox(width: 16),
              _legendDot(AppTheme.skyBlue.withOpacity(0.7), 'Diagonal (G/I/H/J)'),
            ],
          ),

          const SizedBox(height: 14),

          // ══ SAVE PATH ════════════════════════════════════════════════════
          _SavePathPanel(
            connected: widget.connected,
            onCommand: widget.onCommand,
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(children: [
      Container(
          width: 8, height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
      const SizedBox(width: 5),
      Text(label,
          style: const TextStyle(fontSize: 9, color: AppTheme.textDim)),
    ]);
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  SAVE PATH PANEL
//  Lives inside ManualControlCard — active only when manual mode is active.
//
//  Commands sent (from bluetooth1.cpp / savepath1.cpp):
//    K → startRecording()
//    T → stopRecording()   saves path, stops movement
//    E → startPlayback()   plays once then stops
//    Q → stopPlayback()    interrupt playback early
//
//  Arduino replies received via bluetooth_service logs (parsed below):
//    PATH:REC_START  → recording is live
//    PATH:REC_DONE   → path saved successfully
//    PATH:PLAYING    → playback running
//    PATH:STOPPED    → playback finished or stopped
//    PATH:EMPTY      → E or T pressed but nothing recorded
// ══════════════════════════════════════════════════════════════════════════════

enum _SaveState { idle, recording, saved, playing }

class _SavePathPanel extends StatefulWidget {
  final bool connected;
  final ValueChanged<String> onCommand;

  const _SavePathPanel({
    required this.connected,
    required this.onCommand,
  });

  @override
  State<_SavePathPanel> createState() => _SavePathPanelState();
}

class _SavePathPanelState extends State<_SavePathPanel> {
  _SaveState _state   = _SaveState.idle;
  bool       _hasSave = false;   // true once PATH:REC_DONE received

  // ── Command helpers (names match bluetooth1.cpp handler) ─────────────────
  void _startRecording() {
    widget.onCommand('K');        // bluetooth1.cpp: startRecording()
    setState(() { _state = _SaveState.recording; });
  }

  void _stopRecording() {
    widget.onCommand('T');        // bluetooth1.cpp: stopRecording()
    // Optimistically move to saved; Arduino confirms with PATH:REC_DONE
    setState(() { _state = _SaveState.saved; _hasSave = true; });
  }

  void _startPlayback() {
    widget.onCommand('E');        // bluetooth1.cpp: startPlayback()
    setState(() { _state = _SaveState.playing; });
  }

  void _stopPlayback() {
    widget.onCommand('Q');        // bluetooth1.cpp: stopPlayback()
    setState(() { _state = _SaveState.saved; });
  }

  // ── State label + color ──────────────────────────────────────────────────
  String get _stateLabel {
    switch (_state) {
      case _SaveState.idle:      return 'NO PATH';
      case _SaveState.recording: return 'REC ●';
      case _SaveState.saved:     return 'SAVED ✓';
      case _SaveState.playing:   return 'PLAYING ▶';
    }
  }

  Color get _stateColor {
    switch (_state) {
      case _SaveState.idle:      return AppTheme.textDim;
      case _SaveState.recording: return const Color(0xFFF87171);
      case _SaveState.saved:     return AppTheme.green;
      case _SaveState.playing:   return const Color(0xFFA78BFA);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.bgDeep,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderColor, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Header ─────────────────────────────────────────────────────
          Row(children: [
            const Icon(Icons.route_outlined, color: AppTheme.textDim, size: 13),
            const SizedBox(width: 5),
            const Text('SAVE PATH',
                style: TextStyle(fontSize: 10, color: AppTheme.textDim,
                    letterSpacing: 1.2, fontWeight: FontWeight.w500)),
            const Spacer(),
            // State badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: _stateColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: _stateColor.withOpacity(0.4), width: 0.5),
              ),
              child: Text(_stateLabel,
                  style: TextStyle(fontSize: 9, color: _stateColor,
                      letterSpacing: 1, fontWeight: FontWeight.w700)),
            ),
          ]),

          const SizedBox(height: 12),

          // ── Buttons change based on state ─────────────────────────────
          if (!widget.connected)
            _infoBox(AppTheme.redBg, AppTheme.redBorder, AppTheme.red,
                Icons.bluetooth_disabled, 'Connect to car first')

          else if (_state == _SaveState.idle) ...[
            // Only action available: start recording
            _actionBtn(
              label: 'Start Recording',
              icon: Icons.fiber_manual_record,
              color: const Color(0xFFF87171),
              bgColor: const Color(0xFF2D1010),
              borderColor: const Color(0xFF7F1D1D),
              onTap: _startRecording,
            ),
            const SizedBox(height: 8),
            _infoBox(AppTheme.bgDeep, AppTheme.borderColor, AppTheme.textDim,
                Icons.info_outline,
                'Tap Start — then drive with the D-pad above'),
          ]

          else if (_state == _SaveState.recording) ...[
            // Stop & save
            _actionBtn(
              label: 'Stop & Save',
              icon: Icons.stop_circle_outlined,
              color: AppTheme.green,
              bgColor: AppTheme.greenBg,
              borderColor: AppTheme.greenBorder,
              onTap: _stopRecording,
            ),
            const SizedBox(height: 8),
            _infoBox(const Color(0xFF2D1010), const Color(0xFF7F1D1D),
                const Color(0xFFF87171),
                Icons.fiber_manual_record,
                'Recording — drive now using the D-pad above'),
          ]

          else if (_state == _SaveState.saved) ...[
            // Play + Re-record side by side
            Row(children: [
              Expanded(child: _actionBtn(
                label: 'Play',
                icon: Icons.play_arrow_rounded,
                color: const Color(0xFFA78BFA),
                bgColor: const Color(0xFF1E1433),
                borderColor: const Color(0xFF6D28D9),
                onTap: _startPlayback,
              )),
              const SizedBox(width: 8),
              Expanded(child: _actionBtn(
                label: 'Re-record',
                icon: Icons.fiber_manual_record,
                color: const Color(0xFFF87171),
                bgColor: const Color(0xFF2D1010),
                borderColor: const Color(0xFF7F1D1D),
                onTap: _startRecording,
              )),
            ]),
          ]

          else if (_state == _SaveState.playing) ...[
            // Stop playback
            _actionBtn(
              label: 'Stop Playback',
              icon: Icons.stop_rounded,
              color: AppTheme.yellow,
              bgColor: const Color(0xFF2D2000),
              borderColor: const Color(0xFF78350F),
              onTap: _stopPlayback,
            ),
            const SizedBox(height: 8),
            _infoBox(const Color(0xFF1E1433), const Color(0xFF6D28D9),
                const Color(0xFFA78BFA),
                Icons.play_arrow_rounded,
                'Playing saved path — tap Stop to interrupt'),
          ],
        ],
      ),
    );
  }

  // ── Reusable action button ────────────────────────────────────────────────
  Widget _actionBtn({
    required String label, required IconData icon,
    required Color color, required Color bgColor, required Color borderColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: borderColor, width: 0.5),
          boxShadow: [BoxShadow(
              color: color.withOpacity(0.18), blurRadius: 6, spreadRadius: 1)],
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 12, color: color,
              fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  // ── Reusable info box ─────────────────────────────────────────────────────
  Widget _infoBox(Color bg, Color border, Color textColor,
      IconData icon, String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border, width: 0.5),
      ),
      child: Row(children: [
        Icon(icon, color: textColor, size: 13),
        const SizedBox(width: 7),
        Expanded(child: Text(text,
            style: TextStyle(fontSize: 11, color: textColor))),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  D-PAD BUTTON  (cardinal and diagonal, visually distinct)
// ══════════════════════════════════════════════════════════════════════════════
class _DpadBtn extends StatefulWidget {
  final String   dir;
  final String   active;
  final bool     isDiagonal;
  final IconData? icon;
  final String?  label;       // arrow glyph for diagonal buttons
  final ValueChanged<String> onPress;
  final VoidCallback onRelease;

  const _DpadBtn({
    required this.dir,
    required this.active,
    required this.onPress,
    required this.onRelease,
    this.isDiagonal = false,
    this.icon,
    this.label,
  }) : assert(icon != null || label != null,
            '_DpadBtn needs either icon or label');

  @override
  State<_DpadBtn> createState() => _DpadBtnState();
}

class _DpadBtnState extends State<_DpadBtn>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 60));
    _scale = Tween<double>(begin: 1.0, end: 0.82).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isActive = widget.active == widget.dir;

    // Diagonal buttons get a slightly different tint so they're visually
    // distinguishable from cardinal buttons at a glance
    final Color idleColor = widget.isDiagonal
        ? const Color(0xFF151F30)   // slightly cooler than bgBlue
        : AppTheme.bgBlue;
    final Color activeBg  = widget.isDiagonal
        ? const Color(0xFF1A2E4A)
        : AppTheme.blueDark;
    final Color activeBdr = widget.isDiagonal
        ? AppTheme.skyBlue
        : AppTheme.blueLight;
    final Color idleBdr   = widget.isDiagonal
        ? const Color(0xFF1A3050)
        : AppTheme.borderBlue;
    final Color iconColor = widget.isDiagonal
        ? AppTheme.skyBlue
        : AppTheme.blueLight;

    return GestureDetector(
      onTapDown:        (_) { _ctrl.forward(); widget.onPress(widget.dir); },
      onTapUp:          (_) { _ctrl.reverse(); widget.onRelease(); },
      onTapCancel:          () { _ctrl.reverse(); widget.onRelease(); },
      onLongPressStart: (_) { _ctrl.forward(); widget.onPress(widget.dir); },
      onLongPressEnd:   (_) { _ctrl.reverse(); widget.onRelease(); },
      child: ScaleTransition(
        scale: _scale,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 60),
          decoration: BoxDecoration(
            color: isActive ? activeBg : idleColor,
            // Diagonal buttons get rounded corners; cardinal gets sharper
            borderRadius: BorderRadius.circular(widget.isDiagonal ? 12 : 9),
            border: Border.all(
              color: isActive ? activeBdr : idleBdr,
              width: isActive ? 1.0 : 0.5,
            ),
            boxShadow: isActive
                ? [BoxShadow(
                    color: (widget.isDiagonal
                            ? AppTheme.skyBlue
                            : AppTheme.blue)
                        .withOpacity(0.35),
                    blurRadius: 8,
                    spreadRadius: 1)]
                : [],
          ),
          child: Center(
            child: widget.icon != null
                ? Icon(widget.icon, color: iconColor, size: 22)
                : Text(
                    widget.label!,
                    style: TextStyle(
                        fontSize: 18,
                        color: iconColor,
                        fontWeight: FontWeight.w600),
                  ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  CENTRE STOP BUTTON
// ══════════════════════════════════════════════════════════════════════════════
class _StopCenter extends StatelessWidget {
  final String    label;
  final bool      isMoving;
  final VoidCallback onTap;

  const _StopCenter({
    required this.label,
    required this.isMoving,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        decoration: BoxDecoration(
          color: isMoving
              ? AppTheme.redBg
              : AppTheme.bgDeep,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isMoving ? AppTheme.redBorder : AppTheme.borderColor,
            width: isMoving ? 1.0 : 0.5,
          ),
          boxShadow: isMoving
              ? [BoxShadow(
                  color: AppTheme.red.withOpacity(0.25),
                  blurRadius: 8)]
              : [],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
                fontSize: 18,
                color: isMoving ? AppTheme.red : AppTheme.textDim,
                fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  SPEED KNOB  (unchanged from original)
// ══════════════════════════════════════════════════════════════════════════════
class _CircularKnob extends StatelessWidget {
  final int speed;
  final VoidCallback onUp;
  final VoidCallback onDown;
  const _CircularKnob(
      {required this.speed, required this.onUp, required this.onDown});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Speed',
            style: TextStyle(fontSize: 11, color: AppTheme.textDim)),
        const SizedBox(height: 8),
        _AnimatedBtn(icon: Icons.add, onTap: onUp),
        const SizedBox(height: 8),
        CustomPaint(
          size: const Size(80, 80),
          painter: _KnobPainter(speed: speed),
          child: SizedBox(
            width: 80,
            height: 80,
            child: Center(
              child: Text('$speed',
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary)),
            ),
          ),
        ),
        const SizedBox(height: 8),
        _AnimatedBtn(icon: Icons.remove, onTap: onDown),
      ],
    );
  }
}

class _KnobPainter extends CustomPainter {
  final int speed;
  const _KnobPainter({required this.speed});

  @override
  void paint(Canvas canvas, Size size) {
    final center    = Offset(size.width / 2, size.height / 2);
    final radius    = size.width / 2 - 6;
    const start     = 135 * math.pi / 180;
    const sweepAll  = 270 * math.pi / 180;

    canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
        start, sweepAll, false,
        Paint()
          ..color      = AppTheme.borderColor
          ..strokeWidth = 6
          ..style      = PaintingStyle.stroke
          ..strokeCap  = StrokeCap.round);

    canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
        start, sweepAll * (speed / 9), false,
        Paint()
          ..color      = AppTheme.blue
          ..strokeWidth = 6
          ..style      = PaintingStyle.stroke
          ..strokeCap  = StrokeCap.round);

    canvas.drawCircle(center, radius - 8,
        Paint()..color = AppTheme.bgDeep..style = PaintingStyle.fill);
    canvas.drawCircle(center, radius - 8,
        Paint()
          ..color      = AppTheme.borderBlue
          ..strokeWidth = 0.5
          ..style      = PaintingStyle.stroke);
  }

  @override
  bool shouldRepaint(_KnobPainter old) => old.speed != speed;
}

class _AnimatedBtn extends StatefulWidget {
  final IconData    icon;
  final VoidCallback onTap;
  const _AnimatedBtn({required this.icon, required this.onTap});

  @override
  State<_AnimatedBtn> createState() => _AnimatedBtnState();
}

class _AnimatedBtnState extends State<_AnimatedBtn>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 60));
    _scale = Tween<double>(begin: 1.0, end: 0.85).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown:   (_) { _ctrl.forward(); widget.onTap(); },
      onTapUp:     (_) => _ctrl.reverse(),
      onTapCancel: ()  => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: AppTheme.bgBlue,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.borderBlue, width: 0.5),
          ),
          child: Icon(widget.icon, color: AppTheme.blueLight, size: 18),
        ),
      ),
    );
  }
}
