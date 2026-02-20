import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/math_logic.dart';

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
  List<double> _rawHistory = []; // For charting
  double _stressLevel = 0.0;
  String _anxietyStatus = "CALM";

  // Stream Subscription
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

  // Permissions
  Future<bool> checkPermissions() async {
    // Android 12+
    if (await Permission.bluetoothScan.request().isDenied) return false;
    if (await Permission.bluetoothConnect.request().isDenied) return false;
    // Location (Often needed for older scanning)
    if (await Permission.location.request().isDenied) return false;
    
    return true;
  }

  // Scanning
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

  // Connection
  Future<void> connect(BluetoothDevice device) async {
    _isScanning = false;
    FlutterBluePlus.stopScan(); // Ensure scan is stopped

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
    _rawHistory.clear();
    notifyListeners();
  }

  // Service Discovery & Data Parsing
  Future<void> _discoverServices(BluetoothDevice device) async {
    List<BluetoothService> services = await device.discoverServices();
    for (var service in services) {
      if (service.uuid.toString().toUpperCase().contains(serviceUUID)) {
        for (var characteristic in service.characteristics) {
          if (characteristic.uuid.toString().toUpperCase().contains(charUUID)) {
            await characteristic.setNotifyValue(true);
            _dataSubscription = characteristic.lastValueStream.listen((value) {
              _parseData(value);
            });
            // Also listen to onValueReceived if needed, but lastValueStream is usually sufficient with setNotifyValue
          }
        }
      }
    }
  }

  void _parseData(List<int> data) {
    if (data.isEmpty) return;
    
    // Expecting UTF-8 string: "BPM:85,RAW:3150"
    String receivedString = utf8.decode(data);
    
    // Simple parsing logic
    // You might need a more robust parser depending on real data cleanliness
    try {
      List<String> parts = receivedString.split(',');
      for (String part in parts) {
        if (part.startsWith("BPM:")) {
          _bpm = int.tryParse(part.split(':')[1]) ?? _bpm;
        } else if (part.startsWith("RAW:")) {
          _rawSensorValue = int.tryParse(part.split(':')[1]) ?? _rawSensorValue;
          _updateRawHistory(_rawSensorValue.toDouble());
        }
      }

      // Calculate Vitals
      _stressLevel = MathLogic.calculateStress(_bpm);
      _anxietyStatus = MathLogic.determineAnxiety(_stressLevel);

      notifyListeners();
    } catch (e) {
      debugPrint("Parse Error: $e");
    }
  }

  void _updateRawHistory(double value) {
    _rawHistory.add(value);
    if (_rawHistory.length > 100) { // Keep last 100 points for chart
      _rawHistory.removeAt(0);
    }
  }
}
