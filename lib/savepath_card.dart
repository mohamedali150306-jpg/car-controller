import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'bluetooth_service.dart';

class SavePathCard extends StatelessWidget {
  final bool             connected;
  final BluetoothService bt;

  const SavePathCard({
    super.key,
    required this.connected,
    required this.bt,
  });

  void _startRecording() => bt.send('K');
  void _stopAndPlay()    => bt.send('E');
  void _stopPlayback()   => bt.send('Q');

  @override
  Widget build(BuildContext context) {
    final state = bt.pathState;

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
          Row(children: [
            const Text('SAVE PATH',
                style: TextStyle(fontSize: 10, color: AppTheme.textDim,
                    letterSpacing: 1.2, fontWeight: FontWeight.w500)),
            const Spacer(),
            _StateBadge(state: state),
          ]),
          const SizedBox(height: 14),
          _StepRow(currentState: state),
          const SizedBox(height: 16),
          _StateDescription(state: state, connected: connected),
          const SizedBox(height: 14),
          if (!connected)
            _InfoBox(
              color: AppTheme.redBg, border: AppTheme.redBorder,
              icon: Icons.bluetooth_disabled,
              text: 'Connect to the car first to use Save Path.',
              textColor: AppTheme.red,
            )
          else ...[
            if (state == PathState.idle)
              _ActionBtn(
                label: 'Start Recording',
                icon: Icons.fiber_manual_record,
                color: const Color(0xFFF87171),
                bgColor: const Color(0xFF3B1A1A),
                borderColor: const Color(0xFF7F1D1D),
                onTap: _startRecording,
              ),
            if (state == PathState.recording) ...[
              _ActionBtn(
                label: 'Stop & Play Loop',
                icon: Icons.stop_circle_outlined,
                color: const Color(0xFFA78BFA),
                bgColor: const Color(0xFF1E1433),
                borderColor: const Color(0xFF6D28D9),
                onTap: _stopAndPlay,
              ),
              const SizedBox(height: 8),
              _InfoBox(
                color: AppTheme.redBg, border: AppTheme.redBorder,
                icon: Icons.info_outline,
                text: 'Drive the car now — every move is being recorded.',
                textColor: AppTheme.red,
              ),
            ],
            if (state == PathState.playing) ...[
              _ActionBtn(
                label: 'Stop Playback',
                icon: Icons.stop,
                color: AppTheme.yellow,
                bgColor: const Color(0xFF2D2000),
                borderColor: const Color(0xFF78350F),
                onTap: _stopPlayback,
              ),
              const SizedBox(height: 8),
              _RunningBar(),
            ],
          ],
        ],
      ),
    );
  }
}

