import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:usb_serial/usb_serial.dart';

enum SerialStatus { disconnected, connecting, connected, error }

class SerialNotifier extends StateNotifier<SerialStatus> {
  SerialNotifier() : super(SerialStatus.disconnected) {
    _init();
  }

  static const _baudRate = 115200;

  StreamSubscription<UsbEvent>? _usbEventSub;
  StreamSubscription<Uint8List?>? _inputSub;
  UsbPort? _port;
  final _lineBuffer = StringBuffer();
  final _dataController = StreamController<Uint8List>.broadcast();

  Stream<Uint8List> get dataStream => _dataController.stream;

  Future<void> _init() async {
    if (kIsWeb) return;

    try {
      _usbEventSub = UsbSerial.usbEventStream?.listen((UsbEvent event) {
        if (event.event == UsbEvent.ACTION_USB_ATTACHED) {
          debugPrint('[Serial] USB device attached');
          _connect();
        } else if (event.event == UsbEvent.ACTION_USB_DETACHED) {
          debugPrint('[Serial] USB device detached');
          _onDisconnected();
        }
      });
    } catch (e) {
      debugPrint('[Serial] Failed to listen to USB events: $e');
    }

    await _connect();
  }

  Future<void> _connect() async {
    if (kIsWeb || state == SerialStatus.connecting) return;

    state = SerialStatus.connecting;

    await _inputSub?.cancel();
    _inputSub = null;
    try { await _port?.close(); } catch (_) {}
    _port = null;

    try {
      final devices = await UsbSerial.listDevices();

      if (devices.isEmpty) {
        debugPrint('[Serial] No USB devices found');
        if (mounted) state = SerialStatus.disconnected;
        return;
      }

      final device = devices.first;
      debugPrint(
        '[Serial] Found: ${device.productName} '
        '[VID:${device.vid} PID:${device.pid}]',
      );

      final port = await device.create();
      if (port == null) {
        debugPrint('[Serial] Failed to create port');
        if (mounted) state = SerialStatus.error;
        return;
      }

      if (!await port.open()) {
        debugPrint('[Serial] Failed to open port');
        await port.close();
        if (mounted) state = SerialStatus.error;
        return;
      }

      await port.setPortParameters(
        _baudRate,
        UsbPort.DATABITS_8,
        UsbPort.STOPBITS_1,
        UsbPort.PARITY_NONE,
      );

      _port = port;

      _inputSub = port.inputStream?.listen(
        (Uint8List? data) {
          if (data == null || data.isEmpty) return;
          _lineBuffer.write(String.fromCharCodes(data));
          final buffered = _lineBuffer.toString();
          final parts = buffered.split('\n');
          // Keep the last (possibly incomplete) fragment for the next chunk
          _lineBuffer
            ..clear()
            ..write(parts.last);
          for (var i = 0; i < parts.length - 1; i++) {
            final line = parts[i].trimRight();
            if (line.isEmpty) continue;
            debugPrint('[Serial] RX: $line');
            if (!_dataController.isClosed) {
              _dataController.add(Uint8List.fromList(line.codeUnits));
            }
          }
        },
        onError: (Object err) {
          debugPrint('[Serial] Stream error: $err');
          _onDisconnected();
        },
        onDone: () {
          debugPrint('[Serial] Stream closed by device');
          _onDisconnected();
        },
        cancelOnError: false,
      );

      if (mounted) state = SerialStatus.connected;
      debugPrint('[Serial] Connected at $_baudRate baud');
    } catch (e, st) {
      debugPrint('[Serial] Connection error: $e\n$st');
      if (mounted) state = SerialStatus.error;
    }
  }

  void _onDisconnected() {
    _inputSub?.cancel();
    _inputSub = null;
    try { _port?.close(); } catch (_) {}
    _port = null;
    _lineBuffer.clear();
    if (mounted) state = SerialStatus.disconnected;
  }

  @override
  void dispose() {
    _usbEventSub?.cancel();
    _inputSub?.cancel();
    try { _port?.close(); } catch (_) {}
    _dataController.close();
    super.dispose();
  }
}

final serialProvider =
    StateNotifierProvider<SerialNotifier, SerialStatus>((ref) {
  return SerialNotifier();
});

/// Raw bytes stream from the serial port — only emits when connected.
final serialDataProvider = StreamProvider<Uint8List>((ref) {
  return ref.watch(serialProvider.notifier).dataStream;
});
