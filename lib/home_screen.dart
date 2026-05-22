import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'bluetooth_service.dart';
import 'bt_picker_dialog.dart';
import 'battery_card.dart';
import 'mode_card.dart';
import 'manual_control_card.dart';
import 'autonomous_card.dart';
import 'parking_card.dart';
import 'sensor_card.dart';
import 'log_card.dart';
// savepath_card.dart removed

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _bt         = BluetoothService();
  final _parkingKey = GlobalKey<ParkingCardState>();

  CarMode  _selected   = CarMode.manual;
  CarMode? _activeMode;

  @override
  void initState() {
    super.initState();
    _bt.addListener(_rebuild);
  }

  void _rebuild() => setState(() {});

  @override
  void dispose() {
    _bt.removeListener(_rebuild);
    _bt.dispose();
    super.dispose();
  }

  Future<void> _toggleBt() async {
    if (_bt.state == BtState.connected) {
      await _bt.disconnect();
      setState(() => _activeMode = null);
      return;
    }
    final device = await showDialog(
      context: context,
      builder: (_) => BtPickerDialog(bt: _bt),
    );
    if (device != null) await _bt.connect(device);
  }

  void _onModeSelected(CarMode m) => setState(() => _selected = m);

  void _onActivate() {
    setState(() => _activeMode = _selected);
    switch (_selected) {
      case CarMode.manual:
        _bt.send('m');    // firmware: currentMode='M', stopMotors()
        break;
      case CarMode.autonomous:
        _bt.send('X');    // firmware: currentMode='A'
        break;
      case CarMode.autoParking:
        _bt.send('P');    // firmware: currentMode='P'
        _parkingKey.currentState?.startParking();
        break;
    }
  }

  void _onCommand(String cmd) => _bt.send(cmd);

  @override
  Widget build(BuildContext context) {
    final connected  = _bt.state == BtState.connected;
    final connecting = _bt.state == BtState.connecting;

    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(
              connected:  connected,
              connecting: connecting,
              deviceName: _bt.deviceName,
              onBtTap:    _toggleBt,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
                children: [
                  BatteryCard(
                    pct:       _bt.batteryPct,
                    volts:     _bt.batteryVolts,
                    connected: connected,
                  ),
                  const SizedBox(height: 10),
                  ModeCard(
                    current:    _selected,
                    activeMode: _activeMode,
                    onChanged:  _onModeSelected,
                    onActivate: _onActivate,
                  ),
                  const SizedBox(height: 10),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _modePanel(connected),
                  ),
                  const SizedBox(height: 10),
                  SensorCard(
                    left:      _bt.sensorLeft,
                    front:     _bt.sensorFront,
                    right:     _bt.sensorRight,
                    connected: connected,
                  ),
                  const SizedBox(height: 10),
                  LogCard(logs: _bt.logs),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _modePanel(bool connected) {
    switch (_selected) {
      case CarMode.manual:
        return ManualControlCard(
          key:       const ValueKey('manual'),
          connected: connected && _activeMode == CarMode.manual,
          onCommand: _onCommand,
        );
      case CarMode.autonomous:
        return AutonomousCard(
          key:    const ValueKey('auto'),
          active: connected && _activeMode == CarMode.autonomous,
        );
      case CarMode.autoParking:
        return ParkingCard(
          key:       _parkingKey,
          connected: connected,
          bt:        _bt,
        );
    }
  }
}

class _TopBar extends StatelessWidget {
  final bool connected;
  final bool connecting;
  final String deviceName;
  final VoidCallback onBtTap;

  const _TopBar({
    required this.connected, required this.connecting,
    required this.deviceName, required this.onBtTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: AppTheme.bgCard,
        border: Border(bottom: BorderSide(color: AppTheme.borderColor, width: 0.5)),
      ),
      child: Row(children: [
        const Icon(Icons.smart_toy_outlined, color: AppTheme.blueLight, size: 18),
        const SizedBox(width: 8),
        const Text('RoboCar 01',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary, letterSpacing: 0.5)),
        const Spacer(),
        GestureDetector(
          onTap: onBtTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: connected ? AppTheme.greenBg
                  : connecting ? AppTheme.bgBlueDark : AppTheme.redBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: connected ? AppTheme.greenBorder
                    : connecting ? AppTheme.blueDark : AppTheme.redBorder,
                width: 0.5,
              ),
            ),
            child: Row(children: [
              Container(
                width: 6, height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: connected ? AppTheme.green
                      : connecting ? AppTheme.blueLight : AppTheme.red,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                connecting ? 'Connecting...'
                    : connected
                        ? deviceName.isNotEmpty ? deviceName : 'Connected'
                        : 'Disconnected',
                style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w500,
                    color: connected ? AppTheme.green
                        : connecting ? AppTheme.blueLight : AppTheme.red),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}
