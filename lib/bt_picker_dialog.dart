import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'app_theme.dart';
import 'bluetooth_service.dart';

class BtPickerDialog extends StatefulWidget {
  final BluetoothService bt;
  const BtPickerDialog({super.key, required this.bt});

  @override
  State<BtPickerDialog> createState() => _BtPickerDialogState();
}

class _BtPickerDialogState extends State<BtPickerDialog> {
  List<BluetoothDevice> _devices = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scan();
  }

  Future<void> _scan() async {
    setState(() { _loading = true; _error = null; });
    try {
      final devices = await widget.bt.scanDevices();
      setState(() { _devices = devices; _loading = false; });
    } catch (e) {
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.bgCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.bluetooth, color: AppTheme.blueLight, size: 20),
              const SizedBox(width: 8),
              const Text('Paired Devices', style: TextStyle(
                color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
              const Spacer(),
              if (!_loading) IconButton(
                onPressed: _scan,
                icon: const Icon(Icons.refresh, color: AppTheme.textMuted, size: 18),
                padding: EdgeInsets.zero, constraints: const BoxConstraints(),
              ),
            ]),
            const SizedBox(height: 14),
            if (_loading)
              const Center(child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: CircularProgressIndicator(color: AppTheme.blue, strokeWidth: 2),
              ))
            else if (_error != null)
              Text('Error: $_error',
                style: const TextStyle(color: AppTheme.red, fontSize: 12))
            else if (_devices.isEmpty)
              const Text('No paired devices found.\nPair HC-05 in Android settings first.',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 12))
            else
              ..._devices.map((d) => _DeviceTile(
                device: d,
                onTap: () { Navigator.pop(context, d); },
              )),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeviceTile extends StatelessWidget {
  final BluetoothDevice device;
  final VoidCallback onTap;
  const _DeviceTile({required this.device, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.bgDeep,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.borderColor, width: 0.5),
        ),
        child: Row(children: [
          const Icon(Icons.bluetooth, color: AppTheme.blueLight, size: 16),
          const SizedBox(width: 10),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(device.name ?? 'Unknown',
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13,
                    fontWeight: FontWeight.w500)),
              Text(device.address,
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
            ],
          )),
          const Icon(Icons.arrow_forward_ios, color: AppTheme.textDim, size: 12),
        ]),
      ),
    );
  }
}
