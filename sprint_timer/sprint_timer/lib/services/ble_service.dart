import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/ble_packet.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONFIGURE THESE UUIDs to match your timing chip firmware
// ─────────────────────────────────────────────────────────────────────────────
const String kTimingServiceUuid    = '12345678-1234-5678-1234-56789abcdef0';
const String kTimingCharUuid       = '12345678-1234-5678-1234-56789abcdef1';
const String kDeviceNamePrefix     = 'SprintTimer'; // your chip advertises this name
// ─────────────────────────────────────────────────────────────────────────────

enum BleConnectionState { disconnected, scanning, connecting, connected, error }

class BleService extends ChangeNotifier {
  BleConnectionState _connectionState = BleConnectionState.disconnected;
  BluetoothDevice? _connectedDevice;
  StreamSubscription? _scanSub;
  StreamSubscription? _packetSub;
  StreamSubscription? _connectionSub;
  bool _isMockMode = false;
  Timer? _mockTimer;

  final List<ScanResult> _scanResults = [];
  final _packetController = StreamController<BlePacket>.broadcast();

  // ─── Getters ───────────────────────────────────────────────────────────────

  BleConnectionState get connectionState => _connectionState;
  BluetoothDevice? get connectedDevice => _connectedDevice;
  List<ScanResult> get scanResults => List.unmodifiable(_scanResults);
  Stream<BlePacket> get packetStream => _packetController.stream;
  bool get isConnected => _connectionState == BleConnectionState.connected;
  bool get isScanning => _connectionState == BleConnectionState.scanning;
  bool get isMockMode => _isMockMode;
  String get deviceName => _connectedDevice?.platformName ?? (_isMockMode ? 'SIMULATOR' : 'None');

  // ─── Scanning ──────────────────────────────────────────────────────────────

  Future<void> startScan() async {
    _scanResults.clear();
    _connectionState = BleConnectionState.scanning;
    notifyListeners();

    try {
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 15),
        withServices: [], // Can filter by service UUID here
      );

      _scanSub = FlutterBluePlus.scanResults.listen((results) {
        _scanResults.clear();
        // Filter for devices matching our name prefix
        _scanResults.addAll(
          results.where((r) =>
            r.device.platformName.contains(kDeviceNamePrefix) ||
            r.advertisementData.serviceUuids.any(
              (uuid) => uuid.toString().toLowerCase().contains('abcdef0')
            )
          ),
        );
        notifyListeners();
      });

      // When scan completes
      FlutterBluePlus.isScanning.listen((scanning) {
        if (!scanning && _connectionState == BleConnectionState.scanning) {
          _connectionState = BleConnectionState.disconnected;
          notifyListeners();
        }
      });
    } catch (e) {
      _connectionState = BleConnectionState.error;
      notifyListeners();
      debugPrint('BLE scan error: $e');
    }
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
    _scanSub?.cancel();
    _connectionState = BleConnectionState.disconnected;
    notifyListeners();
  }

  // ─── Connection ────────────────────────────────────────────────────────────

  Future<void> connectToDevice(BluetoothDevice device) async {
    _connectionState = BleConnectionState.connecting;
    notifyListeners();

    try {
      await device.connect(autoConnect: false, timeout: const Duration(seconds: 10));
      _connectedDevice = device;
      _connectionState = BleConnectionState.connected;
      notifyListeners();

      // Monitor connection state
      _connectionSub = device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _connectionState = BleConnectionState.disconnected;
          _connectedDevice = null;
          _packetSub?.cancel();
          notifyListeners();
        }
      });

      await _subscribeToCharacteristic(device);
    } catch (e) {
      _connectionState = BleConnectionState.error;
      notifyListeners();
      debugPrint('BLE connect error: $e');
    }
  }

  Future<void> _subscribeToCharacteristic(BluetoothDevice device) async {
    try {
      final services = await device.discoverServices();
      for (final service in services) {
        if (service.uuid.toString().toLowerCase().contains('abcdef0')) {
          for (final char in service.characteristics) {
            if (char.uuid.toString().toLowerCase().contains('abcdef1')) {
              await char.setNotifyValue(true);
              _packetSub = char.onValueReceived.listen((bytes) {
                final packet = BlePacket.parse(bytes);
                debugPrint('Received packet: $packet');
                _packetController.add(packet);
              });
              debugPrint('Subscribed to timing characteristic');
              return;
            }
          }
        }
      }
      debugPrint('Warning: Timing characteristic not found');
    } catch (e) {
      debugPrint('Characteristic subscribe error: $e');
    }
  }

  Future<void> disconnect() async {
    _mockTimer?.cancel();
    _packetSub?.cancel();
    _connectionSub?.cancel();
    await _connectedDevice?.disconnect();
    _connectedDevice = null;
    _isMockMode = false;
    _connectionState = BleConnectionState.disconnected;
    notifyListeners();
  }

  // ─── Simulator Mode ────────────────────────────────────────────────────────
  // Use this to test the app without real hardware

  void enableSimulator() {
    _isMockMode = true;
    _connectionState = BleConnectionState.connected;
    notifyListeners();
    debugPrint('Simulator mode enabled');
  }

  void disableSimulator() {
    _mockTimer?.cancel();
    _isMockMode = false;
    _connectionState = BleConnectionState.disconnected;
    notifyListeners();
  }

  /// Simulate a single timing event (for testing)
  void simulateFinishEvent({int lane = 1, int? timestampMs}) {
    if (!_isMockMode) return;
    final ts = timestampMs ?? (8000 + Random().nextInt(4000)); // 8.000 - 12.000 seconds
    final packet = BlePacket.parse(BlePacket.buildTestPacket(
      eventTypeByte: 0x03,
      lane: lane,
      timestampMs: ts,
    ));
    _packetController.add(packet);
  }

  void simulateStartEvent({int lane = 1}) {
    if (!_isMockMode) return;
    final packet = BlePacket.parse(BlePacket.buildTestPacket(
      eventTypeByte: 0x01,
      lane: lane,
      timestampMs: 0,
    ));
    _packetController.add(packet);
  }

  @override
  void dispose() {
    _mockTimer?.cancel();
    _scanSub?.cancel();
    _packetSub?.cancel();
    _connectionSub?.cancel();
    _packetController.close();
    super.dispose();
  }
}
