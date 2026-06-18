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

  // SAFR framing constants
  static const _safrSof = 0xA5;
  static const _safrMinFrame = 42;  // AAD(21) + NONCE(4) + 1 payload + TAG(16)
  static const _safrMaxFrame = 256; // firmware buffer ceiling

  StreamSubscription<UsbEvent>? _usbEventSub;
  StreamSubscription<Uint8List?>? _inputSub;
  UsbPort? _port;
  String? _connectedDeviceId;
  final _byteBuffer = <int>[];
  final _dataController = StreamController<Uint8List>.broadcast();

  String? get connectedDeviceId => _connectedDeviceId;

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
      _connectedDeviceId = '${device.vid}:${device.pid}';
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
          _byteBuffer.addAll(data);
          _drainFrames();
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

  // Scans _byteBuffer for complete SAFR frames and emits each one.
  // Frame boundary: SOF(0xA5) at offset 0, total length at bytes [2..3].
  void _drainFrames() {
    while (true) {
      // 1. Find next SOF byte.
      final sofIdx = _byteBuffer.indexOf(_safrSof);
      if (sofIdx < 0) {
        _byteBuffer.clear();
        return;
      }
      if (sofIdx > 0) {
        debugPrint('[Serial] Discarding $sofIdx garbage bytes before SOF');
        _byteBuffer.removeRange(0, sofIdx);
      }

      // 2. Need at least 4 bytes to read the LEN field.
      if (_byteBuffer.length < 4) return;

      // 3. Parse total frame length from header bytes [2..3] (big-endian).
      final frameLen = (_byteBuffer[2] << 8) | _byteBuffer[3];
      if (frameLen < _safrMinFrame || frameLen > _safrMaxFrame) {
        // Invalid length — this SOF byte was garbage; skip and retry.
        debugPrint('[Serial] Invalid SAFR frame length $frameLen, skipping SOF');
        _byteBuffer.removeAt(0);
        continue;
      }

      // 4. Wait until the full frame has arrived.
      if (_byteBuffer.length < frameLen) return;

      // 5. Extract and emit the complete frame.
      final frame = Uint8List.fromList(_byteBuffer.sublist(0, frameLen));
      _byteBuffer.removeRange(0, frameLen);
      if (!_dataController.isClosed) {
        debugPrint('[Serial] RX SAFR frame: $frameLen bytes');
        _dataController.add(frame);
      }
    }
  }

  void _onDisconnected() {
    _inputSub?.cancel();
    _inputSub = null;
    try { _port?.close(); } catch (_) {}
    _port = null;
    _connectedDeviceId = null;
    _byteBuffer.clear();
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
