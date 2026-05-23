import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';

enum BtState { disconnected, scanning, connecting, connected }

class BluetoothService extends ChangeNotifier {
  BtState state       = BtState.disconnected;
  String  deviceName  = '';
  int     batteryPct  = 0;
  double  batteryVolts = 0.0;
  int     sensorLeft  = 0;
  int     sensorFront = 0;
  int     sensorRight = 0;
  int     parkingPhase  = 0;
  bool    lowBattAlert  = false;

  final List<String> logs = [];

  BluetoothConnection? _conn;
  String _buffer = '';

  Future<List<BluetoothDevice>> scanDevices() async {
    await _requestPermissions();
    return await FlutterBluetoothSerial.instance.getBondedDevices();
  }

  Future<void> connect(BluetoothDevice device) async {
    if (state == BtState.connected) await disconnect();
    state = BtState.connecting;
    notifyListeners();
    try {
      _conn = await BluetoothConnection.toAddress(device.address)
          .timeout(const Duration(seconds: 10));
      deviceName = device.name ?? device.address;
      state = BtState.connected;
      _addLog('ok', 'Connected — ${device.name}');
      _addLog('info', 'Waiting for data...');
      _conn!.input!.listen(_onData, onDone: () {
        _addLog('warn', 'Connection closed');
        _handleDisconnect();
      }, onError: (_) {
        _addLog('warn', 'Connection error');
        _handleDisconnect();
      });
      notifyListeners();
    } catch (e) {
      state = BtState.disconnected;
      _addLog('warn', 'Failed to connect: $e');
      notifyListeners();
    }
  }

  Future<void> disconnect() async {
    await _conn?.close();
    _conn = null;
    _handleDisconnect();
  }

  void _handleDisconnect() {
    state        = BtState.disconnected;
    deviceName   = '';
    parkingPhase = 0;
    batteryPct   = 0;
    batteryVolts = 0.0;
    lowBattAlert = false;
    sensorLeft   = 0;
    sensorFront  = 0;
    sensorRight  = 0;
    notifyListeners();
  }

  void send(String cmd) {
    if (state != BtState.connected || _conn == null) {
      _addLog('warn', 'Not connected');
      return;
    }
    try {
      _conn!.output.add(Uint8List.fromList(cmd.codeUnits));
      _addLog('info', 'TX → $cmd');
    } catch (_) {
      _addLog('warn', 'Send failed');
    }
  }

  void _onData(Uint8List data) {
    _buffer += String.fromCharCodes(data);
    while (_buffer.contains('\n')) {
      final idx  = _buffer.indexOf('\n');
      final line = _buffer.substring(0, idx).trim();
      _buffer    = _buffer.substring(idx + 1);
      if (line.isNotEmpty) _parseLine(line);
    }
  }

  void _parseLine(String line) {
    // ── Battery: "B:42.5%" — matches exactly what battery1.cpp sends ──────────
    if (line.startsWith('B:') && line.endsWith('%')) {
      final val = double.tryParse(line.substring(2, line.length - 1).trim());
      if (val != null) {
        batteryPct   = val.clamp(0, 100).toInt();
        batteryVolts = (val / 100.0) * 11.0;
        _addLog('ok', 'Battery: $batteryPct% ${batteryVolts.toStringAsFixed(1)}V');
        notifyListeners();
      }

    // ── Sensors: "SNS:left,front,right" ────────────────────────────────────
    } else if (line.startsWith('SNS:')) {
      final parts = line.substring(4).split(',');
      if (parts.length >= 3) {
        sensorLeft  = int.tryParse(parts[0].trim()) ?? sensorLeft;
        sensorFront = int.tryParse(parts[1].trim()) ?? sensorFront;
        sensorRight = int.tryParse(parts[2].trim()) ?? sensorRight;
        notifyListeners();
      }

    // ── Auto-park phase ─────────────────────────────────────────────────────
    } else if (line.startsWith('PARK:')) {
      parkingPhase = int.tryParse(line.substring(5)) ?? 0;
      _addLog('ok', 'RX ← $line');
      notifyListeners();

    // ── Low battery alert ───────────────────────────────────────────────────
    } else if (line == 'ALERT:LOW_BATT') {
      lowBattAlert = true;
      _addLog('warn', '⚠ LOW BATTERY');
      notifyListeners();

    } else {
      _addLog('info', 'RX ← $line');
    }
  }

  void _addLog(String type, String msg) {
    final prefix = type == 'ok' ? '✓' : type == 'warn' ? '⚠' : '›';
    logs.add('$prefix $msg');
    if (logs.length > 20) logs.removeAt(0);
    notifyListeners();
  }

  void addExternalLog(String type, String msg) => _addLog(type, msg);

  Future<void> _requestPermissions() async {
    await [
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.location,
    ].request();
  }
}
