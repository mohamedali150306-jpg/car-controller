import 'package:flutter/material.dart';
import 'app_theme.dart';

// savePath removed — only 3 modes remain
enum CarMode { manual, autonomous, autoParking }

class ModeCard extends StatelessWidget {
  final CarMode current;
  final CarMode? activeMode;
  final ValueChanged<CarMode> onChanged;
  final VoidCallback onActivate;

  const ModeCard({
    super.key,
    required this.current,
    required this.activeMode,
    required this.onChanged,
    required this.onActivate,
  });

  @override
  Widget build(BuildContext context) {
    final isAlreadyActive = current == activeMode;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('OPERATING MODE',
              style: TextStyle(fontSize: 10, color: AppTheme.textDim,
                  letterSpacing: 1.2, fontWeight: FontWeight.w500)),
          const SizedBox(height: 10),

          Row(children: [
            _ModeBtn(
              label: 'Manual',
              icon: Icons.sports_esports_outlined,
              selected: current == CarMode.manual,
              active: activeMode == CarMode.manual,
              onTap: () => onChanged(CarMode.manual),
            ),
            const SizedBox(width: 6),
            _ModeBtn(
              label: 'Autonomous',
              icon: Icons.directions_car_outlined,
              selected: current == CarMode.autonomous,
              active: activeMode == CarMode.autonomous,
              onTap: () => onChanged(CarMode.autonomous),
            ),
            const SizedBox(width: 6),
            _ModeBtn(
              label: 'Auto-Park',
              icon: Icons.local_parking_outlined,
              selected: current == CarMode.autoParking,
              active: activeMode == CarMode.autoParking,
              onTap: () => onChanged(CarMode.autoParking),
            ),
          ]),

          const SizedBox(height: 12),

          _ActivateBtn(
            isAlreadyActive: isAlreadyActive,
            mode: current,
            onTap: onActivate,
          ),
        ],
      ),
    );
  }
}

class _ModeBtn extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final bool active;
  final VoidCallback onTap;

  const _ModeBtn({
    required this.label, required this.icon,
    required this.selected, required this.active, required this.onTap,
  });

  @override
  State<_ModeBtn> createState() => _ModeBtnState();
}

class _ModeBtnState extends State<_ModeBtn> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 80));
    _scale = Tween<double>(begin: 1.0, end: 0.88)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTapDown:   (_) => _ctrl.forward(),
        onTapUp:     (_) { _ctrl.reverse(); widget.onTap(); },
        onTapCancel: ()  => _ctrl.reverse(),
        child: ScaleTransition(
          scale: _scale,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            decoration: BoxDecoration(
              color: widget.active ? AppTheme.greenBg
                  : widget.selected ? AppTheme.bgBlueDark
                  : AppTheme.bgDeep,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: widget.active ? AppTheme.greenBorder
                    : widget.selected ? AppTheme.blueDark
                    : AppTheme.borderColor,
                width: widget.active ? 1.5 : 0.5,
              ),
              boxShadow: widget.active
                  ? [BoxShadow(color: AppTheme.green.withOpacity(0.3), blurRadius: 8, spreadRadius: 1)]
                  : widget.selected
                      ? [BoxShadow(color: AppTheme.blueLight.withOpacity(0.2), blurRadius: 6, spreadRadius: 1)]
                      : [],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(clipBehavior: Clip.none, children: [
                  Icon(widget.icon, size: 20,
                      color: widget.active ? AppTheme.green
                          : widget.selected ? AppTheme.blueLight
                          : AppTheme.textMuted),
                  if (widget.active)
                    Positioned(
                      right: -4, top: -4,
                      child: Container(
                        width: 7, height: 7,
                        decoration: const BoxDecoration(
                            color: AppTheme.green, shape: BoxShape.circle),
                      ),
                    ),
                ]),
                const SizedBox(height: 4),
                Text(widget.label,
                    style: TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w500,
                        color: widget.active ? AppTheme.green
                            : widget.selected ? AppTheme.blueLight
                            : AppTheme.textMuted)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActivateBtn extends StatefulWidget {
  final bool isAlreadyActive;
  final CarMode mode;
  final VoidCallback onTap;

  const _ActivateBtn({required this.isAlreadyActive, required this.mode, required this.onTap});

  @override
  State<_ActivateBtn> createState() => _ActivateBtnState();
}

class _ActivateBtnState extends State<_ActivateBtn> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 60));
    _scale = Tween<double>(begin: 1.0, end: 0.95)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  String get _modeLabel {
    switch (widget.mode) {
      case CarMode.manual:      return 'Manual';
      case CarMode.autonomous:  return 'Autonomous';
      case CarMode.autoParking: return 'Auto-Park';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) { setState(() => _pressed = true); _ctrl.forward(); widget.onTap(); },
      onTapUp:   (_) { setState(() => _pressed = false); _ctrl.reverse(); },
      onTapCancel: () { setState(() => _pressed = false); _ctrl.reverse(); },
      child: ScaleTransition(
        scale: _scale,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: widget.isAlreadyActive ? AppTheme.greenBg
                : _pressed ? AppTheme.blueDark : AppTheme.bgBlue,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: widget.isAlreadyActive ? AppTheme.greenBorder
                  : _pressed ? AppTheme.blueLight : AppTheme.borderBlue,
              width: 0.5,
            ),
            boxShadow: [BoxShadow(
              color: widget.isAlreadyActive
                  ? AppTheme.green.withOpacity(0.25)
                  : AppTheme.blue.withOpacity(0.2),
              blurRadius: 8, spreadRadius: 1,
            )],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.isAlreadyActive ? Icons.check_circle : Icons.rocket_launch,
                color: widget.isAlreadyActive ? AppTheme.green : AppTheme.blueLight,
                size: 15,
              ),
              const SizedBox(width: 6),
              Text(
                widget.isAlreadyActive
                    ? '$_modeLabel mode is active'
                    : 'Activate $_modeLabel mode',
                style: TextStyle(
                    fontSize: 12,
                    color: widget.isAlreadyActive ? AppTheme.green : AppTheme.blueLight,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
