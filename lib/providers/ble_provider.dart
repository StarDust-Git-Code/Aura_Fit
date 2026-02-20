import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/math_logic.dart';
import '../services/notification_service.dart';

class BleProvider with ChangeNotifier {
  // UUIDs
  final String serviceUUID = "180D";
  final String charUUID = "2A37";
  final String deviceNameFilter = "Aura_Fit_BLE";

  // State
  bool _isScanning = false;
  bool _isConnected = false;
  BluetoothDevice? _connectedDevice;

  // Vitals
  int _bpm = 0;
  int _rawSensorValue = 0;
  List<double> _rawHistory = [];
  double _stressLevel = 0.0;
  String _anxietyStatus = "CALM";
  String _recommendation = "";

  // Emergency alert debouncing
  DateTime? _lastNotificationTime;
  static const Duration _notifCooldown = Duration(minutes: 2);

  // Stream Subscriptions
  StreamSubscription<List<int>>? _dataSubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionStateSubscription;

  // Getters
  bool get isScanning => _isScanning;
  bool get isConnected => _isConnected;
  BluetoothDevice? get connectedDevice => _connectedDevice;
  int get bpm => _bpm;
  double get stressLevel => _stressLevel;
  String get anxietyStatus => _anxietyStatus;
  List<double> get rawHistory => _rawHistory;
  String get recommendation => _recommendation;

  // ─── Permissions ───────────────────────────────────────────────────────────
  Future<bool> checkPermissions() async {
    if (await Permission.bluetoothScan.request().isDenied) return false;
    if (await Permission.bluetoothConnect.request().isDenied) return false;
    if (await Permission.location.request().isDenied) return false;
    // Notification permission (Android 13+)
    await Permission.notification.request();
    return true;
  }

  // ─── Scanning ──────────────────────────────────────────────────────────────
  Future<void> startScan() async {
    if (!await checkPermissions()) return;

    _isScanning = true;
    notifyListeners();

    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
      FlutterBluePlus.isScanning.listen((scanning) {
        _isScanning = scanning;
        notifyListeners();
      });
    } catch (e) {
      debugPrint("Scan Error: $e");
      _isScanning = false;
      notifyListeners();
    }
  }

  void stopScan() {
    FlutterBluePlus.stopScan();
    _isScanning = false;
    notifyListeners();
  }

  Stream<List<ScanResult>> get scanResults => FlutterBluePlus.scanResults;

  // ─── Connection ────────────────────────────────────────────────────────────
  Future<void> connect(BluetoothDevice device) async {
    _isScanning = false;
    FlutterBluePlus.stopScan();

    try {
      await device.connect();
      _connectedDevice = device;
      _isConnected = true;
      notifyListeners();

      _connectionStateSubscription = device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          disconnect();
        }
      });

      await _discoverServices(device);
    } catch (e) {
      debugPrint("Connection Error: $e");
      disconnect();
    }
  }

  void disconnect() {
    _connectedDevice?.disconnect();
    _dataSubscription?.cancel();
    _connectionStateSubscription?.cancel();
    _isConnected = false;
    _connectedDevice = null;
    _bpm = 0;
    _stressLevel = 0.0;
    _anxietyStatus = "CALM";
    _recommendation = "";
    _rawHistory.clear();
    notifyListeners();
  }

  // ─── Service Discovery ─────────────────────────────────────────────────────
  Future<void> _discoverServices(BluetoothDevice device) async {
    List<BluetoothService> services = await device.discoverServices();
    for (var service in services) {
      if (service.uuid.toString().toUpperCase().contains(serviceUUID)) {
        for (var characteristic in service.characteristics) {
          if (characteristic.uuid.toString().toUpperCase().contains(charUUID)) {
            await characteristic.setNotifyValue(true);
            _dataSubscription = characteristic.lastValueStream.listen(_parseData);
          }
        }
      }
    }
  }

  // ─── Data Parsing ──────────────────────────────────────────────────────────
  void _parseData(List<int> data) {
    if (data.isEmpty) return;

    try {
      final String received = utf8.decode(data);
      final List<String> parts = received.split(',');

      for (String part in parts) {
        if (part.startsWith("BPM:")) {
          _bpm = int.tryParse(part.split(':')[1]) ?? _bpm;
        } else if (part.startsWith("RAW:")) {
          _rawSensorValue = int.tryParse(part.split(':')[1]) ?? _rawSensorValue;
          _rawHistory.add(_rawSensorValue.toDouble());
          if (_rawHistory.length > 100) _rawHistory.removeAt(0);
        }
      }

      // Compute vitals
      _stressLevel = MathLogic.calculateStress(_bpm);
      _anxietyStatus = MathLogic.determineAnxiety(_stressLevel);
      _recommendation = MathLogic.getRecommendation(_anxietyStatus, _bpm);

      // Trigger emergency notification if needed
      _maybeNotify();

      notifyListeners();
    } catch (e) {
      debugPrint("Parse Error: $e");
    }
  }

  // ─── Emergency Notifications ───────────────────────────────────────────────
  void _maybeNotify() {
    final bool isEmergency = _anxietyStatus == "HIGH" || _bpm > 130;
    if (!isEmergency) return;

    final now = DateTime.now();
    if (_lastNotificationTime != null &&
        now.difference(_lastNotificationTime!) < _notifCooldown) {
      return; // Debounce: don't spam
    }

    _lastNotificationTime = now;

    String title;
    String body;

    if (_bpm > 130) {
      title = "⚠️ High Heart Rate Alert!";
      body = "Your BPM is dangerously high ($_bpm). $_recommendation";
    } else {
      title = "🚨 High Anxiety Detected!";
      body = "Stress level is ${_stressLevel.toInt()}%. $_recommendation";
    }

    NotificationService.showEmergencyNotification(title: title, body: body);
  }
}