// ── State badge ───────────────────────────────────────────────────────────────
class _StateBadge extends StatelessWidget {
  final PathState state;
  const _StateBadge({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (state) {
      case PathState.idle:
        color = AppTheme.textDim; label = 'IDLE'; break;
      case PathState.recording:
        color = const Color(0xFFF87171); label = 'REC ●'; break;
      case PathState.playing:
        color = const Color(0xFFA78BFA); label = 'PLAYING ▶'; break;
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

// ── Step row — NO record syntax, uses List of Maps instead ───────────────────
class _StepRow extends StatelessWidget {
  final PathState currentState;
  const _StepRow({super.key, required this.currentState});

  @override
  Widget build(BuildContext context) {
    final int activeStep = currentState == PathState.idle
        ? -1
        : currentState == PathState.recording ? 0 : 1;

    final steps = <Map<String, dynamic>>[
      {'icon': Icons.fiber_manual_record,  'label': 'Record'},
      {'icon': Icons.play_circle_outline,  'label': 'Loop Play'},
      {'icon': Icons.stop_circle_outlined, 'label': 'Stop'},
    ];

    return Row(
      children: List.generate(5, (i) {
        if (i.isOdd) {
          final lineIdx = i ~/ 2;
          final done = activeStep > lineIdx;
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              height: 2,
              margin: const EdgeInsets.only(bottom: 20),
              color: done ? const Color(0xFFA78BFA) : AppTheme.borderColor,
            ),
          );
        }
        final idx    = i ~/ 2;
        final active = activeStep == idx;
        final done   = activeStep > idx;

        Color bg, border, fg;
        if (active) {
          bg = const Color(0xFF1E1433);
          border = const Color(0xFFA78BFA);
          fg = const Color(0xFFA78BFA);
        } else if (done) {
          bg = AppTheme.greenBg; border = AppTheme.greenBorder; fg = AppTheme.green;
        } else {
          bg = AppTheme.bgDeep; border = AppTheme.borderColor; fg = AppTheme.textDim;
        }

        return Column(children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: bg, shape: BoxShape.circle,
              border: Border.all(color: border, width: active ? 2.0 : 1.5),
              boxShadow: active ? [
                BoxShadow(color: const Color(0xFFA78BFA).withOpacity(0.4),
                    blurRadius: 8, spreadRadius: 1)
              ] : [],
            ),
            child: Icon(steps[idx]['icon'] as IconData, size: 15, color: fg),
          ),
          const SizedBox(height: 4),
          Text(steps[idx]['label'] as String,
              style: TextStyle(fontSize: 9, color: fg,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400)),
        ]);
      }),
    );
  }
}

// ── State description ─────────────────────────────────────────────────────────
class _StateDescription extends StatelessWidget {
  final PathState state;
  final bool connected;
  const _StateDescription({super.key, required this.state, required this.connected});

  @override
  Widget build(BuildContext context) {
    String text;
    switch (state) {
      case PathState.idle:
        text = connected
            ? 'Press "Start Recording", then drive the car manually.\n'
              'When done, press "Stop & Play Loop" to repeat your path.'
            : 'Connect via Bluetooth to use the Save Path feature.';
        break;
      case PathState.recording:
        text = 'Recording — drive the car now.\n'
               'Press "Stop & Play Loop" when finished.';
        break;
      case PathState.playing:
        text = 'Playback loop is running.\n'
               'Press "Stop Playback" to end the loop.';
        break;
    }
    return Text(text,
        style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, height: 1.6));
  }
}

// ── Running bar ───────────────────────────────────────────────────────────────
class _RunningBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1433),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: const Color(0xFF6D28D9).withOpacity(0.5), width: 0.5),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(width: 12, height: 12,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: Color(0xFFA78BFA))),
          SizedBox(width: 8),
          Text('Path loop running...',
              style: TextStyle(fontSize: 12, color: Color(0xFFA78BFA),
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ── Action button ─────────────────────────────────────────────────────────────
class _ActionBtn extends StatefulWidget {
  final String   label;
  final IconData icon;
  final Color    color, bgColor, borderColor;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.label, required this.icon,
    required this.color, required this.bgColor,
    required this.borderColor, required this.onTap,
  });

  @override
  State<_ActionBtn> createState() => _ActionBtnState();
}

class _ActionBtnState extends State<_ActionBtn>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 60));
    _scale = Tween<double>(begin: 1.0, end: 0.95).animate(
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
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: widget.bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: widget.borderColor, width: 0.5),
            boxShadow: [BoxShadow(color: widget.color.withOpacity(0.2),
                blurRadius: 8, spreadRadius: 1)],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, color: widget.color, size: 16),
              const SizedBox(width: 6),
              Text(widget.label,
                  style: TextStyle(fontSize: 12, color: widget.color,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Info box ──────────────────────────────────────────────────────────────────
class _InfoBox extends StatelessWidget {
  final Color    color, border, textColor;
  final IconData icon;
  final String   text;
  const _InfoBox({
    required this.color, required this.border,
    required this.icon, required this.text, required this.textColor,
  });

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
